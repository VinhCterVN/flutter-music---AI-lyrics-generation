import 'dart:developer';

import 'package:flutter_ai_music/data/models/playlist.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../provider/auth_provider.dart';

class PlaylistService {
  final Ref ref;
  final SupabaseClient _supabase;

  PlaylistService(this.ref) : _supabase = ref.read(supabaseClientProvider);

  Future<String> toggleTrackToFavourite(int trackId) async {
    log('Toggling track $trackId to favourites');
    final userId = ref.read(currentUserProvider)?.id ?? "---";

    final existing = await _supabase.from('favourites').select().eq('track_id', trackId).single().maybeSingle();

    if (existing != null) {
      await _supabase.from('favourites').delete().eq('user_id', userId).eq('track_id', trackId);
      log('Track $trackId removed from favourites');
      return 'removed';
    }

    await _supabase.from('favourites').insert({'track_id': trackId});
    log('Track $trackId added to favourites');
    return 'added';
  }

  Future<List<Playlist>> getPlaylists() async {
    log('Fetching playlists from Supabase');
    // final favourite = await _supabase.from("favourites").select();
    final response = await _supabase
        .from("playlists")
        .select("""
          id, user_id, name, photo_url, created_at, updated_at,
          playlists_tracks (track_id)
          """);
    log('Playlists response: $response');
    return (response as List).map((e) => Playlist.fromJson(e)).toList();
  }

  Future<List<int>> getTrackIdsInPlaylist(String playlistId) async {
    final response = await _supabase.from('playlists_tracks').select('track_id').eq('playlist_id', playlistId);
    return (response as List).map((e) => e['track_id'] as int).toList();
  }

  Future<void> addTrackToPlaylist(String playlistId, int trackId) async {
    log('Adding track $trackId to playlist $playlistId');
    await _supabase.from('playlists_tracks').insert({'playlist_id': playlistId, 'track_id': trackId});
  }

  Future<void> removeTrackFromPlaylist(String playlistId, int trackId) async {
    log('Removing track $trackId from playlist $playlistId');
    await _supabase.from('playlists_tracks').delete().eq('playlist_id', playlistId).eq('track_id', trackId);
  }
}
