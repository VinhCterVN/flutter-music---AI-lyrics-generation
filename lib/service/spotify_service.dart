import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_ai_music/data/database/artist_database.dart';
import 'package:flutter_ai_music/data/models/artist.dart';
import 'package:flutter_ai_music/service/secure_storage_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:synchronized/synchronized.dart';

import '../data/enums/spotify_request.dart';

class SpotifyService {
  static final _lock = Lock();
  static String? _cachedAccessToken;
  static DateTime? _cachedEnsuredAt;
  static final String _clientId = dotenv.get("SPOTIFY_CLIENT_ID");
  static final String _clientSecret = dotenv.get("SPOTIFY_CLIENT_SECRET");
  static final Dio _client = Dio(
    BaseOptions(baseUrl: 'https://api.spotify.com/v1/', headers: {'Content-Type': 'application/json'}),
  );

  static final SpotifyService _instance = SpotifyService._internal();

  factory SpotifyService() => _instance;

  SpotifyService._internal();

  static Future<Artist?> getSpotifyArtist(String artistId) async {
    final cachedArtist = await ArtistDatabase.instance.getArtistById(artistId);
    if (cachedArtist != null) return cachedArtist;

    final artist = await getSpotifyResource<Artist>(
      resourceType: SpotifyResourceType.artist,
      id: artistId,
      transform: (json) => Artist.fromJson(json),
    );

    if (artist != null) {
      await ArtistDatabase.instance.insertArtist(artist);
    }

    return artist;
  }

  static Future<T?> getSpotifyResource<T>({
    required SpotifyResourceType resourceType,
    required String id,
    required T Function(Map<String, dynamic> json) transform,
  }) async {
    final token = await _ensureValidToken();
    if (token == null || id.isEmpty) return null;

    try {
      final response = await _client.get(
        '${resourceType.path}/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) return null;

      return transform(response.data);
    } on DioException catch (_) {
      return null;
    }
  }

  static Future<String?> _ensureValidToken() async {
    final now = DateTime.now();

    if (_cachedAccessToken != null && _cachedEnsuredAt != null) {
      final isExpired = now.difference(_cachedEnsuredAt!).inSeconds >= 3600;
      if (!isExpired) return _cachedAccessToken;
    }

    final storedToken = await SecureStorageService.instance.read('spotify_access_token');
    final ensuredAtStr = await SecureStorageService.instance.read('spotify_token_ensured_at');

    if (storedToken != null && ensuredAtStr != null) {
      final ensuredAt = DateTime.parse(ensuredAtStr);
      final isExpired = now.difference(ensuredAt).inSeconds >= 3600;

      if (!isExpired) {
        _cachedAccessToken = storedToken;
        _cachedEnsuredAt = ensuredAt;
        return storedToken;
      }
    }

    await _getAccessToken();
    return _cachedAccessToken;
  }

  static Future<void> _getAccessToken() async {
    await _lock.synchronized(() async {
      final accessToken = await SecureStorageService.instance.read('spotify_access_token');
      final tokenEnsuredAtStr = await SecureStorageService.instance.read('spotify_token_ensured_at');

      if (accessToken != null && tokenEnsuredAtStr != null) {
        final ensuredAt = DateTime.parse(tokenEnsuredAtStr);
        final isExpired = DateTime.now().difference(ensuredAt).inSeconds >= 3600;
        if (!isExpired) return;
      }

      final client = Dio();
      final response = await client.post(
        'https://accounts.spotify.com/api/token',
        data: {'grant_type': 'client_credentials', 'client_id': _clientId, 'client_secret': _clientSecret},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final tokenResponse = SpotifyAccessTokenResponse.fromJson(response.data);

      await SecureStorageService.instance.write('spotify_access_token', tokenResponse.accessToken);
      await SecureStorageService.instance.write('spotify_token_type', tokenResponse.tokenType);
      await SecureStorageService.instance.write('spotify_token_expires_in', tokenResponse.expiresIn.toString());
      await SecureStorageService.instance.write('spotify_token_ensured_at', DateTime.now().toIso8601String());

      log("Obtained new Spotify access token");
    });
  }
}

class SpotifyAccessTokenResponse {
  final String accessToken;
  final String tokenType;
  final int expiresIn;

  SpotifyAccessTokenResponse({required this.accessToken, required this.tokenType, required this.expiresIn});

  factory SpotifyAccessTokenResponse.fromJson(Map<String, dynamic> json) {
    return SpotifyAccessTokenResponse(
      accessToken: json['access_token'],
      tokenType: json['token_type'],
      expiresIn: json['expires_in'],
    );
  }
}
