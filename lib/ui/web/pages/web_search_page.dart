import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/ui/web/components/web_album_card.dart';
import 'package:flutter_ai_music/ui/web/components/web_track_row.dart';
import 'package:flutter_ai_music/utils/audio_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WebSearchPage extends ConsumerWidget {
  const WebSearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final query = ref.watch(trackSearchQueryProvider);
    final tracksAsync = ref.watch(trackSearchProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Search', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 18),
                tracksAsync.maybeWhen(
                  data: (tracks) {
                    final genres = _genresFromTracks(tracks);
                    if (genres.isEmpty) return const SizedBox.shrink();
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: genres.take(10).map((genre) {
                        final selected = query == genre;
                        return ActionChip(
                          avatar: const Icon(Icons.tag, size: 16),
                          label: Text(genre),
                          backgroundColor: selected ? theme.colorScheme.primaryContainer : null,
                          onPressed: () => ref.read(trackSearchQueryProvider.notifier).state = genre,
                        );
                      }).toList(),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 14),
            child: Text('Top results', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 250,
            child: tracksAsync.when(
              data: (tracks) => _TopResultCards(
                tracks: tracks.take(7).toList(),
                onTrackTap: (index) => _playTracks(ref, tracks, index),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => const _InlineMessage(message: 'Search results could not load.'),
            ),
          ),
        ),
        tracksAsync.when(
          data: (tracks) => tracks.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: _InlineMessage(
                    message: query.isEmpty ? 'No tracks available yet.' : 'No tracks match "$query".',
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 36),
                  sliver: SliverList.separated(
                    itemBuilder: (context, index) => WebTrackRow(
                      track: tracks[index],
                      index: index,
                      onTap: () => _playTracks(ref, tracks, index),
                      trailing: IconButton(
                        onPressed: () => AudioHelper.addTracksToQueue(ref, tracks: [tracks[index]]),
                        icon: const Icon(Icons.add),
                        tooltip: 'Add to queue',
                      ),
                    ),
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.24)),
                    itemCount: tracks.length,
                  ),
                ),
          loading: () =>
              const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator())),
          error: (error, _) => const SliverFillRemaining(
            hasScrollBody: false,
            child: _InlineMessage(message: 'Search results could not load.'),
          ),
        ),
      ],
    );
  }

  List<String> _genresFromTracks(List<Track> tracks) {
    final genres = <String>{};
    for (final track in tracks) {
      genres.addAll(track.genres.where((genre) => genre.trim().isNotEmpty));
    }
    return genres.toList()..sort();
  }

  Future<void> _playTracks(WidgetRef ref, List<Track> tracks, int index) async {
    await AudioHelper.playTrackFromList(ref, allTracks: tracks, selectedIndex: index);
  }
}

class _TopResultCards extends StatelessWidget {
  const _TopResultCards({required this.tracks, required this.onTrackTap});

  final List<Track> tracks;
  final ValueChanged<int> onTrackTap;

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return const _InlineMessage(message: 'No top results yet.');
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

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message});

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
