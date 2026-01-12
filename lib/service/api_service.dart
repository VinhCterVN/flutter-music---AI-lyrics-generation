import 'package:dio/dio.dart';
import 'package:flutter_ai_music/data/models/wikipedia_summary.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  final Dio _dio = Dio(
    BaseOptions(connectTimeout: const Duration(milliseconds: 5000), receiveTimeout: const Duration(milliseconds: 5000)),
  );

  Future<Response> get(String url, {Map<String, dynamic>? queryParameters, Options? options }) async {
    return await _dio.get(url, queryParameters: queryParameters, options: options);
  }

  Future<WikipediaSummary> getSummary(String title) async {
    final response = await get(
      'https://en.wikipedia.org/api/rest_v1/page/summary/$title',
    );
    if (response.statusCode == 200) {
      return WikipediaSummary.fromJson(response.data);
    } else {
      throw Exception('Failed to load summary');
    }
  }
}
