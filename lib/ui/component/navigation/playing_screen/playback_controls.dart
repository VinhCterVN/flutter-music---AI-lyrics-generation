import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:just_audio/just_audio.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../provider/audio_provider.dart';

class PlaybackControls extends ConsumerWidget {
  final ValueChanged<bool> onVisibilityChanged;

  const PlaybackControls({super.key, required this.onVisibilityChanged});

  void togglePlayPause(WidgetRef ref, bool isPlaying) {
    final playerController = ref.read(playerControllerProvider);
    if (isPlaying) {
      playerController.pause();
    } else {
      playerController.play();
    }
  }

  void toggleShuffle(WidgetRef ref) {
    final playerController = ref.read(playerControllerProvider);
    playerController.toggleShuffle();
  }

  void toggleRepeat(WidgetRef ref) {
    final playerController = ref.read(playerControllerProvider);
    playerController.switchRepeatMode();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(isPlayingProvider).value ?? false;
    final isBuffering = ref.watch(isBufferingProvider).value ?? false;
    final playerController = ref.watch(playerControllerProvider);
    final isShuffleOn = ref.watch(shuffleModeProvider).value ?? false;
    final loopMode = ref.watch(repeatModeProvider).value ?? LoopMode.off;
    final variant = Theme.of(context).colorScheme.surfaceContainerHighest;

    return VisibilityDetector(
      key: const Key('playback-controls-visibility-detector'),
      onVisibilityChanged: (info) => onVisibilityChanged(info.visibleFraction < 0.25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: HugeIcon(
              icon: HugeIconsStrokeRounded.shuffle,
              strokeWidth: isShuffleOn ? 3.0 : 1.5,
              color: isShuffleOn
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            iconSize: 28,
            onPressed: () => playerController.toggleShuffle(),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.skip_previous_rounded),
            iconSize: 40,
            onPressed: () => playerController.skipPrev(),
          ),
          const SizedBox(width: 16),
          Container(
            width: 79,
            height: 79,
            decoration: BoxDecoration(color: Theme.of(context).textTheme.bodyLarge?.color, shape: BoxShape.circle),
            child: isBuffering
                ? Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(variant),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                    iconSize: 48,
                    onPressed: () => togglePlayPause(ref, isPlaying),
                  ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.skip_next_rounded),
            iconSize: 40,
            onPressed: () => playerController.skipNext(),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: HugeIcon(
              icon: loopMode == LoopMode.one
                  ? HugeIcons.strokeRoundedRepeatOne01
                  : loopMode == LoopMode.all
                  ? HugeIcons.strokeRoundedRepeat
                  : HugeIcons.strokeRoundedRepeatOff,
              color: loopMode == LoopMode.off
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.primary,
              strokeWidth: loopMode == LoopMode.off ? 1.5 : 3.0,
            ),
            iconSize: 28,
            onPressed: () => toggleRepeat(ref),
          ),
        ],
      ),
    );
  }
}
