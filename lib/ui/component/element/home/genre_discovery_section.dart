import 'package:flutter/material.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/ui/component/element/home/animated_home_section.dart';
import 'package:flutter_ai_music/ui/component/element/press_scale.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

/// A horizontal rail of colourful genre cards that deep-link into the
/// genre detail page (`/genres/:genre`).
class GenreDiscoverySection extends ConsumerWidget {
  const GenreDiscoverySection({super.key, this.limit = 12});

  final int limit;

  // Curated gradient palette; a genre is mapped to a pair deterministically so
  // the same genre always shows the same colour across rebuilds.
  static const List<List<Color>> _palettes = [
    [Color(0xff5b6cff), Color(0xff8f5bff)],
    [Color(0xffff6b6b), Color(0xffff9f43)],
    [Color(0xff11998e), Color(0xff38ef7d)],
    [Color(0xfff857a6), Color(0xffff5858)],
    [Color(0xff4776e6), Color(0xff8e54e9)],
    [Color(0xffff9966), Color(0xffff5e62)],
    [Color(0xff1fa2ff), Color(0xff12d8fa)],
    [Color(0xffc471f5), Color(0xfffa71cd)],
  ];

  static List<Color> _paletteFor(String genre) {
    final hash = genre.toLowerCase().codeUnits.fold<int>(0, (acc, c) => acc + c);
    return _palettes[hash % _palettes.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genresAsync = ref.watch(allGenresProvider);

    return genresAsync.when(
      loading: () => const AnimatedHomeSection(child: _GenreSkeleton(key: ValueKey('genre-discovery-loading'))),
      error: (_, __) =>
          const AnimatedHomeSection(child: SizedBox.shrink(key: ValueKey('genre-discovery-error'))),
      data: (genres) {
        if (genres.isEmpty) {
          return const AnimatedHomeSection(child: SizedBox.shrink(key: ValueKey('genre-discovery-empty')));
        }

        final visible = genres.take(limit).toList();

        return AnimatedHomeSection(
          child: Padding(
            key: ValueKey('genre-discovery-${visible.length}'),
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text('Browse by genre', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final genre = visible[index];
                      return _GenreCard(
                        genre: genre,
                        colors: _paletteFor(genre),
                        onTap: () => context.push('/genres/$genre'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GenreCard extends StatelessWidget {
  const _GenreCard({required this.genre, required this.colors, required this.onTap});

  final String genre;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 92,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          boxShadow: [BoxShadow(color: colors.last.withAlpha(60), blurRadius: 14, offset: const Offset(0, 8))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Decorative offset icon bleeding off the corner.
            Positioned(
              right: -8,
              bottom: -10,
              child: Transform.rotate(
                angle: 0.4,
                child: Icon(Icons.music_note_rounded, size: 64, color: Colors.white.withAlpha(38)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedMusicNote01, color: Colors.white.withAlpha(230), size: 20),
                  const Spacer(),
                  Text(
                    genre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1))],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenreSkeleton extends StatelessWidget {
  const _GenreSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeSectionSkeletonBox(width: 170, height: 22, borderRadius: 8),
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => const HomeSectionSkeletonBox(width: 160, height: 92, borderRadius: 18),
            ),
          ),
        ],
      ),
    );
  }
}
