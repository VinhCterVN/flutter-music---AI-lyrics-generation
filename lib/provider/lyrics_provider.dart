
// Providers
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/lyric_line.dart';
import '../service/lyrics_service.dart';
import 'auth_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 120),
    receiveTimeout: const Duration(seconds: 120),
  ));
});

final lyricsServiceProvider = Provider<LyricsService>((ref) {
  return LyricsService(
    ref.watch(supabaseClientProvider),
    ref.watch(dioProvider),
  );
});

final lyricsStreamProvider = StreamProvider.family<List<LyricsLine>, int>((ref, trackId) {
  final supabase = ref.watch(supabaseClientProvider);

  return supabase
      .from('lyric_lines')
      .stream(primaryKey: ['id'])
      .eq('track_id', trackId)
      .order('start_time', ascending: true)
      .map((data) => data.map((json) => LyricsLine.fromJson(json)).toList());
});

// Future provider for initial fetch
final lyricsFutureProvider = FutureProvider.family<List<LyricsLine>, int>((ref, trackId) async {
  final service = ref.watch(lyricsServiceProvider);
  return await service.getLyrics(trackId);
});