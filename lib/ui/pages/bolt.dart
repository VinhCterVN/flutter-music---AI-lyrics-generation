import 'dart:async';

import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import '../component/element/bolt_widgets.dart';
import '../theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/track.dart';
import '../../provider/audio_provider.dart';
import '../../provider/discovery_provider.dart';
import '../../provider/playlist_provider.dart';
import '../../provider/track_provider.dart';
import '../../utils/audio_helper.dart';
import '../component/dialog/add_track_to_playlist.dart';

class BoltPage extends ConsumerStatefulWidget {
  const BoltPage({super.key});
  @override
  ConsumerState<BoltPage> createState() => _BoltPageState();
}

class _BoltPageState extends ConsumerState<BoltPage> {
  String? _genre;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tracks = ref.watch(discoveryTracksProvider(_genre));
    final genres = ref.watch(allGenresProvider);
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        key: const PageStorageKey('bolt-discovery'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      HugeIcon(
                        icon: HugeIconsStrokeRounded.flash,
                        color: scheme.onSurface,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bolt',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontFamily: appFontFamily,
                              letterSpacing: -0.8,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Find your next favorite.',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Something new. One track at a time.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _filter('Surprise me', null),
                  ...?genres.value?.map((genre) => _filter(genre, genre)),
                  if (genres.hasError)
                    BoltControl(
                      label: 'Retry genres',
                      onTap: () => ref.invalidate(allGenresProvider),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 180),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: tracks.when(
                    skipLoadingOnRefresh: false,
                    data: (items) => items.isEmpty
                        ? _DeckMessage(
                            title: 'No discoveries here yet',
                            message:
                                'Try another genre or check back for more music.',
                            action: 'Try again',
                            onAction: _refresh,
                          )
                        : _DiscoveryDeck(
                            key: ObjectKey(items),
                            tracks: items,
                            onRefresh: _refresh,
                          ),
                    loading: () => const BoltSkeleton(),
                    error: (_, _) => _DeckMessage(
                      title: 'Couldn’t load your discoveries',
                      message: 'Check your connection and give it another try.',
                      action: 'Retry',
                      onAction: _refresh,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _refresh() => ref.invalidate(discoveryTracksProvider(_genre));

  Widget _filter(String label, String? genre) => Padding(
    padding: const EdgeInsets.only(right: 20),
    child: BoltControl(
      label: label,
      tab: true,
      selected: _genre == genre,
      onTap: () => setState(() => _genre = genre),
    ),
  );
}

class _DiscoveryDeck extends ConsumerStatefulWidget {
  const _DiscoveryDeck({
    super.key,
    required this.tracks,
    required this.onRefresh,
  });
  final List<Track> tracks;
  final VoidCallback onRefresh;
  @override
  ConsumerState<_DiscoveryDeck> createState() => _DiscoveryDeckState();
}

class _DiscoveryDeckState extends ConsumerState<_DiscoveryDeck> {
  int _index = 0;
  bool _saving = false;
  bool _startingPlayback = false;
  final Map<int, bool> _likes = {};

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _toggleLike(Track track) async {
    setState(() => _saving = true);
    try {
      final result = await ref
          .read(playlistServiceProvider)
          .toggleTrackToFavourite(track.id);
      if (!mounted) return;
      final liked = result == 'added';
      setState(() => _likes[track.id] = liked);
      ref.invalidate(likedTracksProvider);
      final queue = ref.read(queueProvider);
      for (var i = 0; i < queue.rawTracks.length; i++) {
        if (queue.rawTracks[i].id == track.id) {
          ref
              .read(queueProvider.notifier)
              .updateTrackAtIndex(
                i,
                queue.rawTracks[i].copyWith(isFavorite: liked),
              );
        }
      }
      _message(liked ? 'Added to liked songs' : 'Removed from liked songs');
    } catch (_) {
      _message('Couldn’t update liked songs. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _play(Track track) async {
    setState(() => _startingPlayback = true);
    try {
      if (ref.read(currentTrackProvider).value?.id == track.id) {
        if (ref.read(isPlayingProvider).value == true) {
          await AudioHelper.pausePlayback(ref);
        } else {
          // play() completes when playback ends, not when it starts.
          unawaited(
            AudioHelper.resumePlayback(ref).catchError((Object _) {
              _message('Couldn’t play this track. Please try again.');
            }),
          );
        }
      } else {
        await AudioHelper.playSingleTrack(
          ref,
          track: track.copyWith(
            isFavorite: _likes[track.id] ?? track.isFavorite,
          ),
        );
      }
    } catch (_) {
      _message('Couldn’t play this track. Please try again.');
    } finally {
      if (mounted) setState(() => _startingPlayback = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(isPlayingProvider, (_, next) {
      if (_startingPlayback && next.value == true) {
        setState(() => _startingPlayback = false);
      }
    });
    ref.listen(isBufferingProvider, (_, next) {
      // Replacing a playing track may keep `playing` true throughout loading.
      if (_startingPlayback && next.value == false) {
        setState(() => _startingPlayback = false);
      }
    });
    if (_index >= widget.tracks.length) {
      return _DeckMessage(
        title: 'That’s this deck explored',
        message: 'Load another mix or pick a different genre.',
        action: 'Discover more',
        onAction: widget.onRefresh,
      );
    }
    final track = widget.tracks[_index];
    final scheme = Theme.of(context).colorScheme;
    final current = ref.watch(currentTrackProvider).value;
    final playing =
        ref.watch(isPlayingProvider).value == true && current?.id == track.id;
    final queuedLike = ref
        .watch(queueProvider)
        .rawTracks
        .where((item) => item.id == track.id)
        .firstOrNull
        ?.isFavorite;
    final liked = _likes[track.id] ?? queuedLike ?? track.isFavorite;
    final busy = _saving || _startingPlayback;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'YOUR DISCOVERY DECK',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${_index + 1} / ${widget.tracks.length}',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 220),
          child: BoltArtwork(
            key: ValueKey(track.id),
            imageUrl: track.images.firstOrNull,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          track.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            fontFamily: appFontFamily,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          track.artistName ?? 'Unknown artist',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16),
        ),
        if (track.genres.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            track.genres.take(3).join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BoltControl(
              label: liked ? 'Unlike' : 'Like',
              icon: HugeIconsStrokeRounded.favourite,
              selected: liked,
              iconOnly: true,
              onTap: busy ? null : () => _toggleLike(track),
            ),
            const SizedBox(width: 24),
            BoltControl(
              label: _startingPlayback
                  ? 'Loading…'
                  : playing
                  ? 'Pause'
                  : 'Play',
              icon: playing
                  ? HugeIconsStrokeRounded.pause
                  : HugeIconsStrokeRounded.play,
              prominent: true,
              iconOnly: true,
              onTap: busy ? null : () => _play(track),
            ),
            const SizedBox(width: 24),
            BoltControl(
              label: 'Add to playlist',
              icon: HugeIconsStrokeRounded.musicNoteSquare02,
              iconOnly: true,
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.all(16),
                  child: AddToPlaylistScreen(
                    trackId: track.id,
                    trackName: track.name,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        BoltControl(
          label: 'Next discovery',
          icon: HugeIconsStrokeRounded.arrowRight02,
          onTap: busy ? null : () => setState(() => _index++),
        ),
        const SizedBox(height: 12),
        Text(
          'Browse freely. Play when you’re ready.',
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
        ),
      ],
    );
  }
}

class _DeckMessage extends StatelessWidget {
  const _DeckMessage({
    required this.title,
    required this.message,
    required this.action,
    required this.onAction,
  });
  final String title;
  final String message;
  final String action;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 56),
    child: Column(
      children: [
        HugeIcon(
          icon: HugeIconsStrokeRounded.flash,
          size: 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        BoltControl(
          label: action,
          onTap: onAction,
          icon: HugeIconsStrokeRounded.arrowRight02,
        ),
      ],
    ),
  );
}
