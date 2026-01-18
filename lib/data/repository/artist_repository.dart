import 'package:flutter_ai_music/data/database/artist_database.dart';
import 'package:flutter_ai_music/data/models/artist.dart';

class ArtistRepository {
  static final Map<String, Artist> _artists = {};
  static final ArtistRepository instance = ArtistRepository.init();
  static late final ArtistDatabase _database;

  ArtistRepository.init();

  Future<void> init() async {
    _database = ArtistDatabase.instance;
    await _loadArtists();
  }

  Map<String, Artist> get artists => _artists;

  Future<void> _loadArtists() async {
    final artistsFromDb = await _database.getAllArtists();
    for (var artist in artistsFromDb) {
      _artists[artist.id] = artist;
    }
  }

  Artist? getArtistById(String id) => _artists[id];
}
