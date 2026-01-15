import 'dart:developer';

import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/artist.dart';

class ArtistService {
  final Ref ref;
  final SupabaseClient _supabase;

  ArtistService(this.ref) : _supabase = ref.read(supabaseClientProvider);

  Future<Artist> getArtist(String artistId) async {
    final response = await _supabase.from('artists').select().eq('id', artistId).single();
    return Artist.fromJson(response);
  }

  Future<void> getFollowedArtists() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final response = await _supabase.from('follows').select();
    log("Fetched followed artists: $response");
  }

  Future<bool> getFollowStatus(String artistId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return false;

    final existingFollow = await _supabase.from('follows').select().eq('artist_id', artistId).single().maybeSingle();
    return existingFollow != null;
  }

  Future<String> toggleFollowArtist(String artistId, ArtistType artistType) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return "User not logged in";

    final existingFollow = await _supabase.from('follows').select().eq('artist_id', artistId).single().maybeSingle();

    if (existingFollow != null) {
      await _supabase.from('follows').delete().eq('user_id', user.id).eq('artist_id', artistId);
      log('Unfollowed artist $artistId');
      return "Unfollowed artist";
    }

    final followData = {
      'user_id': user.id,
      'artist_id': artistId,
      'artist_type': artistType.toString().split('.').last,
    };
    await _supabase.from('follows').insert(followData);
    log('Followed artist $artistId');
    return "Followed artist";
  }
}
