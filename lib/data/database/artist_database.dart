import 'dart:developer';

import 'package:flutter_ai_music/data/models/artist.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class ArtistDatabase {
  static final ArtistDatabase instance = ArtistDatabase.init();
  static Database? _database;

  ArtistDatabase.init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('artists.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE artists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        images TEXT,
        popularity INTEGER,
        artist_type TEXT NOT NULL
      )
    ''');
  }

  Future<void> insertArtist(Artist artist) async {
    final db = await instance.database;
    await db.insert('artists', artist.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    log('Inserted artist ${artist.name} into the database.');
  }

  Future<void> insertArtists(List<Artist> artists) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var artist in artists) {
      batch.insert('artists', artist.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    log('Inserted ${artists.length} artists into the database.');
  }

  Future<Artist?> getArtistById(String id) async {
    final db = await instance.database;
    final result = await db.query('artists', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Artist.fromDatabase(result.first);
  }

  Future<List<Artist>> getAllArtists() async {
    final db = await instance.database;
    final result = await db.query('artists');
    return result.map((json) => Artist.fromDatabase(json)).toList();
  }
}
