import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/playlist_provider.dart';
import 'package:flutter_ai_music/ui/web/components/web_album_card.dart';
import 'package:flutter_ai_music/ui/web/components/web_track_row.dart';
import 'package:flutter_ai_music/ui/web/providers/web_data_providers.dart';
import 'package:flutter_ai_music/utils/audio_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WebLibraryPage extends ConsumerWidget {
  const WebLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final playlistsAsync = ref.watch(webPlaylistsProvider);
    final favouritesAsync = ref.watch(webFavouriteTracksProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Library', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text(
                        'Your saved songs, generated sessions, and playlist drafts.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _createPlaylist(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Create playlist'),
                ),
              ],
            ),
          ),
        ),
        playlistsAsync.when(
          data: (playlists) => playlists.isEmpty
              ? const SliverToBoxAdapter(
                  child: SizedBox(height: 180, child: _InlineMessage(message: 'Create a playlist to see it here.')),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisExtent: 236,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      return WebAlbumCard(
                        imageUrl: playlist.photoUrl ?? '',
                        title: playlist.name,
                        subtitle: '${playlist.trackIds.length} tracks',
                        onTap: () => context.push('/playlist/${playlist.id}'),
                      );
                    },
                    itemCount: playlists.length,
                  ),
                ),
          loading: () => const SliverToBoxAdapter(
            child: SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
          ),
          error: (error, _) => const SliverToBoxAdapter(
            child: SizedBox(height: 180, child: _InlineMessage(message: 'Could not load playlists.')),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 30, 28, 12),
            child: Text('Pinned songs', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          ),
        ),
        favouritesAsync.when(
          data: (tracks) => tracks.isEmpty
              ? const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _InlineMessage(message: 'Songs you like will appear here.'),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
                  sliver: SliverList.separated(
                    itemBuilder: (context, index) => WebTrackRow(
                      track: tracks[index],
                      index: index,
                      onTap: () => _playTracks(ref, tracks, index),
                      trailing: IconButton(
                        onPressed: () => _toggleFavourite(context, ref, tracks[index]),
                        icon: const Icon(Icons.favorite),
                        tooltip: 'Remove from favorites',
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
            child: _InlineMessage(message: 'Could not load liked songs.'),
          ),
        ),
      ],
    );
  }

  Future<void> _playTracks(WidgetRef ref, List<Track> tracks, int index) async {
    await AudioHelper.playTrackFromList(ref, allTracks: tracks, selectedIndex: index);
  }

  Future<void> _toggleFavourite(BuildContext context, WidgetRef ref, Track track) async {
    final result = await ref.read(playlistServiceProvider).toggleTrackToFavourite(track.id);
    ref.invalidate(webFavouriteTracksProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result == 'added' ? 'Added to favorites' : 'Removed from favorites')));
  }

  Future<void> _createPlaylist(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Playlist name'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(controller.text), child: const Text('Create')),
        ],
      ),
    );
    controller.dispose();

    final trimmedName = name?.trim();
    if (trimmedName == null || trimmedName.isEmpty) return;

    final playlist = await ref.read(playlistServiceProvider).createPlaylist(trimmedName);
    ref.invalidate(webPlaylistsProvider);
    if (!context.mounted) return;
    context.push('/playlist/${playlist.id}');
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
