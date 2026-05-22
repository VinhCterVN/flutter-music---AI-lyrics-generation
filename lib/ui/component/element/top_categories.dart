import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/playlist.dart';
import 'package:flutter_ai_music/provider/playlist_provider.dart';
import 'package:flutter_ai_music/ui/component/element/home/animated_home_section.dart';
import 'package:flutter_ai_music/ui/component/element/press_scale.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../provider/track_provider.dart';
import '../dialog/playlist_options_bottom_sheet.dart';

class TopCategories extends ConsumerWidget {
  const TopCategories({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistService = ref.watch(playlistServiceProvider);

    return StreamBuilder<List<Playlist>>(
      stream: playlistService.streamPlaylists(limit: 10),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const SliverToBoxAdapter(
            child: AnimatedHomeSection(child: _TopCategoriesSkeleton(key: ValueKey('top-categories-loading'))),
          );
        }

        final playlists = snapshot.data ?? [];

        return SliverToBoxAdapter(
          child: AnimatedHomeSection(
            child: _TopCategoriesGrid(key: ValueKey('top-categories-${playlists.length}'), playlists: playlists),
          ),
        );
      },
    );
  }
}

class _TopCategoriesGrid extends StatelessWidget {
  const _TopCategoriesGrid({super.key, required this.playlists});

  final List<Playlist> playlists;

  @override
  Widget build(BuildContext context) {
    final itemCount = 1 + playlists.length;

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 48,
      ),
      itemBuilder: (context, index) {
        if (index == 0) return const _LikedSongsCard();
        return _QuickPlayCard(key: Key(playlists[index - 1].id), playlist: playlists[index - 1]);
      },
      itemCount: itemCount,
    );
  }
}

class _TopCategoriesSkeleton extends StatelessWidget {
  const _TopCategoriesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 48,
      ),
      itemBuilder: (context, index) =>
          const HomeSectionSkeletonBox(width: double.infinity, height: 48, borderRadius: 4),
      itemCount: 4,
    );
  }
}

class _QuickPlayCard extends ConsumerStatefulWidget {
  final Playlist playlist;

  const _QuickPlayCard({required super.key, required this.playlist});

  @override
  ConsumerState<_QuickPlayCard> createState() => _QuickPlayCardState();
}

class _QuickPlayCardState extends ConsumerState<_QuickPlayCard> {
  late String? _photoUrl = widget.playlist.photoUrl;

  @override
  void initState() {
    super.initState();
    _loadPhotoUrl();
  }

  Future<void> _loadPhotoUrl() async {
    if (_photoUrl != null) return;
    if (widget.playlist.trackIds.isEmpty) {
      setState(() => _photoUrl = "https://i.pravatar.cc/300?u=${widget.playlist.id}");
      return;
    }
    final track = await ref.read(trackServiceProvider).getTracksByIds([widget.playlist.trackIds.first.toString()]);
    if (!mounted) return;
    setState(() => _photoUrl = track.first.images.first);
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final imageSize = (64 * dpr).round();
    final playlist = widget.playlist;
    final heroPrefix = 'playlist-${playlist.id}';

    return PressScale(
      key: widget.key,
      onTap: () => context.push('/playlist/${playlist.id}', extra: playlist.copyWith(photoUrl: _photoUrl)),
      onLongPress: () => showPlaylistOptions(context, playlist: playlist, photoUrl: _photoUrl),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white70.withAlpha(30),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 4, offset: const Offset(0, 2))],
            ),
          ),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Hero(
                    tag: '$heroPrefix-image',
                    child: _photoUrl == null
                        ? Container(
                            color: Colors.grey.shade800,
                            child: Center(child: const Icon(Icons.music_note, color: Colors.white54)),
                          )
                        : CachedNetworkImage(
                            imageUrl: _photoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: Colors.grey.shade800),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey.shade800,
                              child: const Icon(Icons.music_note, color: Colors.white54),
                            ),
                            memCacheWidth: imageSize,
                            memCacheHeight: imageSize,
                            maxWidthDiskCache: imageSize,
                            maxHeightDiskCache: imageSize,
                          ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Hero(
                    tag: '$heroPrefix-title',
                    flightShuttleBuilder: (_, animation, __, ___, toHeroContext) =>
                        FadeTransition(opacity: animation, child: toHeroContext.widget),
                    child: Text(
                      playlist.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LikedSongsCard extends StatelessWidget {
  const _LikedSongsCard();

  static const _thumbUrl = 'https://misc.scdn.co/liked-songs/liked-songs-640.jpg';

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () => context.push('/liked-songs'),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF4C2B8A), Color(0xFF2D1B5E)]),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 48,
                height: 48,
                child: CachedNetworkImage(
                  imageUrl: _thumbUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: const Color(0xFF4C2B8A)),
                  errorWidget: (_, __, ___) => const Icon(Icons.favorite, color: Colors.pinkAccent),
                ),
              ),
            ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'Liked Songs',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
