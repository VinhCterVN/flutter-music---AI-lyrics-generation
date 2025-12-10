import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ai_music/provider/uistate_provider.dart';
import 'package:flutter_ai_music/ui/component/navigation/lyrics_display.dart';
import 'package:flutter_ai_music/ui/component/navigation/queue_bottom_sheet.dart';
import 'package:flutter_ai_music/utils/functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../../data/models/lyric_line.dart';
import '../../../data/models/track.dart';
import '../../../provider/audio_provider.dart';
import '../element/artist_card.dart';

class PlayingScreen extends ConsumerStatefulWidget {
  final ScrollController? scrollController;

  const PlayingScreen({super.key, this.scrollController});

  @override
  ConsumerState<PlayingScreen> createState() => _PlayingScreenState();
}

class _PlayingScreenState extends ConsumerState<PlayingScreen> with TickerProviderStateMixin {
  bool _isUserSeeking = false;
  double _sliderProgress = 0.0;
  Color? _previousColor;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _colorController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)
      ..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.fastOutSlowIn));

    _colorController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);

    final initialColor = ref.read(ambientColorProvider);
    _previousColor = initialColor;
    _colorAnimation = ColorTween(
      begin: initialColor,
      end: initialColor,
    ).animate(CurvedAnimation(parent: _colorController, curve: Curves.easeInOut));
    _colorController.value = 1.0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentColor = ref.read(ambientColorProvider);
    if (_previousColor != currentColor && mounted) {
      _previousColor = currentColor;
      _colorAnimation = ColorTween(
        begin: currentColor,
        end: currentColor,
      ).animate(CurvedAnimation(parent: _colorController, curve: Curves.easeInOut));
      _colorController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme
        .of(context)
        .colorScheme
        .surface;
    final currentTrackAsync = ref.watch(currentTrackProvider);
    final screenHeight =
        MediaQuery
            .of(context)
            .size
            .height -
            MediaQuery
                .of(context)
                .padding
                .top -
            MediaQuery
                .of(context)
                .padding
                .bottom -
            40;
    ref.listen<Color>(ambientColorProvider, (previous, next) {
      if (previous != next && mounted) {
        final currentAnimatedValue = _colorAnimation.value ?? previous;
        if (currentAnimatedValue != next) {
          _previousColor = currentAnimatedValue;
          _colorAnimation = ColorTween(
            begin: currentAnimatedValue,
            end: next,
          ).animate(CurvedAnimation(parent: _colorController, curve: Curves.easeInOut));
          _colorController
            ..reset()
            ..forward();
        }
      }
    });

    return currentTrackAsync.when(
      data: (currentTrack) {
        if (currentTrack == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset("assets/animations/impress.json", width: 300, repeat: false),
                  Text("Select any Track to start listening"),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: AnimatedBuilder(
            animation: _colorAnimation,
            builder: (context, child) {
              final animatedColor = _colorAnimation.value;
              if (animatedColor == null) return const SizedBox.shrink();

              return RepaintBoundary(
                child: _AnimatedGradientBackground(
                  animatedColor: animatedColor,
                  surfaceColor: surfaceColor,
                  child: CustomScrollView(
                    controller: widget.scrollController,
                    slivers: <Widget>[
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: screenHeight,
                          child: Column(
                            children: [
                              _AnimatedAppBar(
                                animatedColor: animatedColor,
                                surfaceColor: surfaceColor,
                                onBackPressed: () => Navigator.of(context).pop(),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _AlbumArtwork(
                                        imageUrl: currentTrack.images.first,
                                        ambientColor: animatedColor,
                                        pulseAnimation: _pulseAnimation,
                                      ),
                                      const SizedBox(height: 50),
                                      _TrackInfo(track: currentTrack),
                                      const SizedBox(height: 16),
                                      _ProgressBar(
                                        isUserSeeking: _isUserSeeking,
                                        sliderProgress: _sliderProgress,
                                        onChanged: (value) {
                                          setState(() {
                                            _sliderProgress = value;
                                            _isUserSeeking = true;
                                          });
                                        },
                                        onChangeEnd: (value) async {
                                          setState(() {
                                            _isUserSeeking = false;
                                          });
                                          await ref
                                              .read(audioPlayerProvider)
                                              .seek(Duration(milliseconds: value.toInt()));
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      const _PlaybackControls(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: ArtistCard(
                          borderRadius: BorderRadius.circular(20),
                          imageBorderRadius: BorderRadius.circular(12),
                          artistId: currentTrack.artistId,
                          artistType: currentTrack.artistType,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                final lyricsFile = await rootBundle.loadString('assets/lyrics.txt');
                                final lines = lyricsFile.split('\n');
                                final lyrics = lines
                                    .where((line) =>
                                line
                                    .trim()
                                    .isNotEmpty)
                                    .map((line) => LyricsLine.fromString(line))
                                    .toList();

                                if (!context.mounted) return;

                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        LyricsDisplayWidget(
                                          trackId: currentTrack.id,
                                          trackTitle: currentTrack.name,
                                          artistName: currentTrack.artistType.name,
                                          backgroundColor: animatedColor,
                                        ),
                                  ),
                                );
                              } catch (e) {
                                print('Error loading lyrics: $e');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _colorAnimation.value,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              'Bấm xem trước lời bài hát',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset("assets/animations/Error 404.json", width: 300, repeat: false),
                  Text("Error happened"),
                ],
              ),
            ),
          ),
    );
  }
}

class _AnimatedGradientBackground extends StatelessWidget {
  final Color animatedColor;
  final Color surfaceColor;
  final Widget child;

  const _AnimatedGradientBackground({required this.animatedColor, required this.surfaceColor, required this.child});

  @override
  Widget build(BuildContext context) {
    final containerColor = mixColors([MapEntry(surfaceColor, 0.3), MapEntry(animatedColor, 0.7)]);
    final color1 = mixColors([MapEntry(containerColor, 0.8), MapEntry(surfaceColor, 0.2)]);
    final color2 = mixColors([MapEntry(containerColor, 0.8), MapEntry(surfaceColor, 0.4)]);
    final color3 = mixColors([MapEntry(containerColor, 0.2), MapEntry(surfaceColor, 0.8)]);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color1, color2, color3],
        ),
      ),
      child: child,
    );
  }
}

class _AnimatedAppBar extends StatelessWidget {
  final Color animatedColor;
  final Color surfaceColor;
  final VoidCallback onBackPressed;

  const _AnimatedAppBar({required this.animatedColor, required this.surfaceColor, required this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    final containerColor = mixColors([MapEntry(surfaceColor, 0.3), MapEntry(animatedColor, 0.7)]);
    final color1 = mixColors([MapEntry(containerColor, 0.9), MapEntry(surfaceColor, 0.1)]);
    final color2 = mixColors([MapEntry(containerColor, 0.8), MapEntry(surfaceColor, 0.2)]);

    return RepaintBoundary(
      child: Container(
        padding: EdgeInsets.only(top: MediaQuery
            .of(context)
            .padding
            .top),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color1, color2]),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.keyboard_arrow_down, size: 32), onPressed: onBackPressed),
              const Text(
                'Playing View',
                style: TextStyle(
                  fontSize: 22,
                  fontFamily: "SpotifyMixUI",
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              IconButton(icon: const Icon(Icons.more_vert, size: 28), onPressed: () {}),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlbumArtwork extends ConsumerWidget {
  final String imageUrl;
  final Color ambientColor;
  final Animation<double> pulseAnimation;

  const _AlbumArtwork({required this.imageUrl, required this.ambientColor, required this.pulseAnimation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref
        .watch(isPlayingProvider)
        .value ?? false;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isPlaying ? pulseAnimation.value : 1.0,
            child: Container(
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 0.9,
              height: MediaQuery
                  .of(context)
                  .size
                  .width * 0.9,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: ambientColor.withAlpha(85), blurRadius: 30, spreadRadius: 5)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  cacheWidth: (MediaQuery
                      .of(context)
                      .size
                      .width * 0.9 * MediaQuery
                      .of(context)
                      .devicePixelRatio)
                      .round(),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[900],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[900],
                      child: const Icon(Icons.music_note, size: 100, color: Colors.white54),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TrackInfo extends StatelessWidget {
  final Track track;

  const _TrackInfo({required this.track});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  track.artistId,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme
                        .of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withAlpha((0.7 * 255).toInt()),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.queue_music), iconSize: 24, onPressed: () =>
                  showModalBottomSheet(
                      context: context,
                      useRootNavigator: true,
                      enableDrag: true,
                      builder: (context) => QueueBottomSheet()
                  )),
              IconButton(
                icon: Icon(
                  track.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: track.isFavorite ? const Color(0xFFF64A55) : null,
                ),
                iconSize: 24,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends ConsumerWidget {
  final bool isUserSeeking;
  final double sliderProgress;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  const _ProgressBar({
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
    final progress = ref
        .watch(progressProvider)
        .value;

    if (progress == null) return const SizedBox.shrink();

    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: Theme
                .of(context)
                .textTheme
                .bodyLarge
                ?.color,
            inactiveTrackColor: Theme
                .of(context)
                .textTheme
                .bodyLarge
                ?.color
                ?.withAlpha((0.2 * 255).toInt()),
            thumbColor: Theme
                .of(context)
                .textTheme
                .bodyLarge
                ?.color,
          ),
          child: Slider(
            value: isUserSeeking ? sliderProgress : progress.position.inMilliseconds.toDouble(),
            max: (progress.duration?.inMilliseconds ?? 1).toDouble(),

            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(progress.position),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme
                      .of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withAlpha((0.7 * 255).toInt()),
                ),
              ),
              Text(
                _formatDuration(progress.duration ?? Duration.zero),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme
                      .of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withAlpha((0.7 * 255).toInt()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlaybackControls extends ConsumerWidget {
  const _PlaybackControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref
        .watch(isPlayingProvider)
        .value ?? false;
    final isBuffering = ref
        .watch(isBufferingProvider)
        .value ?? false;
    final playerController = ref.watch(playerControllerProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(icon: const Icon(Icons.skip_previous), iconSize: 40, onPressed: () => playerController.skipPrev()),
        const SizedBox(width: 18),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(color: Theme
              .of(context)
              .textTheme
              .bodyLarge
              ?.color, shape: BoxShape.circle),
          child: isBuffering
              ? const Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : IconButton(
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Theme
                  .of(context)
                  .scaffoldBackgroundColor,
            ),
            iconSize: 40,
            onPressed: () {
              if (isPlaying) {
                playerController.pause();
              } else {
                playerController.play();
              }
            },
          ),
        ),
        const SizedBox(width: 18),
        IconButton(icon: const Icon(Icons.skip_next), iconSize: 40, onPressed: () => playerController.skipNext()),
      ],
    );
  }
}
