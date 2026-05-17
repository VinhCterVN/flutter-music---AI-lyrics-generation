import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';

class WebTrackRow extends StatelessWidget {
  const WebTrackRow({super.key, required this.track, required this.index, this.trailing, this.onTap});

  final Track track;
  final int index;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = track.images.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '${index + 1}',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: hasImage
                  ? CachedNetworkImage(
                      imageUrl: track.images.first,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _FallbackArtwork(theme: theme),
                    )
                  : _FallbackArtwork(theme: theme),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artistName ?? track.artistId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              _durationLabel(index),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            trailing ?? const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  String _durationLabel(int value) {
    final minutes = 2 + value % 3;
    final seconds = 18 + (value * 11) % 42;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _FallbackArtwork extends StatelessWidget {
  const _FallbackArtwork({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.music_note, size: 20, color: theme.colorScheme.onSurfaceVariant),
    );
  }
}
