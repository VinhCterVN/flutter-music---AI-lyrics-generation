
import 'package:dio/dio.dart';

import '../data/models/vibrant_request.dart';

class ImagePaletteService {
  static final ImagePaletteService instance = ImagePaletteService._internal();

  ImagePaletteService._internal();

  final Dio _paletteDio = Dio(
    BaseOptions(baseUrl: "https://image-palette-extractor.vercel.app/"),
  );

  Future<Palette> getPalette(VibrantRequest request) async {
    final response = await _paletteDio.post(
      "api/v1/vibrant/",
      data: request.toJson(),
    );
    return Palette.fromJson(response.data);
  }
}
