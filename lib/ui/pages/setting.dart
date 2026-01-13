import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

class SettingPage extends ConsumerStatefulWidget {
  const SettingPage({super.key});

  @override
  ConsumerState<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends ConsumerState<SettingPage> {
  Duration _animationDuration = const Duration(milliseconds: 300);
  late VideoPlayerController _controller;
  final double _sensitivity = 1.2;
  late final double _minHeight;
  late final double _screenHeight;
  late final double _maxHeight;
  double _sheetHeight = 0;
  double _dragStartHeight = 0;

  final List<String> uris = [
    "https://res.cloudinary.com/dtf1ao1ds/video/upload/v1768311703/m0mzzzicicnvrkowohfl.mp4",
    "https://res.cloudinary.com/dtf1ao1ds/video/upload/v1768311702/vuanwygboqhqvtpbns9l.mp4",
    "https://res.cloudinary.com/dtf1ao1ds/video/upload/v1768311701/jfkdlqtzyrlbkxsgyvve.mp4",
    "https://res.cloudinary.com/dtf1ao1ds/video/upload/v1768309790/rddcekwduscpzioxfa3x.mp4",
  ];

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.networkUrl(
            Uri.parse(uris[3]),
            videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: true),
          )
          ..initialize().then((_) {
            if (!mounted) return;

            final Size(:width, :height) = MediaQuery.of(context).size;
            final topPadding = MediaQuery.of(context).padding.top;

            _screenHeight = height;
            _minHeight = _screenHeight * 0.6;

            final videoHeight = width / _controller.value.aspectRatio;
            final availableHeight = height - topPadding - videoHeight;

            _maxHeight = availableHeight.clamp(_minHeight, height - topPadding - 100);

            setState(() {});
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleSheet() => setState(() => _sheetHeight = _sheetHeight == 0 ? _maxHeight : 0);

  void _handlePanStart(DragStartDetails details) {
    if (_sheetHeight <= 0) return;
    _dragStartHeight = _sheetHeight;

    setState(() => _animationDuration = Duration.zero);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_sheetHeight <= 0 && _dragStartHeight <= 0) return;

    final Offset(:dx, :dy) = details.delta;
    if (dx.abs() < dy.abs() * 1.5) return;
    if (dx < 0 && _sheetHeight == _screenHeight) return;

    setState(() {
      double newHeight = _sheetHeight - dx * _sensitivity;
      _sheetHeight = newHeight.clamp(0.0, _maxHeight);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_dragStartHeight <= 0) return;

    setState(() {
      _animationDuration = const Duration(milliseconds: 300);
      final totalDragDistance = _dragStartHeight - _sheetHeight;
      final velocityX = details.velocity.pixelsPerSecond.dx;

      if ((velocityX > 500 && totalDragDistance > 25) || totalDragDistance > _maxHeight / 2 || _sheetHeight < 100) {
        _sheetHeight = 0;
      } else {
        _sheetHeight = _maxHeight;
      }
    });

    _dragStartHeight = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                      }
                    });
                  },
                  onLongPress: _toggleSheet,
                  child: _controller.value.isInitialized
                      ? AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller))
                      : Container(),
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: _sheetHeight <= 50
                    ? SizedBox.shrink()
                    : Column(
                        children: [
                          Icon(Icons.drag_handle, color: Colors.grey),
                          Text("Đây là nội dung chiếm diện tích thực"),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
