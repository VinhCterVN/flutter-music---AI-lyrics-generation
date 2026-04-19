import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/enums/ui_state.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/playlist_provider.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/ui/layout/loading_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../utils/audio_helper.dart';
import '../../utils/functions.dart';

class LikedSongsPage extends ConsumerStatefulWidget {
  const LikedSongsPage({super.key});

  @override
  ConsumerState<LikedSongsPage> createState() => _LikedSongsPageState();
}

class _LikedSongsPageState extends ConsumerState<LikedSongsPage> {
  static const _coverUrl = 'https://misc.scdn.co/liked-songs/liked-songs-640.jpg';
  static const _accentColor = Color(0xFF171731);

  late final ScrollController _controller;

  List<Track> _tracks = [];
  UIState _state = UIState.loading;
  double _titleOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchTracks();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchTracks() async {
    setState(() => _state = UIState.loading);
    final ids = await ref.read(playlistServiceProvider).getFavouriteTrackIds();
    if (!mounted) return;
    if (ids.isEmpty) {
      setState(() {
        _tracks = [];
        _state = UIState.ready;
      });
      return;
    }
    final tracks = await ref.read(trackServiceProvider).getTracksByIds(ids.map((e) => e.toString()).toList());
    if (!mounted) return;
    setState(() {
      _tracks = tracks;
      _state = UIState.ready;
    });
  }

