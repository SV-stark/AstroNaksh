import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

/// Manages application environment, paths, and global flags.
/// Handles portable mode detection and verbose logging.
class AppEnvironment {
  static bool _isInitialized = false;
  static bool _isPortable = false;
  static bool _isVerbose = false;
  static String? _executableDir;

  static bool get isPortable => _isPortable;
  static bool get isVerbose => _isVerbose;

  static File? _logFile;

  /// Initialize the environment.
  /// Checks for portable mode marker and parses arguments.
  static Future<void> initialize(List<String> args) async {
    if (_isInitialized) return;

    // 1. Check for Verbose Flag
    if (args.contains('--verbose') || args.contains('-v')) {
      _isVerbose = true;
    }

    // 2. Determine Executable Directory
    try {
      _executableDir = p.dirname(Platform.resolvedExecutable);
    } catch (e) {
      // Fallback if needed
    }

    // 3. Check for Portable Marker
    if (_executableDir != null) {
      final portableFile = File(p.join(_executableDir!, '.portable'));
      if (await portableFile.exists()) {
        _isPortable = true;
      }
    }

    // 4. Setup Logging
    await _setupLogging();

    if (_isVerbose) {
      log('Core: Verbose mode enabled via CLI arguments');
      log('Core: Executable directory resolved to: $_executableDir');
      if (_isPortable) {
        log('Core: Portable mode detected (.portable file found)');
      } else {
        log('Core: Standard installation mode (no .portable marker)');
      }
    }

    _isInitialized = true;
  }

  static Future<void> _setupLogging() async {
    try {
      Directory logDir;
      if (_isPortable && _executableDir != null) {
        logDir = Directory(p.join(_executableDir!, 'user_data', 'logs'));
      } else {
        final appSupport = await getApplicationSupportDirectory();
        logDir = Directory(p.join(appSupport.path, 'logs'));
      }

      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      _logFile = File(p.join(logDir.path, 'startup.log'));

      // Clear old log on startup
      if (await _logFile!.exists()) {
        await _logFile!.writeAsString(
          '--- Log Started: ${DateTime.now()} ---\n',
        );
      } else {
        await _logFile!.writeAsString(
          '--- Log Started: ${DateTime.now()} ---\n',
        );
      }
    } catch (e) {
      // Cannot log if logging setup fails, just print to debug console
      if (_isVerbose) debugPrint('Failed to setup logging: $e');
    }
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
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $message';

    // 1. Print to console (stdout) for CLI visibility
    if (_isVerbose) {
      // Use stdout directly for CLI visibility in some contexts
      stdout.writeln(logMessage);
    }

    // 2. Write to file
    if (_logFile != null) {
      try {
        _logFile!.writeAsStringSync('$logMessage\n', mode: FileMode.append);
      } catch (e) {
        // Silently fail if file write fails to avoid crash loops
      }
    }
  }
}
