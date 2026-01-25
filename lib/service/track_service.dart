import 'dart:developer';

import 'package:flutter_ai_music/data/database/track_database.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/auth_provider.dart';
import 'package:flutter_ai_music/service/spotify_service.dart';
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

  /// Params:
  /// - [page]: The page number to fetch (starting from 0).
  /// - [pageSize]: The number of tracks per page.
  ///
  /// Returns a list of [Track] objects.
  Future<TrackPage> getTrackPage({int page = 0, int pageSize = 10}) async {
    log('Fetching tracks from Supabase: page $page, pageSize $pageSize');

    final response = await _supabase
        .from("tracks")
        .select("""
            id, name, uri, artist_id, artist_type, genres, created_at, updated_at,
            images (url),
            favourites!left (id)
         """)
        .range(page * pageSize, page * pageSize + pageSize)
        .order('created_at', ascending: false);

    final list = response as List;
    final hasNextPage = list.length > pageSize;
    final trimmedList = hasNextPage ? list.sublist(0, pageSize) : list;
    final tracksWithArtist = trimmedList.map((e) async {
      final isSpotifyArtist = e['artist_type'] == 'SpotifyArtist';
      final artist = isSpotifyArtist ? await SpotifyService.getSpotifyArtist(e['artist_id'] ?? '') : null;

      return Track.fromJson(e).copyWith(artistName: artist?.name);
    }).toList();

    final trackList = await Future.wait(tracksWithArtist);
    TrackDatabase.instance.insertTracks(trackList);
    return TrackPage(data: trackList, total: trackList.length, hasNextPage: hasNextPage);
  }

  Future<List<Track>> getTracksByIds(List<String> ids) async {
    log('Fetching tracks by IDs from Supabase: $ids');

    if (ids.isEmpty) return [];

    final response = await _supabase
        .from("tracks")
        .select("""
            id, name, uri, artist_id, artist_type, genres, created_at, updated_at,
            images (url),
            favourites!left (id)
              """)
        .inFilter('id', ids);
    final trackWithArtist = (response as List).map((e) async {
      final isSpotifyArtist = e['artist_type'] == 'SpotifyArtist';
      final artist = isSpotifyArtist ? await SpotifyService.getSpotifyArtist(e['artist_id'] ?? '') : null;

      return Track.fromJson(e).copyWith(artistName: artist?.name);
    }).toList();
    // return (response as List).map((e) => Track.fromJson(e)).toList();
    return await Future.wait(trackWithArtist);
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
