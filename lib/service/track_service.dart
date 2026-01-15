import 'dart:developer';

import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrackService {
  final Ref ref;
  final SupabaseClient _supabase;

  TrackService(this.ref) : _supabase = ref.read(supabaseClientProvider);

  Stream<List<Track>> streamTrackList() {
    return _supabase
        .from('full_tracks_view')
        .stream(primaryKey: ['id'])
        .order('createdAt', ascending: false)
        .map((rows) => rows.map((e) => Track.fromJson(e)).toList());
  }

  Future<List<Track>> getAllTracks() async {
    log('Fetching all tracks from Supabase');
    final response = await _supabase
        .from("tracks")
        .select("""
            id, name, uri, artist_id, artist_type, genres, created_at, updated_at,
            images (url),
            favourites!left (id)
              """)
        .order('created_at', ascending: false);
    return (response as List).map((e) => Track.fromJson(e)).toList();
  }

  Future<List<Track>> searchTracks(String query) async {
    log('Searching tracks from Supabase with query: $query');

    if (query.isEmpty) {
      final response = await _supabase
          .from("tracks")
          .select("""
            id, name, uri, artist_id, artist_type, genres, created_at, updated_at,
            images (url),
            favourites!left (id)
              """)
          .order('created_at', ascending: false);
      return (response as List).map((e) => Track.fromJson(e)).toList();
    }

    final response = await _supabase.rpc('search_tracks_fuzzy', params: {'search_query': query});
    final result = (response as List).map((e) => Track.fromJson(e)).toList();
    return result;
  }
}
