import 'package:flutter/material.dart';
import 'package:flutter_ai_music/provider/audio_provider.dart';
import 'package:flutter_ai_music/ui/layout/animated_ambient_color_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlayingGradientColor extends ConsumerStatefulWidget {
  const PlayingGradientColor({super.key});

  @override
  ConsumerState<PlayingGradientColor> createState() => _PlayingGradientColorState();
}

class _PlayingGradientColorState extends ConsumerState<PlayingGradientColor>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;
    final currentTrack = ref.watch(currentTrackProvider);

    return currentTrack.when(
      data: (track) => AnimatedAmbientColorBuilder(
        builder: (color) => Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color, scheme.surfaceDim],
              ),
            ),
          ),
        ),
      ),
      error: (error, stack) => SizedBox.shrink(),
      loading: () => SizedBox.shrink(),
    );
  }
}
