import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_ai_music/data/models/wikipedia_summary.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();

  ApiService._internal();

  final Dio _dio = Dio(
    BaseOptions(connectTimeout: const Duration(milliseconds: 5000), receiveTimeout: const Duration(milliseconds: 5000)),
  );

  Future<Response> get(String url, {Map<String, dynamic>? queryParameters, Options? options}) async {
    return await _dio.get(url, queryParameters: queryParameters, options: options);
  }

  Future<WikipediaSummary> getSummary(String title) async {
    final response = await get('https://en.wikipedia.org/api/rest_v1/page/summary/$title');
    if (response.statusCode == 200) {
      return WikipediaSummary.fromJson(response.data);
    } else {
      throw Exception('Failed to load summary');
    }
  }

  Future<String?> uploadToCloudinary(PlatformFile file) async {
    final cloudName = dotenv.get("CLOUDINARY_CLOUD_NAME");
    final uploadPreset = dotenv.get("CLOUDINARY_UPLOAD_PRESET");

    final dio = Dio();
    final formData = FormData.fromMap({'upload_preset': uploadPreset, 'file': await MultipartFile.fromFile(file.path!)});
    final response = await dio.post(
      'https://api.cloudinary.com/v1_1/$cloudName/auto/upload',
      data: formData,
      onSendProgress: (sent, total) {
        final percent = (sent / total * 100).toStringAsFixed(0);
        log('Uploading: $percent%');
      },
    );

    return response.data['secure_url'];
  }
}
