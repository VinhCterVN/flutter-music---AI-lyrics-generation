// providers/ambient_color_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../utils/functions.dart';
import 'audio_provider.dart';

final ambientColorProvider = StateProvider<Color>((ref) {
  return const Color(0xFF1A1A2E); // default dark color
});

final ambientColorControllerProvider = Provider((ref) {
  ref.listen(currentTrackProvider, (previous, next) async {
    if (next.value == null) return;

    final track = next.value!;
    final imageUrl = track.images.isNotEmpty ? track.images.first : null;

    if (imageUrl == null || imageUrl == previous?.value?.images.first) return;

    final dominantColor = await getDominantColor(imageUrl);

    if (ref.mounted) {
      ref.read(ambientColorProvider.notifier).state = dominantColor;
    }
  });
});