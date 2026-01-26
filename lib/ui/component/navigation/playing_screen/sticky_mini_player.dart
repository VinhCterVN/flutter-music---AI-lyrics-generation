import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/track.dart';
import '../../../../provider/artist_provider.dart';
import '../../../../provider/audio_provider.dart';

class StickyMiniPlayer extends ConsumerWidget {
  final Track track;

  const StickyMiniPlayer({super.key, required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(isPlayingProvider).value ?? false;
    final isBuffering = ref.watch(isBufferingProvider).value ?? false;
    final playerController = ref.watch(playerControllerProvider);
    final currentArtist = ref.watch(currentArtistProvider).value;
    final progress = ref.watch(progressProvider).value;

    final progressValue = progress != null && progress.duration != null && progress.duration!.inMilliseconds > 0
        ? progress.position.inMilliseconds / progress.duration!.inMilliseconds
        : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withAlpha(200),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(30), width: 1),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 20, offset: const Offset(0, 4))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
                child: Row(
                  children: [
                    // Album Art
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: track.images.first,
                          fit: BoxFit.cover,
                          errorWidget: (context, error, stackTrace) => Container(
                            color: Colors.grey[900],
                            child: const Icon(Icons.music_note, size: 24, color: Colors.white54),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Track Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            track.name,
                            style: const TextStyle(
                              fontFamily: "SpotifyMixUI",
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentArtist?.name ?? 'Unknown Artist',
                            style: TextStyle(
                              fontFamily: "SpotifyMixUI",
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha((0.7 * 255).toInt()),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Play/Pause Button
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        shape: BoxShape.circle,
                      ),
                      child: isBuffering
                          ? Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).scaffoldBackgroundColor),
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Theme.of(context).scaffoldBackgroundColor,
                              ),
                              iconSize: 26,
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                if (isPlaying) {
                                  playerController.pause();
                                } else {
                                  playerController.play();
                                }
                              },
                            ),
                    ),
                    const SizedBox(width: 4),
                    // Skip Next Button
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      iconSize: 32,
                      onPressed: () => playerController.skipNext(),
                    ),
                  ],
                ),
              ),
              // Progress Bar
              Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(40),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressValue.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
