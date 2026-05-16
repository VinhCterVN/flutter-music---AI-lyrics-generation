import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_ai_music/ui/layout/animated_ambient_color_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../../data/models/lyric_line.dart';
import '../../../data/models/track.dart';
import '../../../provider/audio_provider.dart';
import '../../../provider/lyrics_provider.dart';

class LyricsDisplayWidget extends ConsumerStatefulWidget {
  final Track track;

  const LyricsDisplayWidget({super.key, required this.track});

  static const double activeLyricFontSize = 24;
  static const double inactiveLyricFontSize = 20;
  static const TextStyle lyricTextStyle = TextStyle(
    fontFamily: "SpotifyMixUI",
    fontWeight: FontWeight.bold,
    letterSpacing: -0.25,
    height: 1.3,
  );

  @override
  ConsumerState<LyricsDisplayWidget> createState() => _LyricsDisplayWidgetState();
}

class _LyricsDisplayWidgetState extends ConsumerState<LyricsDisplayWidget> {
  static const double _lyricHorizontalPadding = 20;
  static const double _activeLyricFontSize = 24;

  // static const double _inactiveLyricFontSize = 20;
  // static const Duration _lyricAnimationDuration = Duration(milliseconds: 500);

  // static const double _inactiveLyricWidthFactor = _inactiveLyricFontSize / _activeLyricFontSize;
  static const TextStyle _lyricTextStyle = TextStyle(
    fontFamily: "SpotifyMixUI",
    fontWeight: FontWeight.bold,
    letterSpacing: -0.25,
    height: 1.3,
  );

  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _lineKeys = {};
  final Map<String, String> _wrappedTextCache = {};
  final ValueNotifier<int> _currentLineIndexNotifier = ValueNotifier<int>(-1);
  int _currentLineIndex = -1;
  bool _isFetchCalled = false;
  List<LyricsLine>? _cachedLyrics;
  int? _activeTrackId;

