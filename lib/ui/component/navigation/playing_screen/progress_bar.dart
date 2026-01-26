import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../provider/audio_provider.dart';

class ProgressBar extends ConsumerWidget {
  final bool isUserSeeking;
  final double sliderProgress;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  const ProgressBar({
    super.key,
    required this.isUserSeeking,
    required this.sliderProgress,
    required this.onChanged,
    required this.onChangeEnd,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider).value;

    if (progress == null) return const SizedBox.shrink();

    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: isUserSeeking ? 3 : 5, end: isUserSeeking ? 5 : 3),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (context, trackHeight, child) => SliderTheme(
            data: SliderThemeData(
              trackHeight: trackHeight,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: Theme.of(context).textTheme.bodyLarge?.color,
              inactiveTrackColor: Theme.of(context).textTheme.bodyLarge?.color?.withAlpha((0.2 * 255).toInt()),
              thumbColor: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            child: child!,
          ),
          child: Slider(
            value: isUserSeeking ? sliderProgress : progress.position.inMilliseconds.toDouble(),
            max: (progress.duration?.inMilliseconds ?? 1).toDouble(),
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(progress.position),
                style: TextStyle(
                  fontFamily: "SpotifyMixUI",
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha((0.7 * 255).toInt()),
                ),
              ),
              Text(
                _formatDuration(progress.duration ?? Duration.zero),
                style: TextStyle(
                  fontFamily: "SpotifyMixUI",
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha((0.7 * 255).toInt()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
