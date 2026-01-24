import 'dart:developer';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_ai_music/service/network_service.dart';
import 'package:html/parser.dart';

import '../data/models/vibrant_request.dart';

Color mixColors(List<MapEntry<Color, double>> colors) {
  if (colors.isEmpty) return const Color(0x00000000); // Transparent

  double r = 0;
  double g = 0;
  double b = 0;
  double a = 0;
  double totalWeight = 0;

  for (var entry in colors) {
    final color = entry.key;
    final weight = entry.value;

    r += color.red * weight;
    g += color.green * weight;
    b += color.blue * weight;
    a += color.opacity * 255 * weight; // opacity 0–1 → 0–255
    totalWeight += weight;
  }

  if (totalWeight <= 0) return const Color(0x00000000);

  return Color.fromARGB(
    (a / totalWeight).round(),
    (r / totalWeight).round(),
    (g / totalWeight).round(),
    (b / totalWeight).round(),
  );
}

Color paletteToColor(PaletteColor color) {
  if (color.rgb.length != 3) {
    throw Exception("PaletteColor must have exactly 3 RGB values");
  }

  return Color.fromARGB(255, color.rgb[0].toInt(), color.rgb[1].toInt(), color.rgb[2].toInt());
}

Future<Color> getDominantColor(String? imageUrl) async {
  const defaultColor = Color(0xFF5D5DFF);

  if (imageUrl == null) return defaultColor;
  try {
    final palette = await ImagePaletteService.instance.getPalette(VibrantRequest(imageUrl));

    return paletteToColor(palette.darkVibrant);
  } on DioException catch (e) {
    log("Network error: ${e.message}");
    return defaultColor;
  } catch (e) {
    log("Unexpected error: $e");
    return defaultColor;
  }
}

String stripHtml(String htmlText) {
  final document = parse(htmlText);
  return parse(document.body?.text).documentElement?.text ?? '';
}