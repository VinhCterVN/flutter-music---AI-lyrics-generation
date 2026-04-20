import 'dart:math';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/artist_provider.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/ui/component/navigation/track_options_bottom_sheet.dart';
import 'package:flutter_ai_music/utils/audio_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

class HomeDiscoverySections extends ConsumerWidget {
  const HomeDiscoverySections({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoveryAsync = ref.watch(homeDiscoveryProvider);

    return discoveryAsync.when(
      loading: () => const SliverToBoxAdapter(child: SizedBox(height: 8)),
      error: (error, stackTrace) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (data) {
        final hasHistory = data.topListenedTracks.isNotEmpty;
        final primaryTracks = hasHistory ? data.topListenedTracks : data.suggestedTracks;
        final secondaryTracks = hasHistory ? data.suggestedTracks : <Track>[];

        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (primaryTracks.isNotEmpty) ...[
                  _SectionHeader(
                    eyebrow: hasHistory ? 'Top listened' : 'Suggestion',
                    title: hasHistory ? 'Your most replayed tracks' : 'More to explore',
                    subtitle: hasHistory
                        ? 'Built from your listening history.'
                        : 'A few artist rails to get you listening right away.',
                  ),
                  const SizedBox(height: 12),
                  _ArtistTrackCarousel(tracks: primaryTracks, forceOrderByHistory: hasHistory),
                ],
                if (secondaryTracks.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _SectionHeader(
                    eyebrow: 'Suggestion',
                    title: 'More artists you might like',
                  ),
                  const SizedBox(height: 12),
                  _ArtistTrackCarousel(tracks: secondaryTracks, forceOrderByHistory: false),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;

  const _SectionHeader({required this.eyebrow, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: TextStyle(
              fontFamily: 'SpotifyMixUI',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: scheme.onSurfaceVariant.withAlpha(220),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontFamily: 'SpotifyMixUI', fontSize: 26, fontWeight: FontWeight.w900, height: 1.0),
          ),
          const SizedBox(height: 6),
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(fontFamily: 'SpotifyMixUI', fontSize: 13, color: scheme.onSurfaceVariant.withAlpha(210)),
            ),
        ],
      ),
    );
  }
}

class _ArtistGroup {
  final String artistId;
  final String artistName;
  final ArtistType artistType;
  final String? imageUrl;
  final List<Track> tracks;
  final int score;

  const _ArtistGroup({
    required this.artistId,
    required this.artistName,
    required this.artistType,
    required this.imageUrl,
    required this.tracks,
    required this.score,
  });
}

class _ArtistTrackCarousel extends StatelessWidget {
  final List<Track> tracks;
  final bool forceOrderByHistory;

  const _ArtistTrackCarousel({required this.tracks, required this.forceOrderByHistory});

  @override
  Widget build(BuildContext context) {
    final groups = _groupTracks(tracks);
    if (groups.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 390,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.9),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _ArtistTrackPage(group: group, forceOrderByHistory: forceOrderByHistory),
          );
        },
      ),
    );
  }

  List<_ArtistGroup> _groupTracks(List<Track> source) {
    final byArtist = <String, List<Track>>{};
    for (final track in source) {
      byArtist.putIfAbsent(track.artistId, () => []).add(track);
    }

    final groups = byArtist.entries.map((entry) {
      final artistTracks = entry.value;
      final firstTrack = artistTracks.first;
      final artistName = firstTrack.artistName ?? firstTrack.artistId;
      final score = forceOrderByHistory ? artistTracks.length * 1000 : artistTracks.length;
      return _ArtistGroup(
        artistId: entry.key,
        artistName: artistName,
        artistType: firstTrack.artistType,
        imageUrl: _pickImage(artistTracks),
        tracks: artistTracks.take(4).toList(),
        score: score,
      );
    }).toList();

    groups.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return a.artistName.compareTo(b.artistName);
    });

    return groups.take(5).toList();
  }

  String? _pickImage(List<Track> tracks) {
    for (final track in tracks) {
      if (track.images.isNotEmpty) return track.images.first;
    }
    return null;
  }
}

class _ArtistTrackPage extends ConsumerWidget {
  final _ArtistGroup group;
  final bool forceOrderByHistory;

  const _ArtistTrackPage({required this.group, required this.forceOrderByHistory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradient = [
      Theme.of(context).colorScheme.primaryContainer,
      Theme.of(context).colorScheme.secondaryContainer,
      Theme.of(context).colorScheme.tertiaryContainer,
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradient[0], gradient[1], gradient[2]],
        ),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(28), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: group.imageUrl == null
                  ? Container(color: Colors.black12)
                  : CachedNetworkImage(
                      imageUrl: group.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(color: Colors.black12),
                    ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withAlpha(24), Colors.black.withAlpha(80), Colors.black.withAlpha(180)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.push(
                      artistRouteLocation(
                        artistId: group.artistId,
                        artistType: group.artistType,
                        artistName: group.artistName,
                        imageUrl: group.imageUrl,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.artistName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'SpotifyMixUI',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                forceOrderByHistory ? 'Top listened artist' : 'Suggestion',
                                style: TextStyle(
                                  fontFamily: 'SpotifyMixUI',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withAlpha(210),
                                  shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                                ),
                              ),
                            ],
                          ),
                        ),
                        HugeIcon(icon: HugeIcons.strokeRoundedUserMultiple, color: Colors.white.withAlpha(230)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: min(group.tracks.length, 4),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final track = group.tracks[index];
                        return _TrackRow(
                          track: track,
                          onTap: () =>
                              AudioHelper.playTrackFromList(ref, allTracks: group.tracks, selectedIndex: index),
                          onLongPress: () => _showTrackOptions(context, track),
                        );
                      },
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

  void _showTrackOptions(BuildContext context, Track track) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        snap: true,
        snapSizes: const [0.5, 0.75, 1.0],
        initialChildSize: 0.5,
        minChildSize: 0.5,
        maxChildSize: 1.0,
        builder: (context, scrollController) =>
            TrackOptionsBottomSheet(track: track, scrollController: scrollController),
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _TrackRow({required this.track, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(115),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(14)),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(28), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: track.images.isNotEmpty
                        ? CachedNetworkImage(imageUrl: track.images.first, fit: BoxFit.cover)
                        : Container(color: scheme.surfaceContainerHighest, child: const Icon(Icons.music_note_rounded)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        track.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'SpotifyMixUI',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        track.artistName ?? track.artistId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: 'SpotifyMixUI', fontSize: 12, color: Colors.white.withAlpha(190)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.play_arrow_rounded, color: Colors.white.withAlpha(220)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