  @override
  void dispose() {
    _currentLineIndexNotifier.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTrackAsync = ref.watch(currentTrackProvider);
    final lyricService = ref.read(lyricsServiceProvider);

    return currentTrackAsync.when(
      data: (currentTrack) {
        final track = currentTrack ?? widget.track;
        _syncTrackState(track.id);
        final lyricsAsync = ref.watch(lyricsStreamProvider(track.id));

        return Scaffold(
          body: Stack(
            children: [
              const _LyricsAmbientGradientBackground(),
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

                    return _LyricsProgressListener(
                      lyrics: lyrics,
                      onProgress: _updateCurrentLineFromPosition,
                      child: _buildContent(track, lyrics),
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
    _currentLineIndexNotifier.value = -1;
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
    if (!mounted) return;
    final nextIndex = _findCurrentLineIndex(position, lyrics);
    if (nextIndex == _currentLineIndex) return;

    _currentLineIndex = nextIndex;
    _currentLineIndexNotifier.value = nextIndex;
    if (nextIndex >= 0) {
      _scrollToCurrentLine(nextIndex);
    }
  }

  int _findCurrentLineIndex(Duration position, List<LyricsLine> lyrics) {
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
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  Widget _buildContent(Track track, List<LyricsLine> lyrics) {
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
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final lyricMaxWidth = constraints.maxWidth - (_lyricHorizontalPadding * 2);

                    return ShaderMask(
                      blendMode: BlendMode.dstOut,
                      shaderCallback: (bounds) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black, Colors.transparent, Colors.transparent, Colors.black],
                        stops: [0.0, 0.08, 0.92, 1.0],
                      ).createShader(bounds),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: _lyricHorizontalPadding, vertical: 40),
                        cacheExtent: constraints.maxHeight * 1.5,
                        addAutomaticKeepAlives: false,
                        itemCount: lyrics.length,
                        itemBuilder: (context, index) {
                          final line = lyrics[index];
                          final wrappedText = _getWrappedText(
                            context: context,
                            text: line.text,
                            maxWidth: lyricMaxWidth,
                          );

                          return _LyricLineItem(
                            lineKey: _lineKeys[index]!,
                            text: wrappedText,
                            activeIndexNotifier: _currentLineIndexNotifier,
                            index: index,
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
        const _LyricsBottomControls(),
      ],
    );
  }

  String _getWrappedText({required BuildContext context, required String text, required double maxWidth}) {
    if (text.isEmpty) return text;

    final activeStyle = _lyricTextStyle.copyWith(fontSize: _activeLyricFontSize);
    final textDirection = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final scaledActiveFontSize = textScaler.scale(_activeLyricFontSize);
    final cacheKey = '${maxWidth.toStringAsFixed(2)}|$scaledActiveFontSize|$textDirection|$text';
    final cached = _wrappedTextCache[cacheKey];
    if (cached != null) return cached;

    bool fitsActiveLine(String value) {
      final textPainter = TextPainter(
        text: TextSpan(text: value, style: activeStyle),
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: 1,
      )..layout(maxWidth: double.infinity);

      return textPainter.width <= maxWidth;
    }

    if (fitsActiveLine(text)) {
      _wrappedTextCache[cacheKey] = text;
      return text;
    }

    final wrappedLines = <String>[];
    final words = text.split(RegExp(r'\s+'));
    var currentLine = '';

    for (final word in words) {
      if (word.isEmpty) continue;
      final candidate = currentLine.isEmpty ? word : '$currentLine $word';

      if (fitsActiveLine(candidate) || currentLine.isEmpty) {
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
      child: Stack(
        fit: StackFit.loose,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    track.name,
                    style: const TextStyle(
                      fontFamily: "SpotifyMixUI",
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 3)],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    track.artistName ?? track.artistType.name,
                    style: TextStyle(
                      fontFamily: "SpotifyMixUI",
                      letterSpacing: (-0.2),
                      color: Colors.white.withAlpha((0.8 * 255).round()),
                      fontSize: 14,
                      shadows: const [Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 3)],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
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
}

String _formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return '$minutes:$seconds';
}

class _LyricLineItem extends StatefulWidget {
  const _LyricLineItem({
    required this.lineKey,
    required this.text,
    required this.activeIndexNotifier,
    required this.index,
  });

  final GlobalKey lineKey;
  final String text;
  final ValueNotifier<int> activeIndexNotifier;
  final int index;

  @override
  State<_LyricLineItem> createState() => _LyricLineItemState();
}

class _LyricLineItemState extends State<_LyricLineItem> {
  static const Duration _duration = Duration(milliseconds: 500);
  static const double _inactiveScale =
      LyricsDisplayWidget.inactiveLyricFontSize / LyricsDisplayWidget.activeLyricFontSize;

  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _isActive = widget.activeIndexNotifier.value == widget.index;
    widget.activeIndexNotifier.addListener(_onActiveIndexChanged);
  }

  @override
  void didUpdateWidget(_LyricLineItem old) {
    super.didUpdateWidget(old);
    if (old.activeIndexNotifier != widget.activeIndexNotifier) {
      old.activeIndexNotifier.removeListener(_onActiveIndexChanged);
      widget.activeIndexNotifier.addListener(_onActiveIndexChanged);
    }
  }

  @override
  void dispose() {
    widget.activeIndexNotifier.removeListener(_onActiveIndexChanged);
    super.dispose();
  }

  void _onActiveIndexChanged() {
    final shouldBeActive = widget.activeIndexNotifier.value == widget.index;
    if (shouldBeActive != _isActive) {
      setState(() => _isActive = shouldBeActive);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedPadding(
        key: widget.lineKey,
        duration: _duration,
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(vertical: _isActive ? 16 : 2),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedScale(
            scale: _isActive ? 1.0 : _inactiveScale,
            alignment: Alignment.centerLeft,
            duration: _duration,
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              opacity: _isActive ? 1.0 : 0.5,
              duration: _duration,
              curve: Curves.easeInOut,
              child: Text(
                widget.text,
                style: LyricsDisplayWidget.lyricTextStyle.copyWith(
                  fontSize: LyricsDisplayWidget.activeLyricFontSize,
                  color: Colors.white,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LyricsProgressListener extends ConsumerWidget {
  final List<LyricsLine> lyrics;
  final void Function(Duration position, List<LyricsLine> lyrics) onProgress;
  final Widget child;

  const _LyricsProgressListener({required this.lyrics, required this.onProgress, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<TrackProgress>>(progressProvider, (_, next) {
      next.whenData((progress) {
        onProgress(progress.position, lyrics);
      });
    });

    final progress = ref.read(progressProvider).value;
    if (progress != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onProgress(progress.position, lyrics);
      });
    }

    return child;
  }
}

class _LyricsBottomControls extends ConsumerWidget {
  const _LyricsBottomControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider).value;
    final isPlaying = ref.watch(isPlayingProvider).value ?? false;
    final duration = progress?.duration ?? Duration.zero;
    final position = progress?.position ?? Duration.zero;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
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
          const SizedBox(height: 4),
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
              child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 40, color: Colors.black),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _LyricsAmbientGradientBackground extends StatelessWidget {
  const _LyricsAmbientGradientBackground();

  @override
  Widget build(BuildContext context) {
    return AnimatedAmbientColorBuilder(
      builder: (color) {
        final topColor = Color.lerp(color, Colors.black, 0.35)!;
        final bottomColor = Color.lerp(color, Colors.black, 0.25)!;

        return Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [topColor, bottomColor],
              ),
            ),
          ),
        );
      },
    );
  }
}
