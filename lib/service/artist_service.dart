import 'dart:developer';

import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/auth_provider.dart';
import 'package:flutter_ai_music/service/spotify_service.dart';
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

  Future<Artist> resolveArtist({
    required String artistId,
    required ArtistType artistType,
    String? fallbackName,
    String? fallbackImageUrl,
  }) async {
    if (artistType == ArtistType.SpotifyArtist) {
      final spotifyArtist = await SpotifyService.getSpotifyArtist(artistId);
      if (spotifyArtist != null) return spotifyArtist;
    }

    return Artist(
      id: artistId,
      name: (fallbackName == null || fallbackName.trim().isEmpty) ? 'Unknown Artist' : fallbackName.trim(),
      images: fallbackImageUrl == null || fallbackImageUrl.isEmpty
          ? const []
          : [ArtistImage(url: fallbackImageUrl, height: 640, width: 640)],
      popularity: 0,
      artistType: artistType,
    );
  }

  Future<void> getFollowedArtists() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final response = await _supabase.from('follows').select().eq('user_id', user.id);
    log("Fetched followed artists: $response");
  }

  Future<bool> getFollowStatus(String artistId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return false;
    if (artistId.isEmpty) return false;

    final existingFollow = await _supabase
        .from('follows')
        .select()
        .eq('user_id', user.id)
        .eq('artist_id', artistId)
        .maybeSingle();
    return existingFollow != null;
  }

  Future<String> toggleFollowArtist(String artistId, ArtistType artistType) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return "User not logged in";
    if (artistId.isEmpty) return "Artist profile is not available yet";

    final existingFollow = await _supabase
        .from('follows')
        .select()
        .eq('user_id', user.id)
        .eq('artist_id', artistId)
        .maybeSingle();

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
