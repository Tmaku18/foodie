import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const _dbName = 'foodie.db';
  static const _dbVersion = 2;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE restaurants(
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            distance_miles REAL NOT NULL,
            rating REAL NOT NULL,
            building_image_asset TEXT NOT NULL,
            food_images_csv TEXT NOT NULL,
            external_place_id TEXT,
            source TEXT,
            latitude REAL,
            longitude REAL,
            address_text TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE menu_items(
            id INTEGER PRIMARY KEY,
            restaurant_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            price REAL NOT NULL,
            description TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE basket_matches(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            restaurant_id INTEGER NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE reviews_or_notes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            restaurant_id INTEGER NOT NULL,
            text TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE restaurants ADD COLUMN external_place_id TEXT');
          await db.execute('ALTER TABLE restaurants ADD COLUMN source TEXT');
          await db.execute('ALTER TABLE restaurants ADD COLUMN latitude REAL');
          await db.execute('ALTER TABLE restaurants ADD COLUMN longitude REAL');
          await db.execute('ALTER TABLE restaurants ADD COLUMN address_text TEXT');
        }
      },
    );
  }
}
