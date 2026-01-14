import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/track.dart';

class TrackDatabase {
  static final TrackDatabase instance = TrackDatabase._init();
  static Database? _database;

  TrackDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tracks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tracks (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        uri TEXT NOT NULL,
        artistId TEXT NOT NULL,
        artistName TEXT,
        artistType TEXT NOT NULL,
        genres TEXT,
        images TEXT,
        isFavorite INTEGER,
        createdAt TEXT
      )
    ''');
  }

  Future<int> getTracksCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM tracks');
    final count = Sqflite.firstIntValue(result);
    return count ?? 0;
  }

  Future<void> insertTrack(Track track) async {
    final db = await instance.database;
    await db.insert('tracks', track.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertTracks(List<Track> tracks) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var track in tracks) {
      batch.insert('tracks', track.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Track>> getAllTracks() async {
    final db = await instance.database;
    final result = await db.query('tracks', orderBy: 'createdAt DESC');

    return result.map((json) {
      return Track(
        id: json['id'] as int,
        name: json['name'] as String,
        uri: json['uri'] as String,
        artistId: json['artistId'] as String,
        artistName: json['artistName'] as String?,
        artistType: ArtistType.values.byName(json['artistType'] as String),
        genres: List<String>.from(jsonDecode(json['genres'] as String)),
        images: List<String>.from(jsonDecode(json['images'] as String)),
        isFavorite: json['isFavorite'] == 1,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
    }).toList();
  }

  Future<void> deleteAllTracks() async {
    final db = await instance.database;
    await db.delete('tracks');
  }
}