  Future<void> _playTrack(int selectedIndex) async {
    try {
      AudioHelper.playTrackFromList(ref, allTracks: _tracks, selectedIndex: selectedIndex);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error playing track: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state == UIState.loading) return const LoadingScaffold();

    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final topPadding = MediaQuery.paddingOf(context).top;

    final bgColor = mixColors([const MapEntry(_accentColor, 0.2), const MapEntry(Colors.black, 0.8)]);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── Main scroll content ──────────────────────────────────────────
          Positioned.fill(
            child: CustomScrollView(
              controller: _controller,
              slivers: [
                // ── Hero header ─────────────────────────────────────────────
                SliverPersistentHeader(
                  delegate: _LikedSongsHeaderDelegate(
                    minHeight: size.height * 0.42,
                    maxHeight: size.height * 0.55,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(18, topPadding + 18, 18, 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            scheme.surfaceDim,
                            scheme.surfaceContainerHigh,
                            mixColors([const MapEntry(_accentColor, 0.25), const MapEntry(Colors.black, 0.75)]),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Center(
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _accentColor.withAlpha(120),
                                          blurRadius: 24,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: CachedNetworkImage(
                                        imageUrl: _coverUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(color: _accentColor),
                                        errorWidget: (_, __, ___) => Container(
                                          color: _accentColor,
                                          child: const Icon(Icons.favorite, size: 64, color: Colors.white70),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Title with visibility tracking for the collapsed header
                          VisibilityDetector(
                            key: const Key('liked_songs_title_visibility'),
                            onVisibilityChanged: (info) {
                              if (!mounted) return;
                              setState(() => _titleOpacity = info.visibleFraction.clamp(0.0, 1.0));
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'Liked Songs',
                                style: TextStyle(
                                  fontFamily: 'SpotifyMixUI',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 28,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          // Subtitle row
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              spacing: 8,
                              children: [
                                const Icon(Icons.favorite_rounded, color: Color(0xFFB39DDB), size: 18),
                                Text(
                                  'Your favourites • ${_tracks.length} songs',
                                  style: TextStyle(
                                    fontFamily: 'SpotifyMixUI',
                                    fontSize: 13,
                                    color: Colors.white.withAlpha(180),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Action row
                          Row(
                            spacing: 4,
                            children: [
                              IconButton(
                                onPressed: () => Fluttertoast.showToast(msg: 'Download feature coming soon!'),
                                icon: const HugeIcon(
                                  icon: HugeIconsStrokeRounded.downloadCircle01,
                                  color: Colors.white70,
                                ),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: const HugeIcon(icon: HugeIconsStrokeRounded.share08, color: Colors.white70),
                              ),
                              const Spacer(),
                              // Shuffle
                              IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withAlpha(25),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () {
                                  if (_tracks.isEmpty) return;
                                  final shuffled = List<Track>.from(_tracks)..shuffle();
                                  AudioHelper.playTrackFromList(ref, allTracks: shuffled, selectedIndex: 0);
                                },
                                icon: const Icon(Icons.shuffle_rounded),
                              ),
                              const SizedBox(width: 8),
                              // Play
                              IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.greenAccent.shade400,
                                  foregroundColor: Colors.black,
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () => _playTrack(0),
                                icon: const Icon(Icons.play_arrow_rounded),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Track count badge ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      '${_tracks.length} songs',
                      style: TextStyle(
                        fontFamily: 'SpotifyMixUI',
                        fontSize: 13,
                        color: Colors.white.withAlpha(130),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),

                // ── Track list ───────────────────────────────────────────────
                if (_tracks.isEmpty)
                  SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final track = _tracks[index];
                        return _LikedTrackTile(track: track, index: index, onTap: () => _playTrack(index));
                      }, childCount: _tracks.length),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 160)),
              ],
            ),
          ),

          // ── Floating condensed app-bar on scroll ────────────────────────
          Align(
            alignment: Alignment.topCenter,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: 1.0 - _titleOpacity,
              child: Container(
                height: 86,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [const Color(0xFF0A38A8), _accentColor.withAlpha(180)],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(top: topPadding),
                  child: const Center(
                    child: Text(
                      'Liked Songs',
                      style: TextStyle(
                        fontFamily: 'SpotifyMixUI',
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Back button ─────────────────────────────────────────────────
          Align(
            alignment: AlignmentDirectional.topStart,
            child: SafeArea(
              top: true,
              child: GestureDetector(
                onTap: context.pop,
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _accentColor.withAlpha(40)),
              child: const Icon(Icons.favorite_border_rounded, size: 40, color: Color(0xFFB39DDB)),
            ),
            const SizedBox(height: 20),
            const Text(
              'No liked songs yet',
              style: TextStyle(
                fontFamily: 'SpotifyMixUI',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Songs you like will appear here.\nTap the ♥ on any track to save it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SpotifyMixUI',
                fontSize: 14,
                color: Colors.white.withAlpha(120),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Track tile ───────────────────────────────────────────────────────────────

class _LikedTrackTile extends StatelessWidget {
  final Track track;
  final int index;
  final VoidCallback onTap;

  const _LikedTrackTile({required this.track, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 46,
          height: 46,
          child: track.images.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: track.images.first,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey.shade800),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey.shade800,
                    child: const Icon(Icons.music_note, color: Colors.white38),
                  ),
                )
              : Container(
                  color: Colors.grey.shade800,
                  child: const Icon(Icons.music_note, color: Colors.white38),
                ),
        ),
      ),
      title: Text(
        track.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'SpotifyMixUI',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          letterSpacing: -0.15,
        ),
      ),
      subtitle: Row(
        spacing: 6,
        children: [
          // Heart badge
          const Icon(Icons.favorite_rounded, size: 12, color: Color(0xFFB39DDB)),
          Flexible(
            child: Text(
              track.artistName ?? 'Unknown Artist',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: 'SpotifyMixUI', fontSize: 13, color: Colors.white.withAlpha(160)),
            ),
          ),
        ],
      ),
      trailing: const Icon(Icons.more_vert_rounded, color: Colors.white38, size: 20),
    );
  }
}

// ── Sliver header delegate ───────────────────────────────────────────────────

class _LikedSongsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  const _LikedSongsHeaderDelegate({required this.minHeight, required this.maxHeight, required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  bool shouldRebuild(covariant _LikedSongsHeaderDelegate old) =>
      maxHeight != old.maxHeight || minHeight != old.minHeight || child != old.child;
}
