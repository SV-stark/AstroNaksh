import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Manages application environment, paths, and global flags.
/// Handles portable mode detection and verbose logging.
class AppEnvironment {
  static bool _isInitialized = false;
  static bool _isPortable = false;
  static bool _isVerbose = false;
  static String? _executableDir;

  static bool get isPortable => _isPortable;
  static bool get isVerbose => _isVerbose;

  /// Initialize the environment.
  /// Checks for portable mode marker and parses arguments.
  static Future<void> initialize(List<String> args) async {
    if (_isInitialized) return;

    // 1. Check for Verbose Flag
    if (args.contains('--verbose') || args.contains('-v')) {
      _isVerbose = true;
      debugPrint('Core: Verbose mode enabled via CLI arguments');
    }

    // 2. Determine Executable Directory
    try {
      _executableDir = p.dirname(Platform.resolvedExecutable);
      if (_isVerbose) {
        debugPrint('Core: Executable directory resolved to: $_executableDir');
      }
    } catch (e) {
      debugPrint('Core: Failed to resolve executable directory: $e');
      // Fallback if needed, though Platform.resolvedExecutable should be reliable on desktop
    }

    // 3. Check for Portable Marker
    // Look for a .portable file in the same directory as the executable
    if (_executableDir != null) {
      final portableFile = File(p.join(_executableDir!, '.portable'));
      if (await portableFile.exists()) {
        _isPortable = true;
        if (_isVerbose) {
          debugPrint('Core: Portable mode detected (.portable file found)');
        }
      } else {
        if (_isVerbose) {
          debugPrint('Core: Standard installation mode (no .portable marker)');
        }
      }
    }

    _isInitialized = true;
  }

  /// Get the directory for storing user data (db, settings, etc.)
  static Future<Directory> getUserDataDirectory() async {
    if (_isPortable && _executableDir != null) {
      final dir = Directory(p.join(_executableDir!, 'user_data'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } else {
      // Standard: %USERPROFILE%\Documents on Windows for easier access,
      // or standard ApplicationDocumentsDirectory
      return await getApplicationDocumentsDirectory();
    }
  }

  /// Get the directory for storing ephemeris files
  static Future<Directory> getEphemerisDirectory() async {
    if (_isPortable && _executableDir != null) {
      final dir = Directory(p.join(_executableDir!, 'user_data', 'ephe'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } else {
      // Standard: ApplicationSupportDirectory (e.g., AppData/Roaming/Company/App)
      final appSupport = await getApplicationSupportDirectory();
      final dir = Directory(p.join(appSupport.path, 'ephe'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
  }

  /// Get the path for the database file
  static Future<String> getDatabasePath() async {
    if (_isPortable && _executableDir != null) {
      final dir = await getUserDataDirectory();
      return p.join(dir.path, 'astronaksh.db');
    } else {
      // Use standard getDatabasesPath
      final dbPath = await getDatabasesPath();
      return p.join(dbPath, 'astronaksh.db');
    }
  }

  /// Helper for verbose logging
  static void log(String message) {
    if (_isVerbose) {
      // Print with a timestamp or tag
      debugPrint('[VERBOSE] $message');
    }
  }
}
