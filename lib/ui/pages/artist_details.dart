import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/artist.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/artist_provider.dart';
import 'package:flutter_ai_music/provider/audio_provider.dart';
import 'package:flutter_ai_music/ui/component/element/track_tile.dart';
import 'package:flutter_ai_music/ui/component/navigation/track_options_bottom_sheet.dart';
import 'package:flutter_ai_music/ui/layout/loading_scaffold.dart';
import 'package:flutter_ai_music/utils/audio_helper.dart';
import 'package:flutter_ai_music/utils/functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

class ArtistDetailsPage extends ConsumerStatefulWidget {
  final ArtistRouteArgs args;

  const ArtistDetailsPage({super.key, required this.args});

  @override
  ConsumerState<ArtistDetailsPage> createState() => _ArtistDetailsPageState();
}

class _ArtistDetailsPageState extends ConsumerState<ArtistDetailsPage> {
  bool? _followOverride;
  bool _isUpdatingFollow = false;

  @override
  Widget build(BuildContext context) {
    final artistAsync = ref.watch(artistPageDataProvider(widget.args));

    return artistAsync.when(
      loading: () => const LoadingScaffold(),
      error: (error, stackTrace) => _ArtistErrorScaffold(message: error.toString()),
      data: (data) {
        final artist = data.artist;
        final tracks = data.tracks;
        final summary = data.summary;
        final scheme = Theme.of(context).colorScheme;
        final followState = _followOverride ?? data.isFollowing;
        final currentTrackId = ref.watch(currentTrackProvider).value?.id;
        final imageUrl = artist.primaryImageUrl ?? widget.args.fallbackImageUrl;
        final description = artist.artistType == ArtistType.SpotifyArtist
            ? (summary?.description.isNotEmpty == true ? summary!.description : 'Spotify artist')
            : 'Nest artist profile is still temporary';
        final summaryText = artist.artistType == ArtistType.SpotifyArtist
            ? stripHtml(summary?.extract ?? 'No biography available yet for this artist.')
            : 'This artist is coming from local/Nest data, so rich profile content is not in the database yet. We can still show follow state and tracks connected to this artist id.';

        return Scaffold(
          backgroundColor: scheme.surfaceDim,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 320,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final topPadding = MediaQuery.paddingOf(context).top;
                    final collapsedHeight = kToolbarHeight + topPadding;
                    final collapseProgress = ((collapsedHeight + 36 - constraints.maxHeight) / 36).clamp(0.0, 1.0);

                    return FlexibleSpaceBar(
                      titlePadding: const EdgeInsetsDirectional.only(start: 72, bottom: 16, end: 72),
                      title: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: collapseProgress.toDouble(),
                        child: Text(
                          artist.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'SpotifyMixUI',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      expandedTitleScale: 1,
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (imageUrl != null && imageUrl.isNotEmpty)
                            CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => _ArtistHeroFallback(artist: artist),
                            )
                          else _ArtistHeroFallback(artist: artist),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withAlpha(35),
                                  Colors.black.withAlpha(110),
                                  Theme.of(context).colorScheme.surface,
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(36),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: Colors.white.withAlpha(40)),
                                  ),
                                  child: Text(
                                    artist.artistType == ArtistType.SpotifyArtist ? 'Spotify Artist' : 'Nest Artist',
                                    style: const TextStyle(
                                      fontFamily: 'SpotifyMixUI',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  artist.name,
                                  style: const TextStyle(
                                    fontFamily: 'SpotifyMixUI',
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'SpotifyMixUI',
                                    fontSize: 13,
                                    color: Colors.white.withAlpha(210),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                leading: IconButton(
                  onPressed: context.pop,
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilledButton.tonal(
                      onPressed: _isUpdatingFollow ? null : () => _toggleFollow(artist),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black.withAlpha(70),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(followState ? 'Following' : 'Follow', style: const TextStyle(fontFamily: 'SpotifyMixUI', fontWeight: FontWeight.w700))
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _InfoPill(
                            icon: HugeIcons.strokeRoundedStar,
                            label: artist.artistType == ArtistType.SpotifyArtist
                                ? 'Popularity ${artist.popularity}/100'
                                : 'Popularity pending',
                          ),
                          _InfoPill(icon: HugeIcons.strokeRoundedMusicNote01, label: '${tracks.length} tracks'),
                          _InfoPill(
                            icon: followState ? HugeIcons.strokeRoundedTickDouble01 : HugeIcons.strokeRoundedUserAdd02,
                            label: followState ? 'Currently following' : 'Not following yet',
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'About',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(fontFamily: 'SpotifyMixUI', fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(summaryText, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45)),
                      if (artist.artistType == ArtistType.NestArtist) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Nest artist metadata is not implemented in the database yet, so this page uses temporary profile info and focuses on the linked tracks.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tracks',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(fontFamily: 'SpotifyMixUI', fontWeight: FontWeight.w800),
                      ),
                      if (tracks.isNotEmpty)
                        Text(
                          '${tracks.length} available',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ),
              if (tracks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        widget.args.normalizedArtistId.isEmpty
                            ? 'No track list yet because this artist does not have a stored artist id.'
                            : 'No tracks found for this artist id yet.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                )
              else
                SliverList.builder(
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: TrackTile(
                        track: track,
                        currentTrackId: currentTrackId,
                        onTap: () => AudioHelper.playTrackFromList(ref, allTracks: tracks, selectedIndex: index),
                        onLongPress: () => _showTrackOptions(track),
                      ),
                    );
                  },
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 240)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleFollow(Artist artist) async {
    setState(() => _isUpdatingFollow = true);
    try {
      final message = await ref.read(artistServiceProvider).toggleFollowArtist(artist.id, artist.artistType);
      final nextStatus = await ref.read(artistServiceProvider).getFollowStatus(artist.id);
      if (!mounted) return;
      setState(() => _followOverride = nextStatus);
      Fluttertoast.showToast(msg: message);
    } finally {
      if (mounted) {
        setState(() => _isUpdatingFollow = false);
      }
    }
  }

  void _showTrackOptions(Track track) {
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

class _InfoPill extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontFamily: 'SpotifyMixUI', fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ArtistHeroFallback extends StatelessWidget {
  final Artist artist;

  const _ArtistHeroFallback({required this.artist});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
            Theme.of(context).colorScheme.surfaceContainerHigh,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: artist.artistType == ArtistType.SpotifyArtist
                  ? HugeIcons.strokeRoundedMic01
                  : HugeIcons.strokeRoundedUserCircle,
              size: 64,
            ),
            const SizedBox(height: 12),
            Text(
              artist.name,
              style: const TextStyle(fontFamily: 'SpotifyMixUI', fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtistErrorScaffold extends StatelessWidget {
  final String message;

  const _ArtistErrorScaffold({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: context.pop)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Unable to load artist details.\n$message',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
