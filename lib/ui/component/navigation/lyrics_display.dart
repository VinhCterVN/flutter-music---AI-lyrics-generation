import 'dart:developer';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../../data/models/lyric_line.dart';
import '../../../data/models/track.dart';
import '../../../provider/audio_provider.dart';
import '../../../provider/lyrics_provider.dart';
import '../../../service/lyrics_service.dart';

class LyricsDisplayWidget extends ConsumerStatefulWidget {
  final Track track;
  final Color backgroundColor;

  const LyricsDisplayWidget({super.key, required this.track, this.backgroundColor = const Color(0xFFD4837D)});

  @override
  ConsumerState<LyricsDisplayWidget> createState() => _LyricsDisplayWidgetState();
}

class _LyricsDisplayWidgetState extends ConsumerState<LyricsDisplayWidget> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _lineKeys = {};
  int _currentLineIndex = -1;
  bool isFetchCalled = false;
  List<LyricsLine>? _cachedLyrics;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lyricsAsync = ref.watch(lyricsStreamProvider(widget.track.id));
    final progressAsync = ref.watch(progressProvider);
    final lyricService = ref.read(lyricsServiceProvider);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CachedNetworkImage(imageUrl: widget.track.images.first, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaY: 15, sigmaX: 15),
              child: Container(color: Colors.black.withAlpha(55)),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withAlpha(45), Colors.black.withAlpha(55)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: lyricsAsync.when(
              data: (lyrics) {
                if (_cachedLyrics == null || _cachedLyrics!.length != lyrics.length) {
                  _cachedLyrics = lyrics;
                  _initializeLineKeys(lyrics.length);
                }

                if (lyrics.isEmpty && !isFetchCalled) {
                  lyricService.getLyrics(widget.track.id);
                  setState(() => isFetchCalled = true);
                  log("Fetch Lyrics Called");
                }

                return progressAsync.when(
                  data: (progress) {
                    final currentPosition = progress.position;
                    _updateCurrentLineFromPosition(currentPosition, lyrics);
                    return _buildContent(lyrics, currentPosition, progress);
                  },
                  loading: () => _buildLoadingState(),
                  error: (error, stack) => _buildErrorState('Error loading progress'),
                );
              },
              loading: () => _buildLoadingState(),
              error: (error, stack) {
                if (error is LyricsNotFoundException) {
                  return _buildGeneratingState();
                }
                return _buildErrorState('Error loading lyrics: ${error.toString()}');
              },
            ),
          ),
        ],
      ),
    );
  }

  void _initializeLineKeys(int count) {
    _lineKeys.clear();
    for (int i = 0; i < count; i++) {
      _lineKeys[i] = GlobalKey();
    }
  }

  void _updateCurrentLineFromPosition(Duration position, List<LyricsLine> lyrics) {
    for (int i = 0; i < lyrics.length; i++) {
      final line = lyrics[i];
      if (position >= line.startTime && position < line.endTime) {
        if (_currentLineIndex != i) {
          setState(() {
            _currentLineIndex = i;
          });
          _scrollToCurrentLine(i);
        }
        break;
      }
    }
  }

  void _scrollToCurrentLine(int index) {
    if (!_scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _lineKeys[index];
      if (key?.currentContext == null) return;

      final RenderBox? renderBox = key!.currentContext!.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final position = renderBox.localToGlobal(Offset.zero);
      final viewportHeight = _scrollController.position.viewportDimension;
      final currentScrollOffset = _scrollController.offset;
      final itemOffset = currentScrollOffset + position.dy;
      final targetOffset = itemOffset - (viewportHeight / 2) - 50;

      _scrollController.animateTo(
        targetOffset.clamp(_scrollController.position.minScrollExtent, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  Widget _buildContent(List<LyricsLine> lyrics, Duration currentPosition, TrackProgress progress) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: lyrics.isEmpty
              ? Center(
                  child: Column(
                    children: [
                      Lottie.asset("assets/animations/impress.json", repeat: false),
                      Text("Lyrics is being created, wait a minutes..."),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                  itemCount: lyrics.length,
                  itemBuilder: (context, index) {
                    final line = lyrics[index];
                    final isActive = index == _currentLineIndex;

                    return Padding(
                      key: _lineKeys[index],
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.black.withAlpha((0.5 * 255).round()),
                          fontSize: isActive ? 32 : 24,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          height: 1.3,
                        ),
                        child: Text(line.text, textAlign: TextAlign.left),
                      ),
                    );
                  },
                ),
        ),
        _buildBottomControls(currentPosition, progress),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 8),
          Text(
            widget.track.name,
            style: const TextStyle(
              fontFamily: "SpotifyMixUI",
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              shadows: [Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 3)],
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            widget.track.artistType.name,
            style: TextStyle(
              color: Colors.white.withAlpha((0.8 * 255).round()),
              fontSize: 14,
              shadows: const [Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 3)],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        _buildHeader(),
        const Expanded(
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildGeneratingState() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 20),
                Text(
                  'Generating lyrics...',
                  style: TextStyle(color: Colors.white.withAlpha((0.8 * 255).round()), fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'This may take a moment',
                  style: TextStyle(color: Colors.white.withAlpha((0.6 * 255).round()), fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Center(
            child: Text(
              'No lyrics available',
              style: TextStyle(color: Colors.white.withAlpha((0.8 * 255).round()), fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.white.withAlpha((0.8 * 255).round()), size: 48),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: TextStyle(color: Colors.white.withAlpha((0.8 * 255).round()), fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls(Duration currentPosition, TrackProgress progress) {
    final duration = progress.duration ?? Duration.zero;
    final position = progress.position;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withAlpha((0.3 * 255).round()),
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: duration.inMilliseconds > 0
                  ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                  : 0.0,
              onChanged: (value) {
                final newPosition = Duration(milliseconds: (value * duration.inMilliseconds).toInt());
                ref.read(audioPlayerProvider).seek(newPosition);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: TextStyle(color: Colors.white.withAlpha((0.7 * 255).round()), fontSize: 12),
                ),
                Text(
                  _formatDuration(duration),
                  style: TextStyle(color: Colors.white.withAlpha((0.7 * 255).round()), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              final player = ref.read(audioPlayerProvider);
              if (player.playing) {
                player.pause();
              } else {
                player.play();
              }
            },
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(
                ref.watch(audioPlayerProvider).playing ? Icons.pause : Icons.play_arrow,
                size: 40,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
