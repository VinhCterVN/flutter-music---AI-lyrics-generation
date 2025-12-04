import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_ai_music/data/models/track.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();

  ApiService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "https://nonpractical-shela-unhieratic.ngrok-free.dev/",
      headers: {"Authorization": "Bearer Vincent", 'Accept': 'application/json'},
      connectTimeout: const Duration(milliseconds: 5000),
      receiveTimeout: const Duration(milliseconds: 5000),
    ),
  );

  Future<List<Track>> getTracks() async {
    final res = await _dio.get("tracks");
    final List<dynamic> data = json.decode(res.data);

    return data.map((e) => Track.fromJson(e)).toList();
  }
}
