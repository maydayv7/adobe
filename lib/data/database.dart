// lib/data/database.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'pinterest.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE images (
            id TEXT PRIMARY KEY,
            filePath TEXT,
            createdAt TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE boards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            createdAt TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE board_images (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            board_id INTEGER,
            image_id TEXT,
            createdAt TEXT
          )
        ''');
      },
    );
  }
}
