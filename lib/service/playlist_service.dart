import 'dart:developer';

import 'package:flutter_ai_music/data/models/playlist.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/auth_provider.dart';

class PlaylistService {
  final Ref ref;

  const PlaylistService(this.ref);

  Future<void> toggleTrackToFavourite(int trackId) async {
    log('Toggling track $trackId to favourites');
    final supabase = ref.read(supabaseClientProvider);
    final userId = ref.read(currentUserProvider)?.id ?? "---";

    final existing = await supabase.from('favourites').select().eq('track_id', trackId).single().maybeSingle();

    if (existing != null) {
      await supabase.from('favourites').delete().eq('user_id', userId).eq('track_id', trackId);
      log('Track $trackId removed from favourites');
    } else {
      await supabase.from('favourites').insert({'track_id': trackId});
      log('Track $trackId added to favourites');
    }
  }

  Future<List<Playlist>> getPlaylists() async {
    log('Fetching playlists from Supabase');
    final supabase = ref.read(supabaseClientProvider);
    final favourite = await supabase.from("favourites").select();
    final response = await supabase
        .from("playlists")
        .select("""
          id, user_id, name, created_at, updated_at,
          playlists_tracks (track_id)
          """)
        .eq('user_id', ref.read(currentUserProvider)?.id ?? "---");
    log('Playlists response: $response');
    return (response as List).map((e) => Playlist.fromJson(e)).toList();
  }
}
