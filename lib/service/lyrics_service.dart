import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/lyric_line.dart';
import '../data/models/track.dart';

// Lyrics Service
class LyricsService {
  final SupabaseClient _supabase;
  final Dio _dio;

  LyricsService(this._supabase, this._dio);

  Future<List<LyricsLine>> getLyrics(Track track) async {
    try {
      final response = await _supabase
          .from('lyric_lines')
          .select()
          .eq('track_id', track.id)
          .order('start_time', ascending: true);

      if (response.isEmpty) {
        return await _fetchAndStoreLyrics(track);
      }

      return (response as List).map((json) => LyricsLine.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<LyricsLine>> _fetchAndStoreLyrics(Track track) async {
    try {
      final response = await _dio.get(
        'https://lrclib.net/api/get',
        queryParameters: {
          'artist_name': track.artistName ?? track.artistId,
          'track_name': track.name,
        },
      );

      if (response.statusCode != 200 || response.data is! Map<String, dynamic>) {
        return [];
      }

      final syncedLyrics = (response.data['syncedLyrics'] as String?)?.trim();
      if (syncedLyrics == null || syncedLyrics.isEmpty) {
        return [];
      }

      final parsedLyrics = _parseSyncedLyrics(syncedLyrics);
      if (parsedLyrics.isEmpty) {
        return [];
      }

      await _supabase.from('lyric_lines').insert(
        parsedLyrics.map((line) {
          return {
            'track_id': track.id,
            'start_time': line.startTime.inMilliseconds / 1000.0,
            'end_time': line.endTime.inMilliseconds / 1000.0,
            'text': line.text,
          };
        }).toList(),
      );

      log('Fetched and inserted ${parsedLyrics.length} lyric lines for track ${track.id}');
      return parsedLyrics;
    } catch (e) {
      log('Failed to fetch lyrics from lrclib: $e');
      return [];
    }
  }

  List<LyricsLine> _parseSyncedLyrics(String syncedLyrics) {
    final matches = RegExp(r'^\[(\d{2}):(\d{2}(?:\.\d{1,3})?)\]\s*(.*)$', multiLine: true).allMatches(syncedLyrics).toList();
    if (matches.isEmpty) return [];

    final parsed = <({Duration startTime, String text})>[];
    for (final match in matches) {
      final minutes = int.parse(match.group(1)!);
      final seconds = double.parse(match.group(2)!);
      final text = match.group(3) ?? '';
      final startTime = Duration(minutes: minutes) + Duration(milliseconds: (seconds * 1000).round());
      parsed.add((startTime: startTime, text: text));
    }

    final lines = <LyricsLine>[];
    for (var i = 0; i < parsed.length; i++) {
      final current = parsed[i];
      final nextStart = i < parsed.length - 1
          ? parsed[i + 1].startTime
          : current.startTime + const Duration(seconds: 5);
      final endTime = nextStart > current.startTime ? nextStart : current.startTime + const Duration(milliseconds: 500);
      lines.add(LyricsLine(startTime: current.startTime, endTime: endTime, text: current.text));
    }

    return lines;
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
