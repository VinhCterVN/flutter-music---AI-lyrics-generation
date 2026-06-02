import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/ui/component/element/press_scale.dart';
import 'package:flutter_ai_music/ui/theme/theme.dart';
import 'package:flutter_ai_music/utils/audio_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final featuredTracksAsync = ref.watch(featuredTracksProvider(10));
    final likedTracksAsync = ref.watch(likedTracksProvider);
    final genresAsync = ref.watch(allGenresProvider);

    return Scaffold(
      backgroundColor: scheme.surfaceDim,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: false,
            toolbarHeight: 48,
            scrolledUnderElevation: 0,
            backgroundColor: scheme.surfaceDim,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: CircleAvatar(backgroundImage: CachedNetworkImageProvider('https://i.pravatar.cc/150')),
            ),
            leadingWidth: 50,
            title: const Text(
              'Search',
              style: TextStyle(fontFamily: appFontFamily, fontSize: 26, fontWeight: FontWeight.w900),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 23),
                onPressed: () {},
              ),
            ],
          ),

          SliverPersistentHeader(
            pinned: true,
            delegate: _SearchBarDelegate(topPadding: MediaQuery.paddingOf(context).top),
          ),

          SliverToBoxAdapter(
            child: _buildTrackHorizontalSection(context, ref, "Featured Tracks", featuredTracksAsync),
          ),

          SliverToBoxAdapter(
            child: _buildTrackHorizontalSection(context, ref, "Liked Tracks", likedTracksAsync),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 26, 16, 8),
              child: Text("Categories", style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),

          genresAsync.when(
            data: (genres) {
              if (genres.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: Text('No genres found', style: TextStyle(color: Colors.white54))),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final genreName = genres[index];
                      final hash = genreName.toLowerCase().hashCode;
                      final colors = [
                        const Color(0xFF673AB7), // Deep Purple
                        const Color(0xFF3F51B5), // Indigo
                        const Color(0xFF2196F3), // Blue
                        const Color(0xFF009688), // Teal
                        const Color(0xFF4CAF50), // Green
                        const Color(0xFFFFC107), // Amber
                        const Color(0xFFFF9800), // Orange
                        const Color(0xFFFF5722), // Deep Orange
                        const Color(0xFFE91E63), // Pink
                        const Color(0xFF9C27B0), // Purple
                      ];
                      final genreColor = colors[hash.abs() % colors.length];

                      return PressScale(
                        onTap: () {
                          context.push('/genres/$genreName');
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            // color: genreColor.withAlpha((0.95 * 255).toInt()),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [genreColor, genreColor.withAlpha(100)]
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            genreName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: -0.25,
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: genres.length,
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
            ),
            error: (error, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Text('Failed to load genres: $error', style: const TextStyle(color: Colors.redAccent)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackHorizontalSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    AsyncValue<List<Track>> tracksAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
        SizedBox(
          height: 195,
          child: tracksAsync.when(
            data: (tracks) {
              if (tracks.isEmpty) {
                return const Center(
                  child: Text('No tracks found', style: TextStyle(color: Colors.white38, fontSize: 14)),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  final image = track.images.isNotEmpty ? track.images.first : '';
                  return PressScale(
                    onTap: () {
                      AudioHelper.playTrackFromList(ref, allTracks: tracks, selectedIndex: index);
                    },
                    child: Container(
                      width: 130,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 130,
                            width: 130,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(12),
                              image: image.isNotEmpty
                                  ? DecorationImage(image: CachedNetworkImageProvider(image), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: image.isEmpty
                                ? const Center(child: Icon(Icons.music_note, color: Colors.white30, size: 40))
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            track.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            track.artistName ?? 'Unknown Artist',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
            error: (error, _) => Center(
              child: Text('Error: $error', style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  const _SearchBarDelegate({required this.topPadding});

  final double topPadding;

  static const _searchBarHeight = 48.0;
  static const _verticalPadding = 4.0;

  double get _extent => topPadding + _searchBarHeight + (_verticalPadding * 2);

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.only(top: topPadding),
      color: scheme.surfaceDim,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, _verticalPadding, 16, _verticalPadding * 2),
        child: Container(
          height: _searchBarHeight,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
          child: const TextField(
            decoration: InputDecoration(
              hintText: "What should we listen to?",
              hintStyle: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, letterSpacing: -0.25),
              prefixIcon: Padding(
                padding: EdgeInsets.all(8.0),
                child: HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: Colors.black87),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SearchBarDelegate oldDelegate) => topPadding != oldDelegate.topPadding;
}
