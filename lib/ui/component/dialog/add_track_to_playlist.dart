import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/playlist.dart';
import 'package:flutter_ai_music/provider/playlist_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddTrackToPlaylist extends ConsumerStatefulWidget {
  final int trackId;

  const AddTrackToPlaylist({super.key, required this.trackId});

  @override
  ConsumerState<AddTrackToPlaylist> createState() => _AddTrackToPlaylistState();
}

class _AddTrackToPlaylistState extends ConsumerState<AddTrackToPlaylist> {
  bool _isLoading = true;
  List<Playlist> _playlists = [];
  Set<String> _addedPlaylistIds = {};
  bool _isFavourite = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchPlaylists();
    });
  }

  Future<void> fetchPlaylists() async {
    final playlistProvider = ref.read(playlistServiceProvider);
    final res = await playlistProvider.getPlaylists();

    // Check which playlists already contain this track
    final addedIds = <String>{};
    for (final playlist in res) {
      if (playlist.containsTrack(widget.trackId)) {
        addedIds.add(playlist.id);
      }
    }

    setState(() {
      _playlists = res;
      _addedPlaylistIds = addedIds;
      _isLoading = false;
    });
  }

  Future<void> _togglePlaylist(Playlist playlist) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final playlistService = ref.read(playlistServiceProvider);
    final isAdded = _addedPlaylistIds.contains(playlist.id);

    try {
      if (isAdded) {
        await playlistService.removeTrackFromPlaylist(playlist.id, widget.trackId);
        setState(() {
          _addedPlaylistIds.remove(playlist.id);
        });
      } else {
        await playlistService.addTrackToPlaylist(playlist.id, widget.trackId);
        setState(() {
          _addedPlaylistIds.add(playlist.id);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Có lỗi xảy ra: $e')));
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _toggleFavourite() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final res = await ref.read(playlistServiceProvider).toggleTrackToFavourite(widget.trackId);
      setState(() {
        _isFavourite = res == 'added';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Có lỗi xảy ra: $e')));
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _createNewPlaylist() {
    // TODO: Implement create new playlist dialog
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đã lưu vào',
                    style: TextStyle(
                      fontFamily: 'SpotifyMixUI',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: _createNewPlaylist,
                    child: Text(
                      'Danh sách phát mới',
                      style: TextStyle(
                        fontFamily: 'SpotifyMixUI',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            if (_isLoading)
              const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Favourite option
                      _PlaylistTile(
                        name: 'Bài hát đã thích',
                        trackCount: null,
                        isAdded: _isFavourite,
                        isFavourite: true,
                        onTap: _toggleFavourite,
                        isProcessing: _isProcessing,
                      ),

                      const Divider(height: 1),

                      // Playlist list
                      ..._playlists.map(
                        (playlist) => _PlaylistTile(
                          name: playlist.name,
                          trackCount: playlist.trackIds.length,
                          photoUrl: playlist.photoUrl,
                          isAdded: _addedPlaylistIds.contains(playlist.id),
                          onTap: () => _togglePlaylist(playlist),
                          isProcessing: _isProcessing,
                        ),
                      ),

                      // Create new playlist option
                      _CreatePlaylistTile(onTap: _createNewPlaylist),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  final String name;
  final int? trackCount;
  final String? photoUrl;
  final bool isAdded;
  final bool isFavourite;
  final VoidCallback onTap;
  final bool isProcessing;

  const _PlaylistTile({
    required this.name,
    required this.trackCount,
    this.photoUrl,
    required this.isAdded,
    this.isFavourite = false,
    required this.onTap,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: isFavourite
              ? const Color(0xFF1DB954) // Spotify green
              : colorScheme.surfaceContainerHighest,
          image: photoUrl != null ? DecorationImage(image: NetworkImage(photoUrl!), fit: BoxFit.cover) : null,
        ),
        child: isFavourite
            ? const Icon(Icons.favorite, color: Colors.white, size: 24)
            : photoUrl == null
            ? Icon(Icons.music_note, color: colorScheme.onSurfaceVariant)
            : null,
      ),
      title: Text(
        name,
        style: TextStyle(
          fontFamily: 'SpotifyMixUI',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: trackCount != null
          ? Text(
              '$trackCount bài hát',
              style: TextStyle(fontFamily: 'SpotifyMixUI', fontSize: 13, color: colorScheme.onSurfaceVariant),
            )
          : null,
      trailing: _StatusButton(isAdded: isAdded, onTap: onTap, isProcessing: isProcessing),
      onTap: onTap,
    );
  }
}

class _StatusButton extends StatelessWidget {
  final bool isAdded;
  final VoidCallback onTap;
  final bool isProcessing;

  const _StatusButton({required this.isAdded, required this.onTap, required this.isProcessing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isProcessing) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(colorScheme.primary)),
      );
    }

    if (isAdded) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.primary),
        child: const Icon(Icons.check, size: 18, color: Colors.white),
      );
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.onSurfaceVariant.withOpacity(0.5), width: 2),
      ),
      child: Icon(Icons.add, size: 18, color: colorScheme.onSurfaceVariant),
    );
  }
}

class _CreatePlaylistTile extends StatelessWidget {
  final VoidCallback onTap;

  const _CreatePlaylistTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: colorScheme.surfaceContainerHighest),
        child: Icon(Icons.add, color: colorScheme.onSurfaceVariant, size: 28),
      ),
      title: Text(
        'Danh sách phát mới',
        style: TextStyle(
          fontFamily: 'SpotifyMixUI',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),
      onTap: onTap,
    );
  }
}
