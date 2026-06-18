import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/audio_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

class QueueBottomSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const QueueBottomSheet({super.key, required this.scrollController});

  @override
  ConsumerState<QueueBottomSheet> createState() => _QueueBottomSheetState();
}

class _QueueBottomSheetState extends ConsumerState<QueueBottomSheet> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(queueProvider);
    final currentTrack = ref.watch(currentTrackProvider).value;
    final scheme = Theme.of(context).colorScheme;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final imageSize = (48 * dpr).round();

    final currentIndex = queue.currentIndex;
    final upcoming = <int>[for (var i = currentIndex + 1; i < queue.tracks.length; i++) i];

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Sheet title
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
            child: Row(
              children: [
                Text(
                  'Queue',
                  style: TextStyle(color: scheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),

          // Now playing card
          if (currentTrack != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _NowPlayingCard(track: currentTrack, imageSize: imageSize, scheme: scheme),
            ),

          const SizedBox(height: 20),

          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  'Next in queue',
                  style: TextStyle(color: scheme.onSurface, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Text(
                  '${upcoming.length}',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Queue list
          Flexible(
            child: upcoming.isEmpty
                ? _EmptyQueue(scheme: scheme, controller: widget.scrollController)
                : ReorderableListView.builder(
                    scrollController: widget.scrollController,
                    key: const Key('queue_list'),
                    padding: const EdgeInsets.only(top: 4, bottom: 16),
                    buildDefaultDragHandles: false,
                    itemCount: upcoming.length,
                    onReorder: (oldIndex, newIndex) {
                      // ReorderableListView reports newIndex assuming the item is
                      // still present; adjust to the post-removal target index.
                      if (newIndex > oldIndex) newIndex -= 1;
                      if (oldIndex == newIndex) return;
                      final base = currentIndex + 1;
                      ref.read(playerControllerProvider).reorderQueue(oldIndex + base, newIndex + base);
                    },
                    itemBuilder: (context, i) {
                      final realIndex = upcoming[i];
                      final source = queue.tracks[realIndex] as UriAudioSource;
                      final tag = source.tag as Map<String, Object>;
                      return _QueueItem(
                        key: ValueKey(tag['id']),
                        index: i,
                        tag: tag,
                        imageSize: imageSize,
                        scheme: scheme,
                        onTap: () => ref.read(audioPlayerProvider).seek(Duration.zero, index: realIndex),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NowPlayingCard extends StatelessWidget {
  final Track track;
  final int imageSize;
  final ColorScheme scheme;

  const _NowPlayingCard({required this.track, required this.imageSize, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: track.images.first,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              memCacheWidth: imageSize,
              memCacheHeight: imageSize,
              maxWidthDiskCache: imageSize,
              maxHeightDiskCache: imageSize,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOW PLAYING',
                  style: TextStyle(color: scheme.primary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  track.name,
                  style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 17, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  track.artistName ?? track.artistType.name,
                  style: TextStyle(color: scheme.onPrimaryContainer.withAlpha(180), fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.equalizer_rounded, color: scheme.primary, size: 26),
        ],
      ),
    );
  }
}

class _QueueItem extends StatelessWidget {
  final int index;
  final Map<String, Object> tag;
  final int imageSize;
  final ColorScheme scheme;
  final VoidCallback onTap;

  const _QueueItem({
    super.key,
    required this.index,
    required this.tag,
    required this.imageSize,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: (tag["images"] as List<String>).first,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                memCacheWidth: imageSize,
                memCacheHeight: imageSize,
                maxWidthDiskCache: imageSize,
                maxHeightDiskCache: imageSize,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tag["title"] as String? ?? 'Unknown',
                    style: TextStyle(color: scheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (tag["artistName"] as String?) ?? ArtistType.SpotifyArtist.name,
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Icon(Icons.drag_handle_rounded, color: scheme.onSurfaceVariant.withAlpha(150)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  final ColorScheme scheme;
  final ScrollController controller;

  const _EmptyQueue({required this.scheme, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 48),
          child: Column(
            children: [
              Icon(Icons.queue_music_rounded, color: scheme.onSurfaceVariant.withAlpha(120), size: 40),
              const SizedBox(height: 12),
              Text('Nothing queued up next', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
