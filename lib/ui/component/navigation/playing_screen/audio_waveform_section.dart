import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/audio_provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AudioWaveformSection extends ConsumerStatefulWidget {
  final Track track;

  const AudioWaveformSection({super.key, required this.track});

  @override
  ConsumerState<AudioWaveformSection> createState() =>
      _AudioWaveformSectionState();
}

class _AudioWaveformSectionState extends ConsumerState<AudioWaveformSection> {
  static const double _pixelsPerSecond = 18;

  final ScrollController _scrollController = ScrollController();

  StreamSubscription<WaveformProgress>? _waveformSubscription;
  Waveform? _waveform;
  double _extractionProgress = 0;
  Object? _error;
  bool _isUserScrolling = false;
  bool _isSyncingScroll = false;
  Duration? _previewPosition;
  int _loadToken = 0;
  int _scrollSyncToken = 0;

  @override
  void initState() {
    super.initState();
    _loadWaveform();
  }

  @override
  void didUpdateWidget(covariant AudioWaveformSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track.id == widget.track.id &&
        oldWidget.track.uri == widget.track.uri) {
      return;
    }
    _loadWaveform();
  }

  @override
  void dispose() {
    _waveformSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadWaveform() async {
    final token = ++_loadToken;
    await _waveformSubscription?.cancel();
    _waveformSubscription = null;

    if (!mounted) {
      return;
    }
    setState(() {
      _waveform = null;
      _error = null;
      _extractionProgress = 0;
      _previewPosition = null;
    });

    try {
      final audioFile = await _resolveAudioFile(widget.track);
      final waveFile = await _waveFileFor(widget.track);

      if (await waveFile.exists() && await waveFile.length() > 0) {
        try {
          final waveform = await JustWaveform.parse(waveFile);
          if (!mounted || token != _loadToken) {
            return;
          }
          setState(() {
            _waveform = waveform;
            _extractionProgress = 1;
          });
          return;
        } catch (_) {
          await waveFile.delete();
        }
      }

      final stream = JustWaveform.extract(
        audioInFile: audioFile,
        waveOutFile: waveFile,
        zoom: const WaveformZoom.pixelsPerSecond(80),
      );
      _waveformSubscription = stream.listen(
        (progress) {
          if (!mounted || token != _loadToken) {
            return;
          }
          setState(() {
            _extractionProgress = progress.progress;
            _waveform = progress.waveform ?? _waveform;
          });
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!mounted || token != _loadToken) {
            return;
          }
          setState(() => _error = error);
        },
      );
    } catch (error) {
      if (!mounted || token != _loadToken) {
        return;
      }
      setState(() => _error = error);
    }
  }

  Future<File> _resolveAudioFile(Track track) async {
    final uri = Uri.tryParse(track.uri);
    if (uri == null || uri.scheme.isEmpty) {
      return File(track.uri);
    }

    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return DefaultCacheManager().getSingleFile(track.uri);
    }

    if (uri.scheme == 'file') {
      return File.fromUri(uri);
    }

    throw UnsupportedError(
      'Waveform extraction needs a downloadable or file-based audio source.',
    );
  }

  Future<File> _waveFileFor(Track track) async {
    final tempDir = await getTemporaryDirectory();
    final waveDir = Directory(p.join(tempDir.path, 'waveforms'));
    if (!await waveDir.exists()) {
      await waveDir.create(recursive: true);
    }
    final uriHash = track.uri.hashCode.abs();
    return File(p.join(waveDir.path, 'track_${track.id}_$uriHash.wave'));
  }

  void _syncScrollToPosition(Duration position, Duration duration) {
    if (_isUserScrolling ||
        !_scrollController.hasClients ||
        duration == Duration.zero) {
      return;
    }

    final target = _offsetForPosition(position, duration);
    final clampedTarget = target.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    final delta = (_scrollController.offset - clampedTarget).abs();
    if (delta < 1) {
      return;
    }

    final syncToken = ++_scrollSyncToken;
    _isSyncingScroll = true;

    if (delta > 1200) {
      _scrollController.jumpTo(clampedTarget);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && syncToken == _scrollSyncToken) {
          _isSyncingScroll = false;
        }
      });
      return;
    }

    unawaited(
      _scrollController
          .animateTo(
            clampedTarget,
            duration: const Duration(milliseconds: 260),
            curve: Curves.linear,
          )
          .whenComplete(() {
            if (mounted && syncToken == _scrollSyncToken) {
              _isSyncingScroll = false;
            }
          }),
    );
  }

  double _offsetForPosition(Duration position, Duration duration) {
    final seconds = position.inMilliseconds / Duration.millisecondsPerSecond;
    return seconds.clamp(
          0.0,
          duration.inMilliseconds / Duration.millisecondsPerSecond,
        ) *
        _pixelsPerSecond;
  }

  Duration _positionForOffset(double offset, Duration duration) {
    final milliseconds =
        (offset / _pixelsPerSecond * Duration.millisecondsPerSecond).round();
    return Duration(
      milliseconds: milliseconds.clamp(0, duration.inMilliseconds),
    );
  }

  Future<void> _seekToScrollPosition(Duration duration) async {
    if (!_scrollController.hasClients || duration == Duration.zero) {
      return;
    }
    final target = _positionForOffset(_scrollController.offset, duration);
    setState(() => _previewPosition = target);
    await ref.read(audioPlayerProvider).seek(target);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider).value;
    final duration = progress?.duration ?? _waveform?.duration ?? Duration.zero;
    final position = _previewPosition ?? progress?.position ?? Duration.zero;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncScrollToPosition(progress?.position ?? Duration.zero, duration);
      }
    });

    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final mutedTextColor = textColor.withAlpha((0.62 * 255).toInt());

    return Container(
      height: 178,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((0.28 * 255).toInt()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha((0.08 * 255).toInt())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Waveform',
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${_formatDuration(position)} / ${_formatDuration(duration)}',
                style: TextStyle(
                  color: mutedTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth = math.max(
                  constraints.maxWidth,
                  duration.inMilliseconds /
                      Duration.millisecondsPerSecond *
                      _pixelsPerSecond,
                );
                final sidePadding = constraints.maxWidth / 2;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (bounds) => const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Colors.white,
                          Colors.white,
                          Colors.transparent,
                        ],
                        stops: [0, 0.08, 0.92, 1],
                      ).createShader(bounds),
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (duration == Duration.zero) {
                            return false;
                          }

                          if (notification is ScrollStartNotification) {
                            if (notification.dragDetails == null) {
                              return false;
                            }
                            _scrollSyncToken++;
                            _isSyncingScroll = false;
                            setState(() => _isUserScrolling = true);
                          } else if (_isSyncingScroll) {
                            return false;
                          } else if (notification is ScrollUpdateNotification &&
                              _isUserScrolling) {
                            setState(() {
                              _previewPosition = _positionForOffset(
                                _scrollController.offset,
                                duration,
                              );
                            });
                          } else if (notification is ScrollEndNotification &&
                              _isUserScrolling) {
                            unawaited(
                              _seekToScrollPosition(duration).whenComplete(() {
                                if (mounted) {
                                  setState(() {
                                    _isUserScrolling = false;
                                    _previewPosition = null;
                                  });
                                }
                              }),
                            );
                          }
                          return false;
                        },
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          physics: duration == Duration.zero
                              ? const NeverScrollableScrollPhysics()
                              : const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics(),
                                ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: sidePadding,
                            ),
                            child: SizedBox(
                              width: contentWidth,
                              height: constraints.maxHeight,
                              child: CustomPaint(
                                painter: _WaveformPainter(
                                  waveform: _waveform,
                                  duration: duration,
                                  position: position,
                                  seed: widget.track.id,
                                  waveColor: Colors.white.withAlpha(
                                    (0.32 * 255).toInt(),
                                  ),
                                  playedColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withAlpha((0.92 * 255).toInt()),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: Container(
                        width: 3,
                        height: constraints.maxHeight - 10,
                        decoration: BoxDecoration(
                          color: textColor,
                          borderRadius: BorderRadius.circular(99),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(
                                (0.35 * 255).toInt(),
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_waveform == null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            minHeight: 2,
                            value: _error == null
                                ? _extractionProgress
                                      .clamp(0.02, 1.0)
                                      .toDouble()
                                : null,
                            backgroundColor: Colors.white.withAlpha(
                              (0.08 * 255).toInt(),
                            ),
                            color: _error == null
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white.withAlpha((0.24 * 255).toInt()),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final Waveform? waveform;
  final Duration duration;
  final Duration position;
  final int seed;
  final Color waveColor;
  final Color playedColor;

  _WaveformPainter({
    required this.waveform,
    required this.duration,
    required this.position,
    required this.seed,
    required this.waveColor,
    required this.playedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final inactivePaint = Paint()
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..color = waveColor;
    final activePaint = Paint()
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..color = playedColor;
    final activeX = duration == Duration.zero
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0) *
              size.width;

    const step = 7.0;
    for (var x = 0.0; x <= size.width; x += step) {
      final normalizedHeight = waveform == null
          ? _syntheticHeight(x)
          : _waveformHeight(x, size.width);
      final barHeight = math.max(8.0, normalizedHeight * size.height * 0.92);
      final centerY = size.height / 2;
      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        x <= activeX ? activePaint : inactivePaint,
      );
    }
  }

  double _waveformHeight(double x, double width) {
    final source = waveform;
    if (source == null || duration == Duration.zero || width <= 0) {
      return 0;
    }

    final position = Duration(
      milliseconds: (x / width * duration.inMilliseconds).round(),
    );
    final sampleIndex = source.positionToPixel(position).round();
    final minSample = source.getPixelMin(sampleIndex);
    final maxSample = source.getPixelMax(sampleIndex);
    final amplitude = math.max(minSample.abs(), maxSample.abs()).toDouble();
    final maxAmplitude = source.flags == 0 ? 32768.0 : 128.0;
    return (amplitude / maxAmplitude).clamp(0.08, 1.0);
  }

  double _syntheticHeight(double x) {
    final a = math.sin((x + seed * 17) * 0.035).abs();
    final b = math.sin((x + seed * 7) * 0.011).abs();
    return (0.18 + a * 0.42 + b * 0.35).clamp(0.1, 0.95);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.waveform != waveform ||
        oldDelegate.duration != duration ||
        oldDelegate.position != position ||
        oldDelegate.seed != seed ||
        oldDelegate.waveColor != waveColor ||
        oldDelegate.playedColor != playedColor;
  }
}
