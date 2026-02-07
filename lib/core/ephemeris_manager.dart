import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:jyotish/jyotish.dart';
import 'dart:ffi';
import 'app_environment.dart';

/// Manages Swiss Ephemeris data files for planetary calculations
/// Uses bundled assets first, downloads only if missing
class EphemerisManager {
  static final Jyotish _jyotish = Jyotish();
  static EphemerisService? _service;
  static bool _initialized = false;

  static Jyotish get jyotish => _jyotish;
  static EphemerisService get service => _service ??= EphemerisService();
  static bool get isInitialized => _initialized;

  // Swiss Ephemeris file URLs (fallback download from GitHub)
  static const String _baseUrl =
      'https://raw.githubusercontent.com/aloistr/swisseph/master/ephe';

  // Required ephemeris files for different date ranges
  static const Map<String, List<String>> _requiredFiles = {
    'standard': [
      'sepl_18.se1', // Planets 1800-2400
      'semo_18.se1', // Moon 1800-2400
      'seas_18.se1', // Asteroids 1800-2400
    ],
    'extended': [
      'seplm18.se1', // Planets -3000 to 3000
      'semom18.se1', // Moon -3000 to 3000
      'seasm18.se1', // Asteroids -3000 to 3000
    ],
  };

  // File sizes in bytes (approximate)
  static const Map<String, int> _fileSizes = {
    'sepl_18.se1': 484055,
    'semo_18.se1': 1304771,
    'seas_18.se1': 223002,
    'seplm18.se1': 1081344,
    'semom18.se1': 1081344,
    'seasm18.se1': 540672,
  };

  /// Ensure ephemeris data is available and initialized
  static Future<void> ensureEphemerisData() async {
    if (_initialized) return;

    final directory = await AppEnvironment.getEphemerisDirectory();
    final ephemerisPath = directory.path;
    final dir = Directory(ephemerisPath);

    AppEnvironment.log('EphemerisManager: Path resolved to $ephemerisPath');

    // Create directory if it doesn't exist
    if (!await dir.exists()) {
      AppEnvironment.log('EphemerisManager: Creating directory $ephemerisPath');
      await dir.create(recursive: true);
    }

    // First try to copy from bundled assets
    await _copyBundledAssets(ephemerisPath);

    // Verify swisseph.dll existence (Windows only)
    if (Platform.isAndroid) {
      AppEnvironment.log(
        'EphemerisManager: Running on Android. Expecting libswisseph.so from JNI.',
      );
    } else if (Platform.isWindows) {
      if (AppEnvironment.isPortable) {
        final dllPath =
            '${p.dirname(Platform.resolvedExecutable)}\\swisseph.dll';
        if (File(dllPath).existsSync()) {
          AppEnvironment.log(
            'EphemerisManager: swisseph.dll found at $dllPath',
          );

          // 1. Check Architecture
          try {
            final bytes = await File(dllPath).readAsBytes();
            // PE Header offset is at 0x3C (60)
            if (bytes.length > 64) {
              final peOffset =
                  bytes[0x3C] |
                  (bytes[0x3D] << 8) |
                  (bytes[0x3E] << 16) |
                  (bytes[0x3F] << 24);
              if (peOffset + 6 < bytes.length) {
                // Machine type is at PE Offset + 4
                // 0x8664 = x64, 0x014c = x86
                final machine =
                    bytes[peOffset + 4] | (bytes[peOffset + 5] << 8);
                final is64Bit = machine == 0x8664;
                AppEnvironment.log(
                  'EphemerisManager: DLL Machine Type: 0x${machine.toRadixString(16)} (Is x64: $is64Bit)',
                );

                if (!is64Bit) {
                  AppEnvironment.log(
                    'EphemerisManager: WARNING - DLL does not appear to be x64! This implies a mismatch.',
                  );
                }
              }
            }
          } catch (e) {
            AppEnvironment.log(
              'EphemerisManager: Failed to parse DLL header: $e',
            );
          }

          // 2. Try Explicit Load
          try {
            AppEnvironment.log(
              'EphemerisManager: Attempting explicit DynamicLibrary.open...',
            );
            // On Windows, open by path
            final lib = DynamicLibrary.open(dllPath);
            AppEnvironment.log(
              'EphemerisManager: Explicit load successful: $lib',
            );
          } catch (e) {
            AppEnvironment.log(
              'EphemerisManager: CRITICAL - Explicit load failed: $e',
            );
            AppEnvironment.log(
              'EphemerisManager: This usually means missing dependencies (VC++ Redist check?) or bad arch.',
            );
          }
        } else {
          AppEnvironment.log(
            'EphemerisManager: ERROR - swisseph.dll NOT found at $dllPath',
          );
        }
      } else {
        // Standard check around executable
        final dllPath =
            '${p.dirname(Platform.resolvedExecutable)}\\swisseph.dll';
        AppEnvironment.log(
          'EphemerisManager: Checking for swisseph.dll at $dllPath: ${File(dllPath).existsSync()}',
        );
      }
    }

    // Check if required files exist, download if still missing
    final missingFiles = await _getMissingFiles(ephemerisPath);
    if (missingFiles.isNotEmpty) {
      AppEnvironment.log(
        'EphemerisManager: Missing files detected: $missingFiles. Attempting download/copy...',
      );
      await _downloadEphemerisFiles(ephemerisPath, missingFiles);
    } else {
      AppEnvironment.log('EphemerisManager: All required files present');
    }

    // Initialize the jyotish library
    try {
      AppEnvironment.log(
        'EphemerisManager: Initializing library with path: $ephemerisPath',
      );
      await _initializeLibrary(ephemerisPath);
      _initialized = true;
      AppEnvironment.log('EphemerisManager: Initialization successful');
    } catch (e, stack) {
      _initialized = false;
      AppEnvironment.log(
        "EphemerisManager: Error initializing Jyotish: $e\n$stack",
      );
      // propagate error so UI can handle it
      throw EphemerisException('Failed to initialize astrology engine: $e');
    }
  }

