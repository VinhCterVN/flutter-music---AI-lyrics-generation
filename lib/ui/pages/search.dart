import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ai_music/ui/component/element/track_card_demo.dart';
import 'package:flutter_ai_music/ui/component/navigation/playing_screen.dart';
import 'package:flutter_ai_music/utils/mock_tracks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/track.dart';
import '../../provider/track_provider.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  Track? currentTrack;
  List<Track> tracks = [];
  StreamSubscription<List<Track>>? _sub;

  final Set<String> likedTrackIds = {};
  final Map<String, AnimationController> _scaleControllers = {};

  @override
  void initState() {
    final trackService = ref.read(trackServiceProvider);
    _sub = trackService.streamTrackList(ref).listen((newTracks) {
      setState(() {
        tracks = newTracks;
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    for (var controller in _scaleControllers.values) {
      controller.dispose();
    }
    _sub?.cancel();
    super.dispose();
  }

  void playTrack(Track track) {
    setState(() {
      currentTrack = track;
    });
  }

  void toggleLike(String trackId) {
    setState(() {
      if (likedTrackIds.contains(trackId)) {
        likedTrackIds.remove(trackId);
      } else {
        likedTrackIds.add(trackId);
      }
    });
  }

  String formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  List<Color> getGradientColors(int index) {
    final colorIndex = index % 5;
    switch (colorIndex) {
      case 0:
        return [const Color(0xFF667eea), const Color(0xFF764ba2)];
      case 1:
        return [const Color(0xFFf093fb), const Color(0xFFf5576c)];
      case 2:
        return [const Color(0xFF4facfe), const Color(0xFF00f2fe)];
      case 3:
        return [const Color(0xFF43e97b), const Color(0xFF38f9d7)];
      default:
        return [const Color(0xFFfa709a), const Color(0xFFfee140)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: 100)),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => TrackCardDemo(
                track: mockTracks[index],
                onPlay: () => showModalBottomSheet(
                  context: context,
                  useRootNavigator: true,
                  isScrollControlled: true,
                  enableDrag: true,
                  barrierColor: Colors.black54,
                  backgroundColor: Colors.transparent,
                  sheetAnimationStyle: AnimationStyle(curve: Curves.easeOut, duration: const Duration(seconds: 1)),
                  builder: (context) => Dismissible(
                    key: const ValueKey("TrackSheet"),
                    direction: DismissDirection.horizontal,
                    onDismissed: (_) => Navigator.pop(context),
                    child: PlayingScreen(),
                  ),
                ),
                onFavorite: () {},
              ),
              childCount: mockTracks.length,
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}
