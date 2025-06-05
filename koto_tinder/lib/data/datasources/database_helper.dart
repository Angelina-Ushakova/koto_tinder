import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:koto_tinder/domain/entities/cat.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'koto_tinder.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cats(
        id TEXT PRIMARY KEY,
        url TEXT NOT NULL,
        breeds TEXT,
        likedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cached_cats(
        id TEXT PRIMARY KEY,
        url TEXT NOT NULL,
        breeds TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // Методы для работы с лайкнутыми котиками
  Future<int> insertLikedCat(Cat cat) async {
    final db = await database;
    return await db.insert('cats', {
      'id': cat.id,
      'url': cat.url,
      'breeds':
          cat.breeds != null
              ? jsonEncode(cat.breeds!.map((b) => b.toJson()).toList())
              : null,
      'likedAt': cat.likedAt?.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deleteLikedCat(String catId) async {
    final db = await database;
    return await db.delete('cats', where: 'id = ?', whereArgs: [catId]);
  }

  Future<List<Cat>> getLikedCats() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cats',
      orderBy: 'likedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Cat(
        id: maps[i]['id'],
        url: maps[i]['url'],
        breeds:
            maps[i]['breeds'] != null
                ? List<Breed>.from(
                  jsonDecode(maps[i]['breeds']).map((x) => Breed.fromJson(x)),
                )
                : null,
        likedAt:
            maps[i]['likedAt'] != null
                ? DateTime.parse(maps[i]['likedAt'])
                : null,
      );
    });
  }

  Future<List<Cat>> getLikedCatsByBreed(String breed) async {
    final allCats = await getLikedCats();
    if (breed.isEmpty) return allCats;

    return allCats
        .where(
          (cat) =>
              cat.breeds != null &&
              cat.breeds!.isNotEmpty &&
              cat.breeds![0].name == breed,
        )
        .toList();
  }

  // Методы для работы с кэшированными котиками
  Future<int> insertCachedCat(Cat cat) async {
    final db = await database;
    return await db.insert('cached_cats', {
      'id': cat.id,
      'url': cat.url,
      'breeds':
          cat.breeds != null
              ? jsonEncode(cat.breeds!.map((b) => b.toJson()).toList())
              : null,
      'createdAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Cat>> getCachedCats({int limit = 20}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cached_cats',
      orderBy: 'createdAt DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return Cat(
        id: maps[i]['id'],
        url: maps[i]['url'],
        breeds:
            maps[i]['breeds'] != null
                ? List<Breed>.from(
                  jsonDecode(maps[i]['breeds']).map((x) => Breed.fromJson(x)),
                )
                : null,
      );
    });
  }

  Future<void> clearOldCachedCats({int keepCount = 50}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cached_cats',
      orderBy: 'createdAt DESC',
      limit: -1,
      offset: keepCount,
    );

    for (final map in maps) {
      await db.delete('cached_cats', where: 'id = ?', whereArgs: [map['id']]);
    }
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
