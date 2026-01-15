import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoSlide extends ConsumerStatefulWidget {
  final File videoFile;
  final double screenHeight;
  final bool isCurrentPage;

  const VideoSlide({super.key, required this.videoFile, required this.screenHeight, this.isCurrentPage = false});

  @override
  ConsumerState<VideoSlide> createState() => _VideoSlideState();
}

class _VideoSlideState extends ConsumerState<VideoSlide> with AutomaticKeepAliveClientMixin {
  Duration _animationDuration = const Duration(milliseconds: 300);
  late final double _maxHeight;
  final double _sensitivity = 1.2;
  double _sheetHeight = 0.0;
  double _dragStartHeight = 0;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  double aspectRatio = 16 / 9;

  Player? _player;
  VideoController? _controller;
  bool _isDisposed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _maxHeight = widget.screenHeight * 2 / 3;
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    if (_isDisposed) return;

    try {
      _player = Player(
        configuration: PlayerConfiguration(
          title: 'Video Slide Player',
          ready: () {
            log("Player for ${widget.videoFile.path} is ready");
          },
        ),
      );

      _controller = VideoController(_player!);

      await Future.delayed(const Duration(milliseconds: 100));

      if (_isDisposed) {
        await _player?.dispose();
        return;
      }

      await _player!.open(Media(widget.videoFile.path));

      if (!mounted || _isDisposed) return;

      _isInitialized = true;
      while (_controller?.player.state.videoParams.aspect == null) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      aspectRatio = _controller!.player.state.videoParams.aspect!;

      setState(() {});

      if (widget.isCurrentPage) {
        await _player?.play();
      }
    } catch (e) {
      log('Error initializing player: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void didUpdateWidget(VideoSlide oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isCurrentPage != oldWidget.isCurrentPage) {
      _handlePageVisibilityChange();
    }
  }

  @override
  void deactivate() {
    super.deactivate();
    _handlePageVisibilityChange();
  }

  Future<void> _handlePageVisibilityChange() async {
    if (_player == null || _isDisposed) return;

    try {
      if (widget.isCurrentPage) {
        await _player?.play();
      } else {
        await _player?.pause();
      }
    } catch (e) {
      log('Error handling visibility change: $e');
    }
  }

  Future<void> _togglePlayPause() async {
    if (_player == null || _isDisposed) return;

    try {
      if (_player!.state.playing) {
        await _player!.pause();
      } else {
        await _player!.play();
      }
    } catch (e) {
      log('Error toggling play/pause: $e');
    }
  }

  void _toggleSheet() {
    if (!_isInitialized || _isDisposed) return;
    setState(() => _sheetHeight = _sheetHeight == 0 ? _maxHeight : 0);
  }

  void _handlePanStart(DragStartDetails details) {
    if (_sheetHeight <= 0) return;
    _dragStartHeight = _sheetHeight;
    _animationDuration = Duration.zero;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_sheetHeight <= 0 && _dragStartHeight <= 0) return;

    final Offset(:dx, :dy) = details.delta;
    if (dx.abs() < dy.abs() * 1.5) return;
    if (dx < 0 && _sheetHeight == widget.screenHeight) return;

    double newHeight = _sheetHeight - dx * _sensitivity;
    _sheetHeight = newHeight.clamp(0.0, _maxHeight);

    if (mounted && !_isDisposed) {
      setState(() {});
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_dragStartHeight <= 0) return;

    final totalDragDistance = _dragStartHeight - _sheetHeight;
    final velocityX = details.velocity.pixelsPerSecond.dx;

    _animationDuration = const Duration(milliseconds: 300);

    if ((velocityX > 500 && totalDragDistance > 25) || totalDragDistance > _maxHeight / 2 || _sheetHeight < 100) {
      _sheetHeight = 0;
    } else {
      _sheetHeight = _maxHeight;
    }

    _dragStartHeight = 0;

    if (mounted && !_isDisposed) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    log('Disposing VideoSlide for ${widget.videoFile.path}');
    _isDisposed = true;
    _disposePlayer();
    super.dispose();
  }

  Future<void> _disposePlayer() async {
    try {
      await _player?.pause();
      await _player?.dispose();
      _player = null;
      _controller = null;
    } catch (e) {
      log('Error disposing player: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final Size(:width, :height) = MediaQuery.of(context).size;

    if (_hasError) {
      return SizedBox(
        height: height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Unable to play video', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'This device doesn\'t support codec HEVC (H.265)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return SizedBox(
        height: height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _togglePlayPause(),
              onLongPress: _toggleSheet,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 50),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    borderRadius: _sheetHeight > 0
                        ? BorderRadius.circular((12 * (_sheetHeight / _maxHeight)).clamp(0, 12))
                        : BorderRadius.zero,
                  ),
                  clipBehavior: _sheetHeight > 0 ? Clip.antiAlias : Clip.none,
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: Video(controller: _controller!, controls: NoVideoControls),
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            child: AnimatedContainer(
              duration: _animationDuration,
              curve: Curves.easeOutCubic,
              height: _sheetHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceBright,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: _sheetHeight <= 50
                  ? const SizedBox.shrink()
                  : const Column(
                      children: [
                        Icon(Icons.drag_handle, color: Colors.grey),
                        Text("Đây là nội dung chiếm diện tích thực"),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
