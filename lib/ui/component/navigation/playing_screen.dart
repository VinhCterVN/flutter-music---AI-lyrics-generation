import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/provider/artist_provider.dart';
import 'package:flutter_ai_music/provider/uistate_provider.dart';
import 'package:flutter_ai_music/ui/component/navigation/lyrics_display.dart';
import 'package:flutter_ai_music/ui/component/navigation/queue_bottom_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';

import '../../../data/models/track.dart';
import '../../../provider/audio_provider.dart';
import '../element/artist_card.dart';

class PlayingScreen extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const PlayingScreen({super.key, required this.scrollController});

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
    final currentTrackAsync = ref.watch(currentTrackProvider);

    final padding = MediaQuery.of(context).padding;
    final screenHeight = MediaQuery.of(context).size.height - padding.top - padding.bottom - 100;
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

              return Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: SizedBox.expand(
                        key: ValueKey(currentTrack.images.first),
                        child: CachedNetworkImage(imageUrl: currentTrack.images.first, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: ListenableBuilder(
                      listenable: widget.scrollController,
                      builder: (context, child) {
                        final offset = widget.scrollController.hasClients ? widget.scrollController.offset : 0.0;
                        final blurAmount = (5 + (offset / 300 * 20)).clamp(5.0, 30.0);
                        return BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
                          child: Container(color: Colors.black.withAlpha(55)),
                        );
                      },
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withAlpha(200)],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomScrollView(
                      controller: widget.scrollController,
                      slivers: <Widget>[
                        SliverAppBar(
                          toolbarHeight: kToolbarHeight + 10,
                          leading: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.keyboard_arrow_down),
                            ),
                          ),
                          actions: [
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert_rounded)),
                            ),
                          ],
                          flexibleSpace: FlexibleSpaceBar(
                            title: const Text(
                              'Playing View',
                              style: TextStyle(
                                fontSize: 22,
                                fontFamily: "SpotifyMixUI",
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            centerTitle: true,
                          ),
                          backgroundColor: Colors.transparent,
                        ),

                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: screenHeight,
                            child: Column(
                              children: [
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
                                            setState(() => _isUserSeeking = false);
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
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                            child: ElevatedButton(
                              onPressed: () async {
                                if (!context.mounted) return;
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        LyricsDisplayWidget(track: currentTrack, backgroundColor: animatedColor),
                                  ),
                                );
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
                ],
              );
            },
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
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

class _AlbumArtwork extends ConsumerWidget {
  final String imageUrl;
  final Color ambientColor;
  final Animation<double> pulseAnimation;

  const _AlbumArtwork({required this.imageUrl, required this.ambientColor, required this.pulseAnimation});

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
                boxShadow: [BoxShadow(color: ambientColor.withAlpha(85), blurRadius: 30, spreadRadius: 5)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Hero(
                  tag: "now-playing-track-$imageUrl",
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
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

class _TrackInfo extends ConsumerWidget {
  final Track track;

  const _TrackInfo({required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentArtist = ref.watch(currentArtistProvider).value;
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
                  style: const TextStyle(fontFamily: "SpotifyMixUI", fontSize: 21, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  currentArtist?.name ?? 'Unknown Artist',
                  style: TextStyle(
                    fontFamily: "SpotifyMixUI",
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha((0.7 * 255).toInt()),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.queue_music_rounded),
                iconSize: 24,
                onPressed: () => showModalBottomSheet(
                  context: context,
                  useRootNavigator: true,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
                  enableDrag: true,
                  showDragHandle: true,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  isDismissible: true,
                  builder: (context) => QueueBottomSheet(),
                ),
              ),
              IconButton(
                icon: track.isFavorite
                    ? FaIcon(FontAwesomeIcons.solidHeart, size: 20)
                    : HugeIcon(icon: HugeIcons.strokeRoundedHeartAdd, size: 22),
                color: track.isFavorite
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).textTheme.bodyLarge?.color,
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
    final progress = ref.watch(progressProvider).value;

    if (progress == null) return const SizedBox.shrink();

    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: isUserSeeking ? 3 : 5, end: isUserSeeking ? 5 : 3),
          duration: const Duration(milliseconds: 250),
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

class _PlaybackControls extends ConsumerWidget {
  const _PlaybackControls();

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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: HugeIcon(
            icon: HugeIconsStrokeRounded.shuffle,
            strokeWidth: isShuffleOn ? 3.0 : 1.5,
            color: isShuffleOn ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
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
                  child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(variant)),
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
    );
  }
}
