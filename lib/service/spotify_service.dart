import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_ai_music/data/models/artist.dart';
import 'package:flutter_ai_music/service/secure_storage_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../data/enums/spotify_request.dart';

class SpotifyService {
  static final String _clientId = dotenv.get("SPOTIFY_CLIENT_ID");
  static final String _clientSecret = dotenv.get("SPOTIFY_CLIENT_SECRET");
  static final Dio _client = Dio(
    BaseOptions(baseUrl: 'https://api.spotify.com/v1/', headers: {'Content-Type': 'application/json'}),
  );

  static final SpotifyService _instance = SpotifyService._internal();

  factory SpotifyService() => _instance;

  SpotifyService._internal();

  static Future<SpotifyArtist?> getSpotifyArtist(String artistId) async => getSpotifyResource<SpotifyArtist>(
    resourceType: SpotifyResourceType.artist,
    id: artistId,
    transform: (json) => SpotifyArtist.fromJson(json),
  );

  static Future<T?> getSpotifyResource<T>({
    required SpotifyResourceType resourceType,
    required String id,
    required T Function(Map<String, dynamic> json) transform,
  }) async {
    final accessToken = await SecureStorageService.instance.read('spotify_access_token');
    final tokenEnsuredAtStr = await SecureStorageService.instance.read('spotify_token_ensured_at');
    final now = DateTime.now();

    bool isExpired = false;
    if (tokenEnsuredAtStr != null) {
      final ensuredAt = DateTime.parse(tokenEnsuredAtStr);
      isExpired = now.difference(ensuredAt).inSeconds >= 3600;
    }

    if (accessToken == null || tokenEnsuredAtStr == null || isExpired) {
      await _getAccessToken();
    }

    final token = await SecureStorageService.instance.read('spotify_access_token');
    try {
      final response = await _client.get(
        '${resourceType.path}/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode != 200) {
        log('Spotify request failed with status code: ${response.statusCode}');
        return null;
      }
      return transform(response.data);
    } on DioException catch (e, s) {
      log('Spotify request failed: $e', stackTrace: s);
      return null;
    }
  }

  static Future<void> _getAccessToken() async {
    final client = Dio();
    final response = await client.post(
      'https://accounts.spotify.com/api/token',
      data: {'grant_type': 'client_credentials', 'client_id': _clientId, 'client_secret': _clientSecret},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    final tokenResponse = SpotifyAccessTokenResponse.fromJson(response.data);
    SecureStorageService.instance.write('spotify_access_token', tokenResponse.accessToken);
    SecureStorageService.instance.write('spotify_token_type', tokenResponse.tokenType);
    SecureStorageService.instance.write('spotify_token_expires_in', tokenResponse.expiresIn.toString());
    SecureStorageService.instance.write('spotify_token_ensured_at', DateTime.now().toIso8601String());
    log("Obtained new Spotify access token");
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
