import 'dart:developer';

import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrackService {
  Stream<List<Track>> streamTrackList(WidgetRef ref) {
    final supabase = ref.read(supabaseClientProvider);

    return supabase
        .from('full_tracks_view')
        .stream(primaryKey: ['id'])
        .order('createdAt', ascending: false)
        .map((rows) => rows.map((e) => Track.fromJson(e)).toList());
  }

  Future<List<Track>> getAllTracks(WidgetRef ref) async {
    log('Fetching all tracks from Supabase');
    final supabase = ref.read(supabaseClientProvider);
    final response = await supabase.from('full_tracks_view').select().order('createdAt', ascending: false);
    return (response as List).map((e) => Track.fromJson(e)).toList();
  }
}
