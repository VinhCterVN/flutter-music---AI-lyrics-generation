import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../../provider/audio_provider.dart';
import '../element/artist_card.dart';
import '../element/button/large_lyrics_button.dart';
import 'playing_screen/album_artwork.dart';
import 'playing_screen/playback_controls.dart';
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
  bool _floatingShow = false;
  double _sliderProgress = 0.0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)
      ..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.fastOutSlowIn));
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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

        return Scaffold(
          body: Stack(
            children: [
              _buildBackgroundImage(currentTrack.images.first),
              _buildBlurOverlay(),
              _buildGradientOverlay(),
              _buildMainContent(currentTrack, screenHeight),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: 12,
                right: 12,
                bottom: _floatingShow ? 16 : -100,
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

  Widget _buildBackgroundImage(String imageUrl) {
    return Positioned.fill(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: SizedBox.expand(
          key: ValueKey(imageUrl),
          child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildBlurOverlay() {
    return Positioned.fill(
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
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withAlpha(255)],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(dynamic currentTrack, double screenHeight) {
    return Positioned.fill(
      child: CustomScrollView(
        controller: widget.scrollController,
        slivers: <Widget>[
          // App Bar
          SliverAppBar(
            toolbarHeight: kToolbarHeight + 10,
            leading: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.keyboard_arrow_down)),
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
          // Player Content
          SliverToBoxAdapter(
            child: Container(
              height: screenHeight,
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AlbumArtwork(imageUrl: currentTrack.images.first, pulseAnimation: _pulseAnimation),
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
                  PlaybackControls(
                    onVisibilityChanged: (info) {
                      if (!mounted) return;
                      setState(() => _floatingShow = info);
                    },
                  ),
                ],
              ),
            ),
          ),
          // Artist Card
          SliverToBoxAdapter(
            child: ArtistCard(borderRadius: BorderRadius.circular(20), imageBorderRadius: BorderRadius.circular(12)),
          ),
          // Lyrics Button
          SliverToBoxAdapter(
            child: Container(margin: const EdgeInsets.fromLTRB(16, 0, 16, 120), child: LargeLyricsButton()),
          ),
        ],
      ),
    );
  }
}
