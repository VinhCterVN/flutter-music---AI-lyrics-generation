import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/ui/web/components/web_album_card.dart';
import 'package:flutter_ai_music/ui/web/components/web_track_row.dart';
import 'package:flutter_ai_music/utils/audio_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WebHomePage extends ConsumerWidget {
  const WebHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final discovery = ref.watch(homeDiscoveryProvider);
    final featured = ref.watch(featuredTracksProvider(12));
    final recent = ref.watch(recentTracksProvider(12));
    final discoveryData = discovery.asData?.value;
    final discoveryTracks = discoveryData?.suggestedTracks ?? const <Track>[];
    final featuredTracks = featured.asData?.value ?? discoveryTracks;
    final recentTracks = recent.asData?.value ?? discoveryData?.topListenedTracks ?? const <Track>[];
    final liveTrack = (discoveryTracks.isNotEmpty ? discoveryTracks : featuredTracks).firstOrNull;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 900;
                final hero = _HeroPanel(
                  theme: theme,
                  onPlayDiscovery: discoveryTracks.isEmpty ? null : () => _playTracks(ref, discoveryTracks, 0),
                  onTuneMood: () => context.go('/search'),
                );
                final liveMix = _LiveMixPanel(
                  theme: theme,
                  track: liveTrack,
                  onTap: liveTrack == null ? null : () => _playTracks(ref, [liveTrack], 0),
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      hero,
                      const SizedBox(height: 18),
                      SizedBox(height: 320, child: liveMix),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 7, child: hero),
                    const SizedBox(width: 18),
                    Expanded(flex: 3, child: liveMix),
                  ],
                );
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _SectionHeader(title: 'Featured shelves', action: 'View all', onAction: () => context.go('/search')),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 250,
            child: featured.when(
              data: (_) => _HorizontalTrackCards(
                tracks: featuredTracks,
                onTrackTap: (index) => _playTracks(ref, featuredTracks, index),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _InlineError(message: 'Could not load featured tracks'),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: 'Recent tracks',
            action: 'Open list',
            onAction: () => context.push('/recent-tracks'),
          ),
        ),
        recent.when(
          data: (_) => recentTracks.isEmpty
              ? const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(message: 'Play a few tracks to build your recent list.'),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
                  sliver: SliverList.separated(
                    itemBuilder: (context, index) => WebTrackRow(
                      track: recentTracks[index],
                      index: index,
                      onTap: () => _playTracks(ref, recentTracks, index),
                      trailing: IconButton(
                        onPressed: () => AudioHelper.addTracksToQueue(ref, tracks: [recentTracks[index]]),
                        icon: const Icon(Icons.add),
                        tooltip: 'Add to queue',
                      ),
                    ),
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.24)),
                    itemCount: recentTracks.length,
                  ),
                ),
          loading: () =>
              const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator())),
          error: (error, _) => const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(message: 'Could not load recent tracks.'),
          ),
        ),
      ],
    );
  }

  Future<void> _playTracks(WidgetRef ref, List<Track> tracks, int index) async {
    await AudioHelper.playTrackFromList(ref, allTracks: tracks, selectedIndex: index);
  }
}

class _HorizontalTrackCards extends StatelessWidget {
  const _HorizontalTrackCards({required this.tracks, required this.onTrackTap});

  final List<Track> tracks;
  final ValueChanged<int> onTrackTap;

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return const _EmptyState(message: 'No featured tracks yet.');
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return WebAlbumCard(
          imageUrl: track.images.firstOrNull ?? '',
          title: track.name,
          subtitle: track.artistName ?? track.artistId,
          onTap: () => onTrackTap(index),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(width: 14),
      itemCount: tracks.length,
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.theme, required this.onPlayDiscovery, required this.onTuneMood});

  final ThemeData theme;
  final VoidCallback? onPlayDiscovery;
  final VoidCallback onTuneMood;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 280),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.82),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.48),
            theme.colorScheme.surfaceContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today on Flussic',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              'Build a playlist from the mood you already have.',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: onPlayDiscovery,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play discovery'),
              ),
              OutlinedButton.icon(onPressed: onTuneMood, icon: const Icon(Icons.tune), label: const Text('Tune mood')),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveMixPanel extends StatelessWidget {
  const _LiveMixPanel({required this.theme, required this.track, required this.onTap});

  final ThemeData theme;
  final Track? track;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 280),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live Mix', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: track?.images.firstOrNull == null
                    ? Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.music_note, color: theme.colorScheme.onSurfaceVariant),
                      )
                    : Image.network(track!.images.first, fit: BoxFit.cover, width: double.infinity),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              track?.name ?? 'Nothing queued yet',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              track?.artistName ?? track?.artistId ?? 'Start discovery to pick a mix',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action, required this.onAction});

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 14),
      child: Row(
        children: [
          Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const Spacer(),
          TextButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
