import 'package:flutter_ai_music/data/models/playlist.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../provider/auth_provider.dart';

class PlaylistService {
  final Ref ref;
  final SupabaseClient _supabase;

  PlaylistService(this.ref) : _supabase = ref.read(supabaseClientProvider);

  Future<String> toggleTrackToFavourite(int trackId) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) throw Exception('User not logged in');

    final existing = await _supabase.from('favourites').select().eq('track_id', trackId).single().maybeSingle();

    if (existing != null) {
      await _supabase.from('favourites').delete().eq('user_id', userId).eq('track_id', trackId);
      return 'removed';
    }
    await _supabase.from('favourites').insert({'track_id': trackId});
    return 'added';
  }

  Future<Playlist> createPlaylist(String name, {String? photoUrl, List<int> initialTrackIds = const []}) async {
    final response = await _supabase.from('playlists').insert({'name': name, 'photo_url': photoUrl}).select().single();
    if (initialTrackIds.isNotEmpty) {
      final playlistId = response['id'] as String;
      final tracksToInsert = initialTrackIds
          .map((trackId) => {'playlist_id': playlistId, 'track_id': trackId})
          .toList();
      await _supabase.from('playlists_tracks').insert(tracksToInsert);
    }
    final fullResponse = await _supabase
        .from('playlists')
        .select("""
          id, user_id, name, photo_url, created_at, updated_at,
          playlists_tracks (track_id)
          """)
        .eq('id', response['id'])
        .single();
    return Playlist.fromJson(fullResponse);
  }

  Future<List<Playlist>> getPlaylists() async {
    final response = await _supabase.from("playlists").select("""
          id, user_id, name, photo_url, created_at, updated_at,
          playlists_tracks (track_id)
          """);
    return (response as List).map((e) => Playlist.fromJson(e)).toList();
  }

  Future<List<Playlist>> getPlaylistByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final response = await _supabase
        .from("playlists")
        .select("""
          id, user_id, name, photo_url, created_at, updated_at,
          playlists_tracks (track_id)
          """)
        .inFilter('id', ids);
    return (response as List).map((e) => Playlist.fromJson(e)).toList();
  }

  Future<List<int>> getTrackIdsInPlaylist(String playlistId) async {
    final response = await _supabase.from('playlists_tracks').select('track_id').eq('playlist_id', playlistId);
    return (response as List).map((e) => e['track_id'] as int).toList();
  }

  Future<void> addTrackToPlaylist(String playlistId, int trackId) async {
    await _supabase.from('playlists_tracks').insert({'playlist_id': playlistId, 'track_id': trackId});
  }

  Future<void> addTracksToPlaylist(String playlistId, List<int> trackIds) async {
    final tracksToInsert = trackIds.map((trackId) => {'playlist_id': playlistId, 'track_id': trackId}).toList();
    await _supabase.from('playlists_tracks').insert(tracksToInsert);
  }

  Future<void> removeTrackFromPlaylist(String playlistId, int trackId) async {
    await _supabase.from('playlists_tracks').delete().eq('playlist_id', playlistId).eq('track_id', trackId);
  }

  Future<void> updatePlaylistPhoto(String playlistId, String photoUrl) async {
    await _supabase.from('playlists').update({'photo_url': photoUrl}).eq('id', playlistId);
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    await _supabase.from('playlists').update({'name': newName}).eq('id', playlistId);
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _supabase.from('playlists').delete().eq('id', playlistId);
  }

  Future<List<int>> getFavouriteTrackIds() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return [];
    final res = await _supabase
        .from('favourites')
        .select('track_id')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (res as List).map((e) => e['track_id'] as int).toList();
  }

  Future<List<WeeklyHistory>> getWeeklyHistory() async {
    final res = await _supabase.rpc('get_weekly_history');
    return (res as List).map((e) => WeeklyHistory.fromJson(e)).toList();
  }

  /// Stream playlists with real-time updates from Supabase.
  /// Returns max [limit] playlists sorted by created_at desc.
  Stream<List<Playlist>> streamPlaylists({int limit = 10}) {
    return _supabase
        .from('playlists')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .limit(limit)
        .asyncMap((event) async {
          final playlists = event.map((e) => Playlist.fromJson(e)).toList();
          if (playlists.isEmpty) return playlists;

          final playlistIds = playlists.map((p) => p.id).toList();
          final relatedData = await _supabase
              .from('playlists_tracks')
              .select('playlist_id, track_id')
              .inFilter('playlist_id', playlistIds);

          for (var playlist in playlists) {
            final tracksForThisPlaylist = (relatedData as List)
                .where((item) => item['playlist_id'] == playlist.id)
                .map((item) => item['track_id'])
                .toList();

            playlist.trackIds.addAll(tracksForThisPlaylist.cast<int>());
          }

          return playlists;
        });
  }
}
