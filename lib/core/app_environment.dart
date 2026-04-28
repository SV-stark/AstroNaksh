// ignore_for_file: avoid_slow_async_io, unawaited_futures, deprecated_member_use, sort_constructors_first, implementation_imports
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

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

    // 2. Determine Executable Directory (Desktop Only)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        _executableDir = p.dirname(Platform.resolvedExecutable);
      } catch (e) {
        // Cannot log yet
      }

      // 3. Check for Portable Marker
      if (_executableDir != null) {
        final portableFile = File(p.join(_executableDir!, '.portable'));
        if (await portableFile.exists()) {
          _isPortable = true;
        }
      }
    }


    // 4. Setup Logging
    await _setupLogging();

    if (_isVerbose) {
      log('Core: Verbose mode enabled via CLI arguments');
      log('Core: Executable directory resolved to: $_executableDir');
      if (_isPortable) {
        log('Core: Portable mode detected (.portable file found)');
      }
    }

    _isInitialized = true;
  }

  static Future<Directory> _getAppSupportDir() async {
    if (Platform.isWindows && !_isPortable) {
      final roaming = Platform.environment['APPDATA'];
      if (roaming != null) {
        final dir = Directory(p.join(roaming, 'AstroNaksh'));
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        return dir;
      }
    }
    return getApplicationSupportDirectory();
  }

  static Future<void> _setupLogging() async {
    try {
      Directory logDir;
      if (_isPortable && _executableDir != null) {
        logDir = Directory(p.join(_executableDir!, 'user_data', 'logs'));
      } else {
        final appSupport = await _getAppSupportDir();
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
      }
    } catch (e) {
      // Cannot log
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
      return getApplicationDocumentsDirectory();
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
      final appSupport = await _getAppSupportDir();
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
      final dbPath = await getDatabasesPath();
      return p.join(dbPath, 'astronaksh.db');
    }
  }

  /// Formats a path for Swiss Ephemeris (ensures correct separators and absolute path)
  static String formatPathForSwissEph(String path) {
    // Ensure absolute path and resolve any .. or . segments
    final absolutePath = p.absolute(path);
    final canonicalPath = p.canonicalize(absolutePath);
    
    var formatted = canonicalPath;
    
    // On Windows, use native backslashes. 
    // While SE can handle forward slashes, some builds of swisseph.dll 
    // on Windows are more stable with native paths.
    if (Platform.isWindows) {
      formatted = formatted.replaceAll('/', '\\');
    } else {
      formatted = formatted.replaceAll('\\', '/');
    }
    
    // Ensure it ends with a separator as SE uses this as a directory prefix
    final separator = Platform.isWindows ? '\\' : '/';
    if (!formatted.endsWith(separator)) {
      formatted += separator;
    }
    
    return formatted;
  }

  /// Helper for verbose logging
  static void log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $message';

    // 1. Print to console (stdout) for CLI visibility
    if (_isVerbose) {
      stdout.writeln(logMessage);
    }

    // 2. Write to file
    if (_logFile != null) {
      try {
        _logFile!.writeAsStringSync('$logMessage\n', mode: FileMode.append);
      } catch (e) {
        // Fallback to stdout
        try {
          stdout.writeln(logMessage);
        } catch (e) {
          // Ignore
        }
      }
    }
  }
}
