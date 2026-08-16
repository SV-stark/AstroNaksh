import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'app_environment.dart';
import 'database.dart';

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
    // Copy file to target destination
    await dbFile.copy(targetPath);
  }

  /// Restore database from a local file path
  Future<void> restoreLocal(String sourcePath) async {
    final dbFile = await getDatabaseFile();
    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) {
      throw Exception('Source backup file not found.');
    }

    // 1. Close current database connection to release lock
    final db = ref.read(databaseProvider);
    await db.close();

    // 2. Overwrite the database file
    await sourceFile.copy(dbFile.path);

    // 3. Invalidate provider so next read creates a new connection
    ref.invalidate(databaseProvider);
  }

  /// Test connection to WebDAV server
  Future<bool> testWebDAV(String url, String username, String password) async {
    if (url.trim().isEmpty) {
      throw Exception('WebDAV URL cannot be empty');
    }
    final basicAuth =
        'Basic ${base64Encode(utf8.encode('$username:$password'))}';

    try {
      final uri = Uri.parse(url);
      final response = await http
          .get(uri, headers: {'Authorization': basicAuth})
          .timeout(const Duration(seconds: 15));

      // 200, 207 Multi-Status, or similar indicates WebDAV server accepts authentication.
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Authentication failed (HTTP ${response.statusCode})');
      }
      // Any other status below 500 implies the server answered and authenticated.
      return response.statusCode < 500;
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

  /// Download and restore database file from WebDAV
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

    final dbFile = await getDatabaseFile();

    // 1. Close current database connection
    final db = ref.read(databaseProvider);
    await db.close();

    // 2. Write the downloaded bytes to the db file
    await dbFile.writeAsBytes(response.bodyBytes);

    // 3. Invalidate provider to reopen connection
    ref.invalidate(databaseProvider);
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref);
});
