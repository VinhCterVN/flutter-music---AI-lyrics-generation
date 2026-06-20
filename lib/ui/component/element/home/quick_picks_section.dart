import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/ui/component/element/home/animated_home_section.dart';
import 'package:flutter_ai_music/ui/component/element/press_scale.dart';
import 'package:flutter_ai_music/utils/audio_helper.dart';
import 'package:flutter_ai_music/utils/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A compact two-row horizontal grid of suggested tracks for quick playback,
/// reusing the existing home discovery data.
class QuickPicksSection extends ConsumerWidget {
  const QuickPicksSection({super.key, this.maxTiles = 8});

  final int maxTiles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoveryAsync = ref.watch(homeDiscoveryProvider);

    return discoveryAsync.when(
      loading: () => const AnimatedHomeSection(child: _QuickPicksSkeleton(key: ValueKey('quick-picks-loading'))),
      error: (_, __) => const AnimatedHomeSection(child: SizedBox.shrink(key: ValueKey('quick-picks-error'))),
      data: (data) {
        // Prefer suggestions; fall back to top listened so the section is never
        // empty when there is any catalogue data at all.
        final source = data.suggestedTracks.isNotEmpty ? data.suggestedTracks : data.topListenedTracks;
        // Keep an even count so the 2-row grid stays balanced.
        var tiles = source.take(maxTiles).toList();
        if (tiles.length.isOdd) tiles = tiles.sublist(0, tiles.length - 1);

        if (tiles.isEmpty) {
          return const AnimatedHomeSection(child: SizedBox.shrink(key: ValueKey('quick-picks-empty')));
        }

        return AnimatedHomeSection(
          child: Padding(
            key: ValueKey('quick-picks-${tiles.length}'),
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text('Quick picks', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 148,
                  child: GridView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 264,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: tiles.length,
                    itemBuilder: (context, index) {
                      final track = tiles[index];
                      return _QuickPickTile(
                        track: track,
                        onTap: () => AudioHelper.playTrackFromList(ref, allTracks: tiles, selectedIndex: index),
                        onLongPress: () => showTrackOptions(context, track),
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

class _QuickPickTile extends StatelessWidget {
  const _QuickPickTile({required this.track, required this.onTap, required this.onLongPress});

  final Track track;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PressScale(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: track.images.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: track.images.first,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: scheme.surfaceContainerHighest),
                      errorWidget: (_, __, ___) => Container(
                        color: scheme.surfaceContainerHighest,
                        child: Icon(Icons.music_note_rounded, color: scheme.onSurfaceVariant),
                      ),
                    )
                  : Container(
                      color: scheme.surfaceContainerHighest,
                      child: Icon(Icons.music_note_rounded, color: scheme.onSurfaceVariant),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, height: 1.1),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      track.artistName ?? 'Unknown Artist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.play_arrow_rounded, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickPicksSkeleton extends StatelessWidget {
  const _QuickPicksSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeSectionSkeletonBox(width: 130, height: 22, borderRadius: 8),
          const SizedBox(height: 12),
          SizedBox(
            height: 148,
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 264,
                mainAxisSpacing: 12,
                crossAxisSpacing: 10,
              ),
              itemCount: 4,
              itemBuilder: (_, __) => const HomeSectionSkeletonBox(width: 264, height: 64, borderRadius: 14),
            ),
          ),
        ],
      ),
    );
  }
}
