import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/lyric_line.dart';
import '../../../../data/models/track.dart';
import '../../../../provider/audio_provider.dart';
import '../../../../provider/lyrics_provider.dart';
import '../../../../provider/user_preferences_provider.dart';
import '../lyrics_display.dart';

/// A single synced lyric that opens the full lyrics view when tapped.
class CurrentLyricLine extends ConsumerWidget {
  const CurrentLyricLine({
    super.key,
    required this.track,
    this.textStyle,
    this.position,
  });

  final Track track;
  final TextStyle? textStyle;

  /// Overrides playback position while the user drags the progress slider.
  final Duration? position;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(showAnimatedLyricsProvider)) return const SizedBox(height: 50);
    final streamedLyrics = ref.watch(lyricsStreamProvider(track.id)).value;
    final lyrics = streamedLyrics != null && streamedLyrics.isNotEmpty
        ? streamedLyrics
        : ref.watch(lyricsFutureProvider(track)).value ?? const <LyricsLine>[];
    final playbackPosition =
        position ??
        ref.watch(progressProvider).value?.position ??
        Duration.zero;
    final index = _currentLineIndex(lyrics, playbackPosition);
    final text = index < 0 ? '' : lyrics[index].text;
    final style = const TextStyle(
      fontFamily: 'SpotifyMixUI',
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.25,
      height: 1.3,
      color: Colors.white,
    ).merge(textStyle);
    final scaledLineHeight =
        MediaQuery.textScalerOf(context).scale(style.fontSize!) *
            style.height! +
        12;

    return Semantics(
      button: true,
      label: 'Open expanded lyrics',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LyricsDisplayWidget(track: track),
          ),
        ),
        child: SizedBox(
          height: scaledLineHeight > 50 ? scaledLineHeight : 50,
          width: double.infinity,
          child: ClipRect(
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.white,
                  Colors.white,
                  Colors.transparent,
                ],
                stops: [0, 0.2, 0.8, 1],
              ).createShader(bounds),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => AnimatedBuilder(
                  animation: animation,
                  child: FadeTransition(opacity: animation, child: child),
                  builder: (context, child) {
                    final outgoing =
                        animation.status == AnimationStatus.reverse ||
                        animation.status == AnimationStatus.dismissed;
                    return FractionalTranslation(
                      translation: Offset(
                        0,
                        (outgoing ? -1 : 1) * (1 - animation.value),
                      ),
                      child: child,
                    );
                  },
                ),
                child: Center(
                  key: ValueKey((track.id, index, text)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      text,
                      style: style,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _currentLineIndex(List<LyricsLine> lyrics, Duration position) {
    var low = 0;
    var high = lyrics.length - 1;
    while (low <= high) {
      final mid = low + ((high - low) >> 1);
      final line = lyrics[mid];
      if (position < line.startTime) {
        high = mid - 1;
      } else if (position >= line.endTime) {
        low = mid + 1;
      } else {
        return mid;
      }
    }
    return -1;
  }
}