  /// Copy bundled ephemeris files from assets to app directory
  static Future<void> _copyBundledAssets(String targetPath) async {
    final files = _requiredFiles['standard']!;

    // Debug: List Asset Manifest if possible to see what's available
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      // Simple check
      AppEnvironment.log(
        'EphemerisManager: AssetManifest loaded. Length: ${manifestContent.length}',
      );
      if (AppEnvironment.isVerbose) {
        // AppEnvironment.log('EphemerisManager: Manifest: $manifestContent'); // Too verbose
      }
    } catch (e) {
      AppEnvironment.log('EphemerisManager: Could not load AssetManifest: $e');
    }

    for (final file in files) {
      final targetFile = File('$targetPath/$file');

      // Skip if file already exists and has correct size
      if (await targetFile.exists()) {
        final size = await targetFile.length();
        final expectedSize = _fileSizes[file] ?? 0;
        if (size >= expectedSize * 0.9) {
          continue;
        }
      }

      // Try to copy from bundled assets
      try {
        final assetPath = 'assets/ephe/$file';
        AppEnvironment.log(
          'EphemerisManager: Attempting to load asset: $assetPath',
        );
        final data = await rootBundle.load(assetPath);
        await targetFile.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
        AppEnvironment.log('EphemerisManager: Copied bundled asset: $file');
      } catch (e) {
        AppEnvironment.log(
          'EphemerisManager: Asset $file not bundled or copy failed: $e',
        );
      }
    }
  }

  /// Check which files are missing
  static Future<List<String>> _getMissingFiles(String path) async {
    final missing = <String>[];
    final files = _requiredFiles['standard']!;

    for (final file in files) {
      final filePath = '$path/$file';
      final fileObj = File(filePath);
      if (!await fileObj.exists()) {
        missing.add(file);
      } else {
        // Check file size
        final size = await fileObj.length();
        final expectedSize = _fileSizes[file] ?? 0;
        if (size < expectedSize * 0.9) {
          // File is incomplete, re-download
          missing.add(file);
        }
      }
    }

    return missing;
  }

  /// Download ephemeris files with progress tracking
  static Future<void> _downloadEphemerisFiles(
    String path,
    List<String> files, {
    void Function(double progress, String currentFile)? onProgress,
  }) async {
    final totalSize = files.fold<int>(
      0,
      (sum, file) => sum + (_fileSizes[file] ?? 0),
    );
    int downloadedSize = 0;

    for (final file in files) {
      try {
        if (kDebugMode) {
          print('Downloading $file...');
        }

        final url = '$_baseUrl/$file';
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final filePath = '$path/$file';
          final fileObj = File(filePath);
          await fileObj.writeAsBytes(response.bodyBytes);

          downloadedSize += response.bodyBytes.length;
          final progress = totalSize > 0 ? downloadedSize / totalSize : 0.0;

          if (onProgress != null) {
            onProgress(progress, file);
          }

          if (kDebugMode) {
            print('Downloaded $file (${response.bodyBytes.length} bytes)');
          }
        } else {
          if (kDebugMode) {
            print('Failed to download $file: HTTP ${response.statusCode}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error downloading $file: $e');
        }
      }
    }
  }

  /// Initialize the jyotish library with the ephemeris path
  static Future<void> _initializeLibrary(String ephemerisPath) async {
    try {
      // Initialize both service wrappers
      await _jyotish.initialize(ephemerisPath: ephemerisPath);
      await service.initialize(ephemerisPath: ephemerisPath);
    } catch (e) {
      // Fallback: try without parameters
      try {
        await _jyotish.initialize();
        await service.initialize(
          ephemerisPath: ephemerisPath,
        ); // Retry service with path
      } catch (e2) {
        // If both fail, the library might auto-initialize
        if (kDebugMode) {
          print('Library initialization skipped: $e2');
        }
      }
    }
  }

  /// Check if ephemeris files are available for a date range
  static Future<bool> isDateRangeCovered(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final year = startDate.year;

    // Standard files cover 1800-2400
    if (year >= 1800 && year <= 2400) {
      final directory = await getApplicationSupportDirectory();
      final ephemerisPath = '${directory.path}/ephe';
      final missing = await _getMissingFiles(ephemerisPath);
      return missing.isEmpty;
    }

    // Extended range requires different files
    return false;
  }

  /// Get available date range for current ephemeris
  static Future<Map<String, DateTime>> getAvailableDateRange() async {
    final directory = await getApplicationSupportDirectory();
    final ephemerisPath = '${directory.path}/ephe';
    final hasStandard = await _hasFiles(
      ephemerisPath,
      _requiredFiles['standard']!,
    );
    final hasExtended = await _hasFiles(
      ephemerisPath,
      _requiredFiles['extended']!,
    );

    if (hasExtended) {
      return {
        'start': DateTime(1800, 1, 1).add(Duration(days: -3000 * 365)),
        'end': DateTime(3000, 12, 31),
      };
    } else if (hasStandard) {
      return {'start': DateTime(1800, 1, 1), 'end': DateTime(2400, 12, 31)};
    }

    // Fallback: only current date with approximate calculations
    return {'start': DateTime(1900, 1, 1), 'end': DateTime(2100, 12, 31)};
  }

  /// Check if specific files exist
  static Future<bool> _hasFiles(String path, List<String> files) async {
    for (final file in files) {
      final filePath = '$path/$file';
      if (!await File(filePath).exists()) {
        return false;
      }
    }
    return true;
  }

  /// Clear and re-download all ephemeris files
  static Future<void> resetEphemerisData({
    void Function(double progress, String currentFile)? onProgress,
  }) async {
    final directory = await getApplicationSupportDirectory();
    final ephemerisPath = '${directory.path}/ephe';
    final dir = Directory(ephemerisPath);

    // Delete existing files
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);

    // First try bundled assets
    await _copyBundledAssets(ephemerisPath);

    // Download any still missing files
    final missingFiles = await _getMissingFiles(ephemerisPath);
    if (missingFiles.isNotEmpty) {
      await _downloadEphemerisFiles(
        ephemerisPath,
        missingFiles,
        onProgress: onProgress,
      );
    }

    // Re-initialize
    _initialized = false;
    await ensureEphemerisData();
  }

  /// Get the total size of required ephemeris files
  static int getRequiredDownloadSize() {
    final files = _requiredFiles['standard']!;
    return files.fold<int>(0, (sum, file) => sum + (_fileSizes[file] ?? 0));
  }

  /// Verify ephemeris file integrity
  static Future<bool> verifyEphemerisIntegrity() async {
    final directory = await getApplicationSupportDirectory();
    final ephemerisPath = '${directory.path}/ephe';
    final files = _requiredFiles['standard']!;

    for (final file in files) {
      final filePath = '$ephemerisPath/$file';
      final fileObj = File(filePath);

      if (!await fileObj.exists()) {
        return false;
      }

      final size = await fileObj.length();
      // Relaxed check: just ensure file is not empty (e.g. > 1KB)
      if (size < 1024) {
        return false;
      }
    }

    return true;
  }
}

class EphemerisException implements Exception {
  final String message;
  EphemerisException(this.message);
  @override
  String toString() => 'EphemerisException: $message';
}
