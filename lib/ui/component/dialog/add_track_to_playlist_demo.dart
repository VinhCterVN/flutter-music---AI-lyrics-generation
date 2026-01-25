import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/playlist.dart';
import 'package:flutter_ai_music/provider/playlist_provider.dart';
import 'package:flutter_ai_music/ui/component/element/create_playlist_section.dart';
import 'package:flutter_ai_music/ui/component/element/playlist_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';

enum PlaylistSortType { aToZ, zToA, newest, oldest, mostTracks }

class AddToPlaylistScreen extends ConsumerStatefulWidget {
  final int trackId;
  final String trackName;

  const AddToPlaylistScreen({super.key, required this.trackId, required this.trackName});

  @override
  ConsumerState<AddToPlaylistScreen> createState() => _AddToPlaylistScreenState();
}

class _AddToPlaylistScreenState extends ConsumerState<AddToPlaylistScreen> {
  final ScrollController _controller = ScrollController();
  final GlobalKey _buttonKey = GlobalKey();

  List<Playlist> _playlists = [];
  PlaylistSortType _currentSortType = PlaylistSortType.aToZ;

  final Set<String> _initialPlaylistIds = {};
  final Set<String> _selectedPlaylistIds = {};

  bool _isLoading = true;
  bool _isCreating = false;
  bool _buttonVisible = true;
  final TextEditingController _newPlaylistController = TextEditingController();

  static const Color _spotifyGreen = Color(0xFF1DB954);
  static const String _fontFamily = 'SpotifyMixUI';

  @override
  void initState() {
    super.initState();
    _fetchPlaylistData();
  }

