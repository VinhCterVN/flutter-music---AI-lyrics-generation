import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../component/element/slide/video_slide.dart';

class BoltPage extends ConsumerStatefulWidget {
  const BoltPage({super.key});

  @override
  ConsumerState<BoltPage> createState() => _SettingPageState();
}

class _SettingPageState extends ConsumerState<BoltPage> {
  late final PageController _pageController;
  final Map<int, File> _cachedFiles = {};
  int _currentPage = 0;
  bool _isPreloading = false;

  final List<String> uris = [
    "https://res.cloudinary.com/dtf1ao1ds/video/upload/v1768405581/zwh1b2g4wdg9gs3ben7w.mp4",
    "https://res.cloudinary.com/dtf1ao1ds/video/upload/v1768311703/m0mzzzicicnvrkowohfl.mp4",
    "https://res.cloudinary.com/dtf1ao1ds/video/upload/v1768405581/zwh1b2g4wdg9gs3ben7w.mp4",
    "https://res.cloudinary.com/dtf1ao1ds/video/upload/v1768311702/vuanwygboqhqvtpbns9l.mp4",
    "https://res.cloudinary.com/dtf1ao1ds/video/upload/v1768311701/jfkdlqtzyrlbkxsgyvve.mp4",
    "https://res.cloudinary.com/dtf1ao1ds/video/upload/v1768309790/rddcekwduscpzioxfa3x.mp4",
    "https://res.cloudinary.com/dtf1ao1ds/video/upload/v1768405581/zwh1b2g4wdg9gs3ben7w.mp4",
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _preloadVideos(0);
  }

  Future<void> _preloadVideos(int currentIndex) async {
    if (_isPreloading) return;
    _isPreloading = true;

    try {
      // Preload current, next and previous
      final indicesToLoad = [
        currentIndex,      // Current (priority)
        currentIndex + 1,  // Next
        currentIndex - 1,  // Previous
      ];

      // Load current first, then adjacent videos
      for (final index in indicesToLoad) {
        if (index >= 0 && index < uris.length && !_cachedFiles.containsKey(index)) {
          await _preload(index);

          // Small delay between downloads to avoid overwhelming network
          if (mounted) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
        }
      }
    } finally {
      _isPreloading = false;
    }
  }

  Future<void> _preload(int index) async {
    if (index < 0 || index >= uris.length) return;
    if (_cachedFiles.containsKey(index)) return;

    try {
      debugPrint('Preloading video at index $index');

      final file = await DefaultCacheManager().getSingleFile(
        uris[index],
        key: 'video_$index', // Add unique key for better cache management
      );

      if (mounted) {
        setState(() {
          _cachedFiles[index] = file;
        });
        debugPrint('Successfully cached video at index $index');
      }
    } catch (e) {
      debugPrint('Error preloading video at index $index: $e');
    }
  }

  void _onPageChanged(int index) {
    if (_currentPage == index) return;

    debugPrint('Page changed from $_currentPage to $index');

    setState(() {
      _currentPage = index;
    });

    // Preload adjacent videos
    _preloadVideos(index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: uris.length,
          pageSnapping: true,
          onPageChanged: _onPageChanged,
          physics: const PageScrollPhysics(),
          allowImplicitScrolling: true,
          itemBuilder: (context, index) {
            final file = _cachedFiles[index];

            if (file == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading video ${index + 1}/${uris.length}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return VideoSlide(
              key: ValueKey('video_$index'),
              videoFile: file,
              screenHeight: screenHeight,
              isCurrentPage: index == _currentPage,
            );
          },
        ),
      ),
    );
  }
}