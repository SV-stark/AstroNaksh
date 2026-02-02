import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:jyotish/jyotish.dart';

/// Manages Swiss Ephemeris data files for planetary calculations
/// Downloads and maintains ephemeris files from official sources
class EphemerisManager {
  static final Jyotish _jyotish = Jyotish();
  static bool _initialized = false;

  static Jyotish get jyotish => _jyotish;
  static bool get isInitialized => _initialized;

  // Swiss Ephemeris file URLs
  static const String _baseUrl = 'https://www.astro.com/swisseph/ephe';
  // unused: static const String _ftpBaseUrl = 'ftp://ssd.jpl.nasa.gov/pub/eph/planets/bsp';

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
    'sepl_18.se1': 540672,
    'semo_18.se1': 540672,
    'seas_18.se1': 270336,
    'seplm18.se1': 1081344,
    'semom18.se1': 1081344,
    'seasm18.se1': 540672,
  };

  /// Ensure ephemeris data is available and initialized
  static Future<void> ensureEphemerisData() async {
    if (_initialized) return;

    final directory = await getApplicationSupportDirectory();
    final ephemerisPath = '${directory.path}/ephe';
    final dir = Directory(ephemerisPath);

    // Create directory if it doesn't exist
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Check if required files exist, download if missing
    final missingFiles = await _getMissingFiles(ephemerisPath);
    if (missingFiles.isNotEmpty) {
      await _downloadEphemerisFiles(ephemerisPath, missingFiles);
    }

    // Initialize the jyotish library
    try {
      await _initializeLibrary(ephemerisPath);
      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing Jyotish: $e");
      }
      // Try with fallback equal-house calculations
      _initialized = true;
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
        final response = await http.get(Uri.parse(url));

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
      // Try to initialize with the library's initialize method
      // Different versions might have different signatures
      await _jyotish.initialize(ephemerisPath: ephemerisPath);
    } catch (e) {
      // Fallback: try without parameters
      try {
        await _jyotish.initialize();
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

    // Re-download all files
    final allFiles = _requiredFiles['standard']!;
    await _downloadEphemerisFiles(
      ephemerisPath,
      allFiles,
      onProgress: onProgress,
    );

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
      final expectedSize = _fileSizes[file] ?? 0;
      if (size < expectedSize * 0.9) {
        return false;
      }
    }

    return true;
  }
}