  @override
  void dispose() {
    _newPlaylistController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchPlaylistData() async {
    final service = ref.read(playlistServiceProvider);
    final playlists = await service.getPlaylists();
    _sortPlaylistsByType(playlists, _currentSortType);

    if (!mounted) return;

    final initialIds = <String>{};
    for (var p in playlists) {
      if (p.trackIds.contains(widget.trackId)) {
        initialIds.add(p.id);
      }
    }

    setState(() {
      _playlists = playlists;
      _initialPlaylistIds.addAll(initialIds);
      _selectedPlaylistIds.addAll(initialIds);
      _isLoading = false;
    });
  }

  void _toggleTrackInPlaylist(String playlistId) {
    setState(() {
      if (_selectedPlaylistIds.contains(playlistId)) {
        _selectedPlaylistIds.remove(playlistId);
      } else {
        _selectedPlaylistIds.add(playlistId);
      }
    });
  }

  Future<void> _createNewPlaylist() async {
    if (_newPlaylistController.text.isEmpty || !mounted) return;

    final playlist = await ref.read(playlistServiceProvider).createPlaylist(_newPlaylistController.text);
    setState(() {
      _playlists.insert(0, playlist);
      // _selectedPlaylistIds.add(playlist.id);
      _initialPlaylistIds.add(playlist.id);
      _isCreating = false;
      _newPlaylistController.clear();
    });
  }

  void _sortPlaylistsByType(List<Playlist> playlists, PlaylistSortType sortType) {
    switch (sortType) {
      case PlaylistSortType.aToZ:
        playlists.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case PlaylistSortType.zToA:
        playlists.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
      case PlaylistSortType.newest:
        playlists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case PlaylistSortType.oldest:
        playlists.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case PlaylistSortType.mostTracks:
        playlists.sort((a, b) => b.trackIds.length.compareTo(a.trackIds.length));
    }
  }

  String _getSortLabel(PlaylistSortType sortType) {
    return switch (sortType) {
      PlaylistSortType.aToZ => 'A-Z',
      PlaylistSortType.zToA => 'Z-A',
      PlaylistSortType.newest => 'Newest',
      PlaylistSortType.oldest => 'Oldest',
      PlaylistSortType.mostTracks => 'Most Tracks',
    };
  }

  Future<void> _deletePlaylist(Playlist playlist) async {
    try {
      await ref.read(playlistServiceProvider).deletePlaylist(playlist.id);
      setState(() {
        _playlists.removeWhere((p) => p.id == playlist.id);
        _selectedPlaylistIds.remove(playlist.id);
        _initialPlaylistIds.remove(playlist.id);
      });
      Fluttertoast.showToast(msg: 'Playlist "${playlist.name}" deleted');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error deleting playlist: $e');
    }
  }

  Future<void> _onDonePressed() async {
    final service = ref.read(playlistServiceProvider);
    final toAdd = _selectedPlaylistIds.difference(_initialPlaylistIds);
    final toRemove = _initialPlaylistIds.difference(_selectedPlaylistIds);

    if (toAdd.isEmpty && toRemove.isEmpty) {
      Navigator.pop(context);
      return;
    }

    try {
      await Future.wait([
        ...toAdd.map((playlistId) => service.addTrackToPlaylist(playlistId, widget.trackId)),
        ...toRemove.map((playlistId) => service.removeTrackFromPlaylist(playlistId, widget.trackId)),
      ]);

      if (mounted) {
        Fluttertoast.showToast(msg: "Updated playlists");
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(msg: "Error updating playlists: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final double safeMaxHeight = screenHeight - keyboardHeight - 100;
    final double effectiveMaxHeight = math.min(safeMaxHeight, 600);

    final textStyleBold = const TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: Colors.white);
    final textStyleNormal = const TextStyle(fontFamily: _fontFamily, color: Colors.white);

    return Padding(
      padding: _isCreating ? EdgeInsets.only(top: MediaQuery.of(context).padding.top) : EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceDim,
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: BoxConstraints(maxHeight: effectiveMaxHeight > 0 ? effectiveMaxHeight : 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: textStyleBold.copyWith(fontSize: 18),
                        children: [
                          const TextSpan(text: "Adding "),
                          TextSpan(
                            text: widget.trackName,
                            style: const TextStyle(color: Color(0xFF1891FC)),
                          ),
                          const TextSpan(text: " to playlist"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 150),
                    child: (!_buttonVisible && !_isCreating)
                        ? TextButton(
                            onPressed: () {
                              if (_buttonKey.currentContext == null) return;
                              Scrollable.ensureVisible(
                                _buttonKey.currentContext!,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                              setState(() => _isCreating = true);
                            },
                            child: Text(
                              "Create Playlist",
                              style: const TextStyle(
                                fontFamily: "SpotifyMixUI",
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Flexible(
              fit: FlexFit.loose,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                alignment: Alignment.topCenter,
                child: _isLoading
                    ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
                    : ListView(
                        controller: _controller,
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: [
                          CreatePlaylistSection(
                            isCreating: _isCreating,
                            buttonKey: _buttonKey,
                            newPlaylistController: _newPlaylistController,
                            onButtonVisibilityChanged: (visible) {
                              if (!mounted) return;
                              setState(() => _buttonVisible = visible);
                            },
                            onStartCreating: () => setState(() => _isCreating = true),
                            onCancelCreating: () => setState(() => _isCreating = false),
                            onCreatePlaylist: _createNewPlaylist,
                          ),

                          if (_playlists.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.list, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text("Most relevant playlists", style: textStyleBold.copyWith(fontSize: 14)),
                                  const Spacer(),

                                  PopupMenuButton<PlaylistSortType>(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    position: PopupMenuPosition.under,
                                    onSelected: (sortType) {
                                      setState(() {
                                        _currentSortType = sortType;
                                        _sortPlaylistsByType(_playlists, sortType);
                                      });
                                    },
                                    itemBuilder: (context) => PlaylistSortType.values
                                        .map(
                                          (type) => PopupMenuItem(
                                            value: type,
                                            child: Row(
                                              children: [
                                                if (_currentSortType == type)
                                                  const Icon(Icons.check, size: 16)
                                                else
                                                  const SizedBox(width: 16),
                                                const SizedBox(width: 8),
                                                Text(_getSortLabel(type)),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(100),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _getSortLabel(_currentSortType),
                                            style: textStyleNormal.copyWith(fontSize: 12),
                                          ),
                                          const SizedBox(width: 4),
                                          const HugeIcon(icon: HugeIconsStrokeRounded.sortByDown01, size: 16),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Animated playlist list with shuffle effect
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            layoutBuilder: (currentChild, previousChildren) {
                              return Stack(children: [...previousChildren, if (currentChild != null) currentChild]);
                            },
                            child: Column(
                              key: ValueKey(_currentSortType),
                              children: _playlists.asMap().entries.map((entry) {
                                final index = entry.key;
                                final playlist = entry.value;
                                return TweenAnimationBuilder<double>(
                                  key: ValueKey('${playlist.id}_$_currentSortType'),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 300)),
                                  curve: Curves.easeOutBack,
                                  builder: (context, value, child) {
                                    return Transform.translate(
                                      offset: Offset((1 - value) * (index.isEven ? -30 : 30), 0),
                                      child: Opacity(
                                        opacity: value.clamp(0.0, 1.0),
                                        child: Transform.scale(scale: 0.95 + (0.05 * value), child: child),
                                      ),
                                    );
                                  },
                                  child: PlaylistItem(
                                    playlist: playlist,
                                    titleStyle: textStyleBold,
                                    subtitleStyle: textStyleNormal,
                                    isSelected: _selectedPlaylistIds.contains(playlist.id),
                                    onTap: () => _toggleTrackInPlaylist(playlist.id),
                                    onConfirmDelete: () => _showDeleteConfirmDialog(playlist),
                                    onLongPress: () => Fluttertoast.showToast(msg: "Playlist: ${playlist.name}"),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton(
                onPressed: _onDonePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _spotifyGreen,
                  foregroundColor: Colors.black,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                ),
                child: Text("Done", style: textStyleBold.copyWith(color: Colors.black, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmDialog(Playlist playlist) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Delete Playlist',
            style: const TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          content: RichText(
            text: TextSpan(
              style: TextStyle(fontFamily: _fontFamily, color: Colors.white),
              children: [
                const TextSpan(text: 'Are you sure you want to delete the playlist '),
                TextSpan(
                  text: '"${playlist.name}"',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: '? This action cannot be undone.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: const TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context, true);
                await _deletePlaylist(playlist);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Delete',
                style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ) ??
      false;
}
