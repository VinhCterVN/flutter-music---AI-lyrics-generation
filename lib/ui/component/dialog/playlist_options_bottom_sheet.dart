import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ai_music/data/models/playlist.dart';
import 'package:flutter_ai_music/provider/playlist_provider.dart';
import 'package:flutter_ai_music/service/playlist_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';

/// Shows the playlist options bottom sheet and returns when dismissed.
Future<void> showPlaylistOptions(BuildContext context, {required Playlist playlist, String? photoUrl}) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PlaylistOptionsSheet(playlist: playlist, photoUrl: photoUrl),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _PlaylistOptionsSheet extends ConsumerWidget {
  final Playlist playlist;
  final String? photoUrl;

  const _PlaylistOptionsSheet({required this.playlist, this.photoUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final service = ref.read(playlistServiceProvider);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceDim,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ───────────────────────────────────────────────────
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),

          // ── Playlist identity row ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              spacing: 14,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: photoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: photoUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _placeholderArt(),
                          )
                        : _placeholderArt(),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'SpotifyMixUI',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${playlist.trackIds.length} songs',
                        style: TextStyle(fontFamily: 'SpotifyMixUI', fontSize: 13, color: Colors.white.withAlpha(130)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.white12),

          // ── Options list ──────────────────────────────────────────────────
          _Option(
            icon: Icons.play_circle_outline_rounded,
            label: 'Play',
            onTap: () {
              Navigator.pop(context);
              context.push('/playlist/${playlist.id}');
            },
          ),
          _Option(
            icon: Icons.edit_rounded,
            label: 'Rename',
            // Show dialog FIRST (sheet context still alive), pop sheet after
            onTap: () async {
              await _showRenameDialog(context, ref, scheme, service);
              if (context.mounted) Navigator.pop(context);
            },
          ),
          _Option(
            icon: Icons.share_rounded,
            label: 'Share',
            onTap: () {
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'Share feature coming soon!');
            },
          ),
          _Option(
            icon: Icons.queue_music_rounded,
            label: 'Add to queue',
            onTap: () {
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'Add to queue — coming soon!');
            },
          ),
          _Option(
            icon: Icons.copy_rounded,
            label: 'Copy playlist ID',
            onTap: () {
              Clipboard.setData(ClipboardData(text: playlist.id));
              Fluttertoast.showToast(msg: 'Playlist ID copied');
              Navigator.pop(context);
            },
          ),
          _Option(
            icon: Icons.delete_outline_rounded,
            label: 'Delete playlist',
            color: Colors.redAccent.shade100,
            // Show dialog FIRST (sheet context still alive), pop sheet after
            onTap: () async {
              await _showDeleteDialog(context, ref, scheme, service);
              if (context.mounted) Navigator.pop(context);
            },
          ),

          // Safe area bottom padding
          SizedBox(height: MediaQuery.paddingOf(context).bottom + 12),
        ],
      ),
    );
  }

  // ── Rename dialog ─────────────────────────────────────────────────────────
  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref, ColorScheme scheme, PlaylistService service) async {
    final controller = TextEditingController(text: playlist.name);
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: scheme.surfaceDim,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Rename playlist',
          style: TextStyle(fontFamily: 'SpotifyMixUI', fontWeight: FontWeight.w700, color: Colors.white),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(fontFamily: 'SpotifyMixUI', color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Playlist name',
              hintStyle: TextStyle(color: Colors.white.withAlpha(80)),
              filled: true,
              fillColor: Colors.white.withAlpha(15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.greenAccent, width: 1.5),
              ),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Name cannot be empty' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withAlpha(160))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.greenAccent.shade400, foregroundColor: Colors.black),
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text(
              'Save',
              style: TextStyle(fontFamily: 'SpotifyMixUI', fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        debugPrint('Renaming playlist ${playlist.id} to "${controller.text.trim()}"');
        await service.renamePlaylist(playlist.id, controller.text.trim());
        Fluttertoast.showToast(msg: 'Playlist renamed');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Failed to rename: $e');
      }
    }
  }

  // ── Delete dialog ─────────────────────────────────────────────────────────
  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref,ColorScheme scheme, PlaylistService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: scheme.surfaceDim,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete playlist?',
          style: TextStyle(fontFamily: 'SpotifyMixUI', fontWeight: FontWeight.w700, color: Colors.white),
        ),
        content: Text(
          'This will permanently delete "${playlist.name}". This action cannot be undone.',
          style: TextStyle(fontFamily: 'SpotifyMixUI', fontSize: 14, color: Colors.white.withAlpha(160)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withAlpha(160))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(fontFamily: 'SpotifyMixUI', fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await service.deletePlaylist(playlist.id);
        Fluttertoast.showToast(msg: '"${playlist.name}" deleted');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Failed to delete: $e');
      }
    }
  }

  Widget _placeholderArt() => Container(
    color: Colors.grey.shade800,
    child: const Icon(Icons.music_note, color: Colors.white38),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _Option extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _Option({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.white;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          spacing: 16,
          children: [
            Icon(icon, color: effectiveColor, size: 22),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'SpotifyMixUI',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
