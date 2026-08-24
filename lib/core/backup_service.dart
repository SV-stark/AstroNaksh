import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'app_environment.dart';
import 'database.dart';
import 'settings_provider.dart';

class BackupService {
  BackupService(this.ref);
  final Ref ref;

  Future<File> getDatabaseFile() async {
    final path = await AppEnvironment.getDatabasePath();
    return File(path);
  }

  /// Backup database to a local file path
  Future<void> backupLocal(String targetPath) async {
    final dbFile = await getDatabaseFile();
    if (!dbFile.existsSync()) {
      throw Exception('Database file not found at ${dbFile.path}');
    }

    try {
      final db = ref.read(databaseProvider);
      await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
    } catch (_) {
      // If DB is closed or not WAL mode, ignore checkpoint error
    }

    // Copy file to target destination
    await dbFile.copy(targetPath);
  }

  /// Restore database from a local file path
  Future<void> restoreLocal(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) {
      throw Exception('Source backup file not found.');
    }

    final db = ref.read(databaseProvider);

    // 1. Attempt transactional ATTACH restore (leaves connection alive and active)
    var transactionalSuccess = false;
    try {
      final sanitizedPath = sourcePath.replaceAll("'", "''");
      await db.transaction(() async {
        await db.customStatement("ATTACH DATABASE '$sanitizedPath' AS backup_db;");
        try {
          await db.customStatement('DELETE FROM charts;');
          await db.customStatement(
            'INSERT INTO charts (id, name, dateTime, latitude, longitude, locationName, timezone) '
            'SELECT id, name, dateTime, latitude, longitude, locationName, timezone FROM backup_db.charts;',
          );
          await db.customStatement('DELETE FROM settings;');
          await db.customStatement(
            'INSERT INTO settings (key, value) SELECT key, value FROM backup_db.settings;',
          );
        } finally {
          await db.customStatement('DETACH DATABASE backup_db;');
        }
      });
      transactionalSuccess = true;
      ref.invalidate(settingsProvider);
    } catch (e) {
      AppEnvironment.log(
        'BackupService: Transactional restore unavailable, falling back to file overwrite: $e',
      );
    }

    // 2. Fallback to file replacement if transactional ATTACH was not possible
    if (!transactionalSuccess) {
      final dbFile = await getDatabaseFile();

      try {
        await db.close();
      } catch (_) {}

      final walFile = File('${dbFile.path}-wal');
      final shmFile = File('${dbFile.path}-shm');
      if (walFile.existsSync()) {
        try {
          walFile.deleteSync();
        } catch (_) {}
      }
      if (shmFile.existsSync()) {
        try {
          shmFile.deleteSync();
        } catch (_) {}
      }

      await sourceFile.copy(dbFile.path);

      ref.invalidate(databaseProvider);
      ref.invalidate(settingsProvider);
      ref.read(databaseProvider);
    }
  }

  /// Test connection to WebDAV server
  Future<bool> testWebDAV(String url, String username, String password) async {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) {
      throw Exception('WebDAV URL cannot be empty');
    }
    final uri = Uri.parse(trimmedUrl);
    if (!uri.hasScheme || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      throw Exception('Invalid URL scheme. Must start with http:// or https://');
    }
    if (uri.isScheme('http')) {
      AppEnvironment.log('WARNING: Connecting to WebDAV over unencrypted HTTP.');
    }

    final basicAuth =
        'Basic ${base64Encode(utf8.encode('$username:$password'))}';

    try {
      final response = await http
          .get(uri, headers: {'Authorization': basicAuth})
          .timeout(const Duration(seconds: 15));

      // 200 OK, 207 Multi-Status indicate successful WebDAV authentication
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Authentication failed (HTTP ${response.statusCode})');
      }
      throw Exception('WebDAV server returned HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to connect: $e');
    }
  }

  /// Upload database file to WebDAV
  Future<void> uploadToWebDAV(
    String url,
    String username,
    String password,
  ) async {
    final dbFile = await getDatabaseFile();
    if (!dbFile.existsSync()) {
      throw Exception('Database file not found');
    }

    try {
      final db = ref.read(databaseProvider);
      await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
    } catch (_) {}

    final bytes = await dbFile.readAsBytes();

    final basicAuth =
        'Basic ${base64Encode(utf8.encode('$username:$password'))}';
    final targetUrl = url.endsWith('/')
        ? '${url}astronaksh_backup.db'
        : '$url/astronaksh_backup.db';

    final response = await http
        .put(
          Uri.parse(targetUrl),
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/octet-stream',
          },
          body: bytes,
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      throw Exception(
        'Upload failed: Server returned HTTP ${response.statusCode}',
      );
    }
  }

  /// Download database file from WebDAV and restore
  Future<void> downloadAndRestoreFromWebDAV(
    String url,
    String username,
    String password,
  ) async {
    final basicAuth =
        'Basic ${base64Encode(utf8.encode('$username:$password'))}';
    final targetUrl = url.endsWith('/')
        ? '${url}astronaksh_backup.db'
        : '$url/astronaksh_backup.db';

    final response = await http
        .get(Uri.parse(targetUrl), headers: {'Authorization': basicAuth})
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      if (response.statusCode == 404) {
        throw Exception(
          'Backup file not found on cloud server (astronaksh_backup.db)',
        );
      }
      throw Exception(
        'Download failed: Server returned HTTP ${response.statusCode}',
      );
    }

    // Write to a temporary file and restore seamlessly
    final tempDir = Directory.systemTemp;
    final tempFile = File(
      p.join(tempDir.path, 'astronaksh_restore_${DateTime.now().millisecondsSinceEpoch}.db'),
    );
    try {
      await tempFile.writeAsBytes(response.bodyBytes);
      await restoreLocal(tempFile.path);
    } finally {
      if (tempFile.existsSync()) {
        try {
          tempFile.deleteSync();
        } catch (_) {}
      }
    }
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref);
});
