import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/ui/component/element/home/animated_home_section.dart';
import 'package:flutter_ai_music/utils/audio_helper.dart';
import 'package:flutter_ai_music/utils/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RecentTracksSection extends ConsumerWidget {
  const RecentTracksSection({super.key});

  static const _limit = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentTracksAsync = ref.watch(recentTracksProvider(_limit));

    return recentTracksAsync.when(
      loading: () => const AnimatedHomeSection(child: _RecentTracksSkeleton(key: ValueKey('recent-tracks-loading'))),
      error: (_, __) => const AnimatedHomeSection(child: SizedBox.shrink(key: ValueKey('recent-tracks-error'))),
      data: (tracks) {
        if (tracks.isEmpty) {
          return const AnimatedHomeSection(child: SizedBox.shrink(key: ValueKey('recent-tracks-empty')));
        }

        final trackGroups = List<List<Track>>.generate(
          (tracks.length / 4).ceil(),
          (index) => tracks.skip(index * 4).take(4).toList(),
        );

        return AnimatedHomeSection(
          child: Padding(
            key: ValueKey('recent-tracks-${tracks.length}'),
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.withAlpha((0.05 * 255).toInt()),
              ),
              child: Column(
                spacing: 10,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            "Don't miss your recent tracks",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/recent-tracks'),
                          child: const Text(
                            "See All",
                            style: TextStyle(color: Colors.white, decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CarouselSlider(
                    options: CarouselOptions(height: 270, viewportFraction: 0.93, padEnds: false),
                    items: trackGroups.map((group) {
                      return Builder(
                        builder: (BuildContext context) {
                          return Container(
                            margin: const EdgeInsets.only(left: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(group.length, (index) {
                                final track = group[index];
                                return InkWell(
                                  onTap: () => AudioHelper.playTrackFromList(
                                    ref,
                                    allTracks: tracks,
                                    selectedIndex: tracks.indexWhere((item) => item.id == track.id),
                                  ),
                                  onLongPress: () => showTrackOptions(context, track),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: CachedNetworkImage(
                                            imageUrl: track.images.firstOrNull ?? '',
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) => Container(
                                              width: 50,
                                              height: 50,
                                              color: Colors.grey.shade800,
                                              child: const Icon(Icons.music_note, color: Colors.white54),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                track.name,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                  letterSpacing: (-0.15),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                track.artistName ?? track.artistType.name,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white.withAlpha((0.7 * 255).toInt()),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => showTrackOptions(context, track),
                                          icon: const Icon(Icons.more_vert_rounded),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RecentTracksSkeleton extends StatelessWidget {
  const _RecentTracksSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.withAlpha((0.05 * 255).toInt()),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomeSectionSkeletonBox(width: 220, height: 20, borderRadius: 8),
            const SizedBox(height: 18),
            ...List.generate(
              4,
              (index) => const Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    HomeSectionSkeletonBox(width: 50, height: 50, borderRadius: 4),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HomeSectionSkeletonBox(width: double.infinity, height: 14, borderRadius: 7),
                          SizedBox(height: 8),
                          HomeSectionSkeletonBox(width: 140, height: 12, borderRadius: 6),
                        ],
                      ),
                    ),
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
