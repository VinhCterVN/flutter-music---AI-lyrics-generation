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

class LyricsDisplayWidget extends ConsumerStatefulWidget {
  final Track track;

  const LyricsDisplayWidget({super.key, required this.track});

  @override
  ConsumerState<LyricsDisplayWidget> createState() => _LyricsDisplayWidgetState();
}

class _LyricsDisplayWidgetState extends ConsumerState<LyricsDisplayWidget> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _lineKeys = {};
  final Map<String, String> _wrappedTextCache = {};
  int _currentLineIndex = -1;
  bool _isFetchCalled = false;
  List<LyricsLine>? _cachedLyrics;
  int? _activeTrackId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTrackAsync = ref.watch(currentTrackProvider);
    final progressAsync = ref.watch(progressProvider);
    final lyricService = ref.read(lyricsServiceProvider);

    return currentTrackAsync.when(
      data: (currentTrack) {
        final track = currentTrack ?? widget.track;
        _syncTrackState(track.id);
        final lyricsAsync = ref.watch(lyricsStreamProvider(track.id));

        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(imageUrl: track.images.first, fit: BoxFit.cover),
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

                    if (lyrics.isEmpty && !_isFetchCalled) {
                      _isFetchCalled = true;
                      Future.microtask(() async {
                        final fetchedLyrics = await lyricService.getLyrics(track);
                        if (!mounted) return;
                        if (fetchedLyrics.isEmpty) {
                          log('No synced lyrics found for track ${track.id}');
                        }
                      });
                    }

                    return progressAsync.when(
                      data: (progress) {
                        final currentPosition = progress.position;
                        _updateCurrentLineFromPosition(currentPosition, lyrics);
                        return _buildContent(track, lyrics, currentPosition, progress);
                      },
                      loading: () => _buildLoadingState(track),
                      error: (error, stack) => _buildErrorState(track, 'Error loading progress'),
                    );
                  },
                  loading: () => _buildLoadingState(track),
                  error: (error, stack) => _buildErrorState(track, 'Error loading lyrics: ${error.toString()}'),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(body: _buildLoadingState(widget.track)),
      error: (error, stack) => Scaffold(body: _buildErrorState(widget.track, 'Error loading current track')),
    );
  }

  void _syncTrackState(int trackId) {
    if (_activeTrackId == trackId) return;
    _activeTrackId = trackId;
    _currentLineIndex = -1;
    _isFetchCalled = false;
    _cachedLyrics = null;
    _lineKeys.clear();
    _wrappedTextCache.clear();
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.minScrollExtent);
        }
      });
    }
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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  Widget _buildContent(Track track, List<LyricsLine> lyrics, Duration currentPosition, TrackProgress progress) {
    return Column(
      children: [
        _buildHeader(track),
        Expanded(
          child: lyrics.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset("assets/animations/impress.json", repeat: false),
                      const SizedBox(height: 8),
                      const Text("No synced lyrics available yet."),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  itemCount: lyrics.length,
                  itemBuilder: (context, index) {
                    final line = lyrics[index];
                    final isActive = index == _currentLineIndex;
                    final wrappedText = _getWrappedText(
                      context: context,
                      text: line.text,
                      maxWidth: MediaQuery.of(context).size.width - 40,
                    );

                    return Padding(
                      key: _lineKeys[index],
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          fontFamily: "SpotifyMixUI",
                          color: isActive ? Colors.white : Colors.white54.withAlpha((0.5 * 255).round()),
                          fontSize: isActive ? 28 : 20,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                          height: 1.3,
                        ),
                        child: Text(wrappedText, textAlign: TextAlign.left),
                      ),
                    );
                  },
                ),
        ),
        _buildBottomControls(currentPosition, progress),
      ],
    );
  }

  String _getWrappedText({
    required BuildContext context,
    required String text,
    required double maxWidth,
  }) {
    if (text.isEmpty) return text;

    final cacheKey = '${maxWidth.toStringAsFixed(2)}|$text';
    final cached = _wrappedTextCache[cacheKey];
    if (cached != null) return cached;

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontFamily: 'SpotifyMixUI',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
      ),
      textDirection: Directionality.of(context),
    )..layout(maxWidth: maxWidth);

    if (textPainter.width <= maxWidth) {
      _wrappedTextCache[cacheKey] = text;
      return text;
    }

    final wrappedLines = <String>[];
    final words = text.split(RegExp(r'\s+'));
    var currentLine = '';

    for (final word in words) {
      if (word.isEmpty) continue;
      final candidate = currentLine.isEmpty ? word : '$currentLine $word';
      final candidatePainter = TextPainter(
        text: TextSpan(
          text: candidate,
          style: const TextStyle(
            fontFamily: 'SpotifyMixUI',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),
        textDirection: Directionality.of(context),
      )..layout(maxWidth: maxWidth);

      if (candidatePainter.width <= maxWidth || currentLine.isEmpty) {
        currentLine = candidate;
      } else {
        wrappedLines.add(currentLine);
        currentLine = word;
      }
    }

    if (currentLine.isNotEmpty) {
      wrappedLines.add(currentLine);
    }

    final wrappedText = wrappedLines.join('\n');
    _wrappedTextCache[cacheKey] = wrappedText;
    return wrappedText;
  }

  Widget _buildHeader(Track track) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Text(
                track.name,
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
                track.artistName ?? track.artistType.name,
                style: TextStyle(
                  color: Colors.white.withAlpha((0.8 * 255).round()),
                  fontSize: 14,
                  shadows: const [Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 3)],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(Track track) {
    return Column(
      children: [
        _buildHeader(track),
        const Expanded(
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildErrorState(Track track, String message) {
    return Column(
      children: [
        _buildHeader(track),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
          const SizedBox(height: 6),
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                ref.watch(audioPlayerProvider).playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 40,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 20)
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
