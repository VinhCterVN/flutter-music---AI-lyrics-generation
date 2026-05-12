import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/ui/component/element/playing_gradient_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../../provider/audio_provider.dart';
import '../element/artist_card.dart';
import '../element/button/large_lyrics_button.dart';
import 'playing_screen/album_artwork.dart';
import 'playing_screen/audio_waveform_section.dart';
import 'playing_screen/playback_controls.dart';
import 'playing_screen/playing_app_bar.dart';
import 'playing_screen/progress_bar.dart';
import 'playing_screen/sticky_mini_player.dart';
import 'playing_screen/track_info.dart';

class PlayingScreen extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const PlayingScreen({super.key, required this.scrollController});

  @override
  ConsumerState<PlayingScreen> createState() => _PlayingScreenState();
}

class _PlayingScreenState extends ConsumerState<PlayingScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  bool _isUserSeeking = false;
  final ValueNotifier<bool> _floatingShow = ValueNotifier(false);
  final GlobalKey _scrollViewportKey = GlobalKey();
  final GlobalKey _playbackControlsKey = GlobalKey();
  double _sliderProgress = 0.0;
  double? _miniPlayerRevealOffset;
  bool _visibilitySyncScheduled = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..value = 1.0;

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.fastOutSlowIn));

    ref.listenManual<AsyncValue<bool>>(isPlayingProvider, (_, next) {
      final isPlaying = next.value ?? false;
      if (isPlaying) {
        if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
      } else {
        _pulseController..stop()..value = 1.0;
      }
    }, fireImmediately: true);
    widget.scrollController.addListener(_handleScrollChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleMiniPlayerVisibilitySync());
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(covariant PlayingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController == widget.scrollController) return;
    oldWidget.scrollController.removeListener(_handleScrollChanged);
    widget.scrollController.addListener(_handleScrollChanged);
    _miniPlayerRevealOffset = null;
    _scheduleMiniPlayerVisibilitySync();
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_handleScrollChanged);
    _floatingShow.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleScrollChanged() => _updateMiniPlayerVisibility();

  void _scheduleMiniPlayerVisibilitySync() {
    if (!mounted || _visibilitySyncScheduled) return;
    _visibilitySyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilitySyncScheduled = false;
      if (!mounted) return;
      _syncMiniPlayerRevealOffset();
      _updateMiniPlayerVisibility();
    });
  }

  void _syncMiniPlayerRevealOffset() {
    if (!widget.scrollController.hasClients) return;

    final viewportBox = _scrollViewportKey.currentContext?.findRenderObject() as RenderBox?;
    final controlsBox = _playbackControlsKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewportBox == null || controlsBox == null || !viewportBox.hasSize || !controlsBox.hasSize) return;

    final controlsTop = controlsBox.localToGlobal(Offset.zero, ancestor: viewportBox).dy;
    final controlsBottom = controlsTop + controlsBox.size.height;
    _miniPlayerRevealOffset = widget.scrollController.offset + controlsBottom;
  }

  void _updateMiniPlayerVisibility() {
    if (!mounted || !widget.scrollController.hasClients || _miniPlayerRevealOffset == null) {
      if (_floatingShow.value) _floatingShow.value = false;
      return;
    }
    final shouldShow = widget.scrollController.offset >= _miniPlayerRevealOffset!;
    if (_floatingShow.value != shouldShow) {
      _floatingShow.value = shouldShow;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currentTrackAsync = ref.watch(currentTrackProvider);

    final padding = MediaQuery.of(context).padding;
    final screenHeight = MediaQuery.of(context).size.height - padding.top - padding.bottom - 100;

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
        _scheduleMiniPlayerVisibilitySync();
        return Scaffold(
          body: Stack(
            children: [
              const PlayingGradientColor(),
              _buildMainContent(currentTrack, screenHeight),
              ValueListenableBuilder<bool>(
                valueListenable: _floatingShow,
                builder: (context, show, child) => AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  left: 12,
                  right: 12,
                  bottom: show ? 16 : -100,
                  child: child!,
                ),
                child: StickyMiniPlayer(track: currentTrack),
              ),
            ],
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

  Widget _buildMainContent(Track currentTrack, double screenHeight) {
    return Positioned.fill(
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: (notification) {
          _scheduleMiniPlayerVisibilitySync();
          return false;
        },
        child: SizedBox.expand(
          key: _scrollViewportKey,
          child: CustomScrollView(
            controller: widget.scrollController,
            cacheExtent: 3000.0,
            slivers: <Widget>[
              // App Bar
              PlayingAppBar(track: currentTrack),
              // Player Content
              SliverToBoxAdapter(
                child: Container(
                  height: screenHeight,
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AlbumArtwork(imageUrl: currentTrack.images.firstOrNull, pulseAnimation: _pulseAnimation),
                      const SizedBox(height: 50),
                      TrackInfo(track: currentTrack),
                      const SizedBox(height: 16),
                      ProgressBar(
                        isUserSeeking: _isUserSeeking,
                        sliderProgress: _sliderProgress,
                        onChanged: (value) => setState(() {
                          _sliderProgress = value;
                          _isUserSeeking = true;
                        }),
                        onChangeEnd: (value) async {
                          setState(() => _isUserSeeking = false);
                          await ref.read(audioPlayerProvider).seek(Duration(milliseconds: value.toInt()));
                        },
                      ),
                      const SizedBox(height: 8),
                      PlaybackControls(key: _playbackControlsKey),
                    ],
                  ),
                ),
              ),
              // Artist Card
              SliverToBoxAdapter(
                child: ArtistCard(
                  borderRadius: BorderRadius.circular(20),
                  imageBorderRadius: BorderRadius.circular(12),
                ),
              ),
              SliverToBoxAdapter(child: AudioWaveformSection(track: currentTrack)),
              // Lyrics Button
              SliverToBoxAdapter(
                child: Container(margin: const EdgeInsets.fromLTRB(16, 0, 16, 120), child: const LargeLyricsButton()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
