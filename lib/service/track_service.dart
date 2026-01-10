import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrackService {

  Stream<List<Track>> streamTrackList(WidgetRef ref) {
    final supabase = ref.read(supabaseClientProvider);

    return supabase
        .from('full_tracks_view')
        .stream(primaryKey: ['id'])
        .order('name', ascending: true)
        .map((rows) => rows.map((e) => Track.fromJson(e)).toList());
  }
}