import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/playlist.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';

class PlaylistItem extends ConsumerStatefulWidget {
  const PlaylistItem({
    super.key,
    required this.playlist,
    required this.isSelected,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.onTap,
    required this.onLongPress,
    required this.onConfirmDelete,
  });

  final Playlist playlist;
  final bool isSelected;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Future<bool?> Function() onConfirmDelete;

  @override
  ConsumerState<PlaylistItem> createState() => _PlaylistItemState();
}

class _PlaylistItemState extends ConsumerState<PlaylistItem> {
  final Color spotifyGreen = const Color(0xFF1DB954);
  String _photoUrl = "";
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPhotoUrl();
  }

  Future<void> _loadPhotoUrl() async {
    if (widget.playlist.photoUrl != null) {
      setState(() => _photoUrl = widget.playlist.photoUrl!);
      return;
    }
    if (widget.playlist.trackIds.isEmpty) {
      setState(() => _photoUrl = "https://i.pravatar.cc/300?u=${widget.playlist.id}");
      return;
    }
    final track = await ref.read(trackServiceProvider).getTracksByIds([widget.playlist.trackIds.first.toString()]);
    if (!mounted) return;
    setState(() => _photoUrl = track.first.images.first);
  }

  @override
  Widget build(BuildContext context) {
    Color trashColor = Color.fromARGB((_progress * 255 * 2).clamp(100, 255).toInt(), 255, 0, 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Dismissible(
        key: Key(widget.playlist.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => widget.onConfirmDelete(),
        onUpdate: (details) => setState(() => _progress = details.progress),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: HugeIcon(icon: HugeIconsStrokeRounded.delete03, size: 24, color: trashColor, strokeWidth: 1.5),
        ),
        child: Material(
          color: Theme.of(context).colorScheme.surfaceDim,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: CachedNetworkImage(
                        imageUrl: _photoUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.music_note, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.playlist.name,
                          style: widget.titleStyle.copyWith(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${widget.playlist.trackIds.length} tracks",
                          style: widget.subtitleStyle.copyWith(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  ClipOval(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        key: ValueKey(widget.isSelected),
                        padding: const EdgeInsets.all(4),
                        color: widget.isSelected ? spotifyGreen : Colors.grey[800],
                        child: HugeIcon(
                          icon: widget.isSelected
                              ? HugeIconsStrokeRounded.checkmarkCircle03
                              : HugeIconsStrokeRounded.add01,
                          size: 16,
                          color: widget.isSelected ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
