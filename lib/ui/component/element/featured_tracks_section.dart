import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/artist_provider.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/ui/component/element/home/animated_home_section.dart';
import 'package:flutter_ai_music/ui/component/element/press_scale.dart';
import 'package:flutter_ai_music/utils/audio_helper.dart';
import 'package:flutter_ai_music/utils/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FeaturedTracksSection extends ConsumerWidget {
  const FeaturedTracksSection({super.key, this.limit = 12});

  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredTracksAsync = ref.watch(featuredTracksProvider(limit));

    return featuredTracksAsync.when(
      loading: () =>
          const AnimatedHomeSection(child: _FeaturedTracksSkeleton(key: ValueKey('featured-tracks-loading'))),
      error: (_, __) => const AnimatedHomeSection(child: SizedBox.shrink(key: ValueKey('featured-tracks-error'))),
      data: (tracks) {
        if (tracks.isEmpty) {
          return const AnimatedHomeSection(child: SizedBox.shrink(key: ValueKey('featured-tracks-empty')));
        }

        return AnimatedHomeSection(
          child: Padding(
            key: ValueKey('featured-tracks-${tracks.length}'),
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text('Featured tracks', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 230,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      return _FeaturedTrackCard(
                        track: track,
                        onTap: () => AudioHelper.playTrackFromList(ref, allTracks: tracks, selectedIndex: index),
                        onLongPress: () => showTrackOptions(context, track),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemCount: tracks.length,
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

class _FeaturedTrackCard extends StatefulWidget {
  const _FeaturedTrackCard({required this.track, required this.onTap, required this.onLongPress});

  final Track track;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  State<_FeaturedTrackCard> createState() => _FeaturedTrackCardState();
}

class _FeaturedTrackCardState extends State<_FeaturedTrackCard> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 154,
      child: PressScale(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 1,
                child: CachedNetworkImage(
                  imageUrl: widget.track.images.firstOrNull ?? '',
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: scheme.surfaceContainerHighest),
                  errorWidget: (_, __, ___) => Container(
                    color: scheme.surfaceContainerHighest,
                    child: Icon(Icons.music_note_rounded, color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              widget.track.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.15),
            ),
            const SizedBox(height: 3),
            PressScale(
              onTap: () => context.push(
                artistRouteLocation(artistId: widget.track.artistId, artistType: widget.track.artistType),
              ),
              child: Text(
                widget.track.artistName ?? 'Unknown Artist',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedTracksSkeleton extends StatelessWidget {
  const _FeaturedTracksSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeSectionSkeletonBox(width: 150, height: 22, borderRadius: 8),
          const SizedBox(height: 12),
          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) => const SizedBox(
                width: 154,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeSectionSkeletonBox(width: 154, height: 154, borderRadius: 8),
                    SizedBox(height: 9),
                    HomeSectionSkeletonBox(width: 132, height: 14, borderRadius: 7),
                    SizedBox(height: 8),
                    HomeSectionSkeletonBox(width: 96, height: 12, borderRadius: 6),
                  ],
                ),
              ),
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemCount: 3,
            ),
          ),
        ],
      ),
    );
  }
}
