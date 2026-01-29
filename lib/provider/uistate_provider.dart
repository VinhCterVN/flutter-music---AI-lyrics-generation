import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/models/track.dart';
import '../utils/functions.dart';
import 'audio_provider.dart';

final animatedAmbientColorProvider = StateNotifierProvider<AnimatedAmbientColorNotifier, AnimatedColorState>(
  (ref) => AnimatedAmbientColorNotifier(initial: const Color(0xFF1A1A2E)),
);

final ambientColorControllerProvider = Provider<void>((ref) {
  ref.keepAlive();

  ref.listen<AsyncValue<Track?>>(currentTrackProvider, (previous, next) async {
    final track = next.value;
    if (track == null) return;

    final imageUrl = track.images.isNotEmpty ? track.images.first : null;
    if (imageUrl == null || imageUrl == previous?.value?.images.first) return;

    final dominantColor = await getDominantColor(imageUrl);
    if (ref.mounted) {
      ref.read(animatedAmbientColorProvider.notifier).animateTo(dominantColor);
    }
  });
});

class AnimatedAmbientColorNotifier extends StateNotifier<AnimatedColorState> {
  AnimatedAmbientColorNotifier({required Color initial}) : super(AnimatedColorState(from: initial, to: initial));

  void animateTo(Color next) {
    if (state.to == next) return;
    state = AnimatedColorState(from: state.to, to: next);
  }
}

class AnimatedColorState {
  final Color from;
  final Color to;

  const AnimatedColorState({required this.from, required this.to});
}
