import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/enums/constraints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../provider/audio_provider.dart';

class AlbumArtwork extends ConsumerWidget {
  final String? imageUrl;
  final Animation<double> pulseAnimation;

  const AlbumArtwork({super.key, required this.imageUrl, required this.pulseAnimation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(isPlayingProvider).value ?? false;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isPlaying ? pulseAnimation.value : 1.0,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withAlpha(100),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Hero(
                  tag: "now-playing-track-$imageUrl",
                  child: CachedNetworkImage(
                    imageUrl: imageUrl ?? url,
                    fit: BoxFit.cover,
                    errorWidget: (context, error, stackTrace) => Container(
                      color: Colors.grey[900],
                      child: const Icon(Icons.music_note, size: 100, color: Colors.white54),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
