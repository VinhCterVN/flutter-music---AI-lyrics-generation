import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/playlist.dart';
import 'package:flutter_ai_music/provider/playlist_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:visibility_detector/visibility_detector.dart';

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
  bool _buttonVisible = true;
  bool _isLoading = true;
  bool _isCreating = false;
  final TextEditingController _newPlaylistController = TextEditingController();

  final Color _spotifyGreen = const Color(0xFF1DB954);
  final String _fontFamily = 'SpotifyMixUI';

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
    playlists.sort((a, b) => a.name.compareTo(b.name));
    if (!mounted) return;
    setState(() {
      _playlists = playlists;
      _isLoading = false;
    });
  }

  void _toggleTrackInPlaylist(String playlistId) {
    setState(() {
      final index = _playlists.indexWhere((p) => p.id == playlistId);
      if (index != -1) {
        // _playlists[index].isContainsTrack = !_playlists[index].isContainsTrack;
      }
    });
  }

  Future<void> _createNewPlaylist() async {
    if (_newPlaylistController.text.isEmpty || !mounted) return;

    final playlist = await ref.read(playlistServiceProvider).createPlaylist(_newPlaylistController.text);
    setState(() {
      _playlists.insert(0, playlist);
      _isCreating = false;
      _newPlaylistController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final double safeMaxHeight = screenHeight - keyboardHeight - 100;
    final double effectiveMaxHeight = math.min(safeMaxHeight, 600);

    final textStyleBold = TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: Colors.white);
    final textStyleNormal = TextStyle(fontFamily: _fontFamily, color: Colors.white);

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
                  if (!_buttonVisible && !_isCreating)
                    TextButton(
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
                        style: const TextStyle(fontFamily: "SpotifyMixUI", fontWeight: FontWeight.bold, fontSize: 12),
                      ),
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 150),
                              child: !_isCreating
                                  ? VisibilityDetector(
                                      key: _buttonKey,
                                      onVisibilityChanged: (info) {
                                        if (!mounted) return;
                                        setState(() {
                                          _buttonVisible = info.visibleFraction > 0;
                                        });
                                      },
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: ElevatedButton(
                                          onPressed: () => setState(() => _isCreating = true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            shape: const StadiumBorder(),
                                          ),
                                          child: Text(
                                            "Create a new Playlist",
                                            style: textStyleBold.copyWith(color: Colors.black, fontSize: 16),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        TextField(
                                          controller: _newPlaylistController,
                                          style: textStyleBold.copyWith(fontSize: 16),
                                          decoration: InputDecoration(
                                            hintText: "Playlist name",
                                            hintStyle: textStyleBold.copyWith(color: Colors.grey),
                                            enabledBorder: const UnderlineInputBorder(
                                              borderSide: BorderSide(color: Colors.grey),
                                            ),
                                            focusedBorder: const UnderlineInputBorder(
                                              borderSide: BorderSide(color: Colors.white),
                                            ),
                                          ),
                                          autofocus: true,
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            TextButton(
                                              onPressed: () => setState(() => _isCreating = false),
                                              child: Text("Cancel", style: textStyleBold.copyWith(fontSize: 14)),
                                            ),
                                            const SizedBox(width: 14),
                                            ElevatedButton(
                                              onPressed: _createNewPlaylist,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: _spotifyGreen,
                                                foregroundColor: Colors.black,
                                                shape: const StadiumBorder(),
                                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                              ),
                                              child: Text(
                                                "Add",
                                                style: textStyleBold.copyWith(color: Colors.black, fontSize: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        const Divider(color: Colors.grey),
                                      ],
                                    ),
                            ),
                          ),

                          // Playlist List Header
                          if (_playlists.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.list, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text("Most relevant playlists", style: textStyleBold.copyWith(fontSize: 14)),
                                ],
                              ),
                            ),

                          ..._playlists.map((playlist) => _buildPlaylistItem(playlist, textStyleBold, textStyleNormal)),

                          const SizedBox(height: 16),
                        ],
                      ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
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

  Widget _buildPlaylistItem(Playlist playlist, TextStyle titleStyle, TextStyle subtitleStyle) {
    return InkWell(
      onTap: () => _toggleTrackInPlaylist(playlist.id),
      onLongPress: () => Fluttertoast.showToast(msg: "Playlist: ${playlist.name}"),
      splashColor: Colors.white24,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: CachedNetworkImage(
                  imageUrl: playlist.photoUrl ?? "https://i.pravatar.cc/300?u=${playlist.id}",
                  fit: BoxFit.cover,
                  errorWidget: (context, error, stackTrace) => Container(
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
                spacing: 2,
                children: [
                  Text(playlist.name, style: titleStyle.copyWith(fontSize: 14)),
                  Text(
                    "${playlist.trackIds.length} tracks",
                    style: subtitleStyle.copyWith(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),

            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: playlist.trackIds.contains(widget.trackId) ? Colors.white : Colors.grey,
                  width: 2,
                ),
                color: playlist.trackIds.contains(widget.trackId) ? Colors.white : Colors.transparent,
              ),
              child: playlist.trackIds.contains(widget.trackId)
                  ? const Center(
                      child: Icon(Icons.circle, size: 12, color: Colors.black), // Dot inside
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
