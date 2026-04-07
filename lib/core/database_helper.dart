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
        version: 1,
        onCreate: _onCreate,
        onOpen: (db) async {
          // Verify database integrity on open
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
