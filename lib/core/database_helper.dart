import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    return await openDatabase(
      join(path, 'astronaksh.db'),
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE charts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        dateTime TEXT,
        latitude REAL,
        longitude REAL,
        locationName TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE settings(
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<int> insertChart(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('charts', row);
  }

  Future<List<Map<String, dynamic>>> getCharts() async {
    final db = await database;
    return await db.query('charts', orderBy: 'id DESC');
  }

  Future<int> deleteChart(int id) async {
    final db = await database;
    return await db.delete('charts', where: 'id = ?', whereArgs: [id]);
  }
}
