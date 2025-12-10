import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';

import '../data/models/lyric_line.dart';

// Lyrics Service
class LyricsService {
  final SupabaseClient _supabase;
  final Dio _dio;

  LyricsService(this._supabase, this._dio);

  Future<List<LyricsLine>> getLyrics(int trackId) async {
    try {
      final response = await _supabase
          .from('lyric_lines')
          .select()
          .eq('track_id', trackId)
          .order('start_time', ascending: true);
      log("getLyrics called");
      if (response.isEmpty) {
        await _requestLyricsGeneration(trackId);
        throw LyricsNotFoundException('Lyrics are being generated');
      }

      return (response as List)
          .map((json) => LyricsLine.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _requestLyricsGeneration(int trackId) async {
    try {
      final res = await _dio.post(
        'https://nonpractical-shela-unhieratic.ngrok-free.dev/api/lyrics',
        data: {'track_id': trackId},
      );
      log("Generate request sent");
      log(res.data);
    } catch (e) {
      log('Failed to request lyrics generation: $e');
      throw LyricsGenerationException('Failed to request lyrics generation: $e');
    }
  }
}

// Exceptions
class LyricsNotFoundException implements Exception {
  final String message;
  LyricsNotFoundException(this.message);
}

class LyricsGenerationException implements Exception {
  final String message;
  LyricsGenerationException(this.message);
}
