import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/utils/audio_helper.dart';
import 'package:flutter_ai_music/utils/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';

class RecentlyPlayedSection extends ConsumerStatefulWidget {
  const RecentlyPlayedSection({super.key});

  @override
  ConsumerState<RecentlyPlayedSection> createState() => _RecentlyPlayedSectionState();
}

class _RecentlyPlayedSectionState extends ConsumerState<RecentlyPlayedSection> {
  static const _limit = 10;
  static const _animationDuration = Duration(milliseconds: 280);

  final _listKey = GlobalKey<AnimatedListState>();
  final List<Track> _visibleTracks = [];
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final recentTracksAsync = ref.watch(recentTracksProvider(_limit));

    ref.listen<AsyncValue<List<Track>>>(recentTracksProvider(_limit), (_, next) {
      next.whenData(_syncVisibleTracks);
    });

    recentTracksAsync.whenData((tracks) {
      if (_initialized) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncVisibleTracks(tracks));
    });

    if (!_initialized && recentTracksAsync.isLoading) {
      return const SizedBox.shrink();
    }

    return recentTracksAsync.when(
      loading: () => _buildContent(context),
      error: (_, __) => const SizedBox.shrink(),
      data: (_) => _buildContent(context),
    );
  }

  void _syncVisibleTracks(List<Track> nextTracks) {
    if (!mounted) return;

    if (!_initialized) {
      setState(() {
        _visibleTracks
          ..clear()
          ..addAll(nextTracks);
        _initialized = true;
      });
      return;
    }

    final nextIds = nextTracks.map((track) => track.id).toSet();

    for (var index = _visibleTracks.length - 1; index >= 0; index--) {
      final track = _visibleTracks[index];
      if (!nextIds.contains(track.id)) {
        final removedTrack = _visibleTracks.removeAt(index);
        _listKey.currentState?.removeItem(
          index,
          (context, animation) => _buildAnimatedItem(removedTrack, animation),
          duration: _animationDuration,
        );
      }
    }

    for (var targetIndex = 0; targetIndex < nextTracks.length; targetIndex++) {
      final nextTrack = nextTracks[targetIndex];
      final currentIndex = _visibleTracks.indexWhere((track) => track.id == nextTrack.id);

      if (currentIndex == -1) {
        _visibleTracks.insert(targetIndex, nextTrack);
        _listKey.currentState?.insertItem(targetIndex, duration: _animationDuration);
        continue;
      }

      _visibleTracks[currentIndex] = nextTrack;

      if (currentIndex != targetIndex) {
        final movedTrack = _visibleTracks.removeAt(currentIndex);
        _listKey.currentState?.removeItem(
          currentIndex,
          (context, animation) => _buildAnimatedItem(movedTrack, animation),
          duration: _animationDuration,
        );

        _visibleTracks.insert(targetIndex, movedTrack);
        _listKey.currentState?.insertItem(targetIndex, duration: _animationDuration);
      }
    }
  }

  Widget _buildContent(BuildContext context) {
    if (_visibleTracks.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recently Played",
                  style: TextStyle(fontFamily: "SpotifyMixUI", fontSize: 18, fontWeight: FontWeight.w800),
                ),
                TextButton(
                  onPressed: () => context.push('/recent-tracks'),
                  child: const Text(
                    "See All",
                    style: TextStyle(fontFamily: "SpotifyMixUI", fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: AnimatedList(
              key: _listKey,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 4, 0),
              initialItemCount: _visibleTracks.length,
              itemBuilder: (context, index, animation) {
                final track = _visibleTracks[index];
                return _buildAnimatedItem(
                  track,
                  animation,
                  onTap: () => _playTrack(track),
                  onLongPress: () => showTrackOptions(track, context),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedItem(
    Track track,
    Animation<double> animation, {
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return SizeTransition(
      axis: Axis.horizontal,
      sizeFactor: curvedAnimation,
      child: FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.16, 0), end: Offset.zero).animate(curvedAnimation),
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _RecentTrackCard(
              key: ValueKey(track.id),
              track: track,
              onTap: onTap ?? () {},
              onLongPress: onLongPress ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  void _playTrack(Track track) {
    try {
      AudioHelper.playTrackFromList(
        ref,
        allTracks: _visibleTracks,
        selectedIndex: _visibleTracks.indexWhere((item) => item.id == track.id),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error playing track: $e');
    }
  }
}

class _RecentTrackCard extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _RecentTrackCard({super.key, required this.track, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 1,
                child: CachedNetworkImage(
                  imageUrl: track.images.isNotEmpty ? track.images.first : '',
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey.shade800),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey.shade800,
                    child: const Icon(Icons.music_note, color: Colors.white54),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              track.name,
              style: const TextStyle(fontFamily: "SpotifyMixUI", fontSize: 14, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              track.artistName ?? "Unknown Artist",
              style: TextStyle(
                fontFamily: "SpotifyMixUI",
                fontSize: 12,
                color: Colors.white.withAlpha((0.6 * 255).toInt()),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
