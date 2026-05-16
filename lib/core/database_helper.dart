// ignore_for_file: avoid_slow_async_io, unawaited_futures, deprecated_member_use, sort_constructors_first, implementation_imports
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'app_environment.dart';

class DatabaseHelper {
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await _initDatabase();
      return _database!;
    } catch (e) {
      throw DatabaseException('Failed to initialize database: $e');
    }
  }

  Future<Database> _initDatabase() async {
    try {
      final path = await AppEnvironment.getDatabasePath();
      AppEnvironment.log('DatabaseHelper: Opening database at $path');

      // Ensure directory exists
      final dir = Directory(dirname(path));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      return await openDatabase(
        path,
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: (db) async {
          // Verify database integrity on open
          // We check for columns here because Drift and sqflite share the same file
          // and might have conflicting versioning.
          try {
            final tableInfo = await db.rawQuery('PRAGMA table_info(charts)');
            final columns = tableInfo.map((e) => e['name'] as String).toList();

            if (!columns.contains('locationName')) {
              await db.execute(
                'ALTER TABLE charts ADD COLUMN locationName TEXT',
              );
              AppEnvironment.log(
                'DatabaseHelper: Added missing column locationName',
              );
            }
            if (!columns.contains('timezone')) {
              await db.execute('ALTER TABLE charts ADD COLUMN timezone TEXT');
              AppEnvironment.log(
                'DatabaseHelper: Added missing column timezone',
              );
            }
          } catch (e) {
            AppEnvironment.log(
              'DatabaseHelper: Error verifying schema on open - $e',
            );
          }

          if (!db.isOpen) {
            AppEnvironment.log(
              'DatabaseHelper: Warning - db.isOpen is false after openDatabase',
            );
          } else {
            AppEnvironment.log(
              'DatabaseHelper: Database opened successfully. Version: ${await db.getVersion()}',
            );
          }
        },
      );
    } catch (e) {
      throw DatabaseException('Error opening database: $e');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE charts(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          dateTime TEXT,
          latitude REAL,
          longitude REAL,
          locationName TEXT,
          timezone TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE settings(
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
    } catch (e) {
      throw DatabaseException('Error creating database tables: $e');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        // Add columns that might be missing from version 1
        // Check if columns exist first to avoid errors
        final tableInfo = await db.rawQuery('PRAGMA table_info(charts)');
        final columns = tableInfo.map((e) => e['name'] as String).toList();

        if (!columns.contains('locationName')) {
          await db.execute('ALTER TABLE charts ADD COLUMN locationName TEXT');
        }
        if (!columns.contains('timezone')) {
          await db.execute('ALTER TABLE charts ADD COLUMN timezone TEXT');
        }
      } catch (e) {
        AppEnvironment.log('DatabaseHelper: Error during upgrade - $e');
      }
    }
  }

  Future<int> insertChart(Map<String, dynamic> row) async {
    try {
      final db = await database;
      return await db.insert('charts', row);
    } catch (e) {
      throw DatabaseException('Error inserting chart: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCharts() async {
    try {
      final db = await database;
      return await db.query('charts', orderBy: 'id DESC');
    } catch (e) {
      throw DatabaseException('Error fetching charts: $e');
    }
  }

  Future<int> deleteChart(int id) async {
    try {
      final db = await database;
      return await db.delete('charts', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw DatabaseException('Error deleting chart: $e');
    }
  }
}

class DatabaseException implements Exception {
  DatabaseException(this.message);
  final String message;
  @override
  String toString() => 'DatabaseException: $message';
}
