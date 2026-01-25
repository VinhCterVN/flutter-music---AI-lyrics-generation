import 'package:flutter/material.dart';

// --- Models ---
class Playlist {
  final int id;
  final String name;
  final String? imageUrl;
  final int trackCount;
  bool isContainsTrack; // Mock state: track có trong playlist này không

  Playlist({required this.id, required this.name, this.imageUrl, this.trackCount = 0, this.isContainsTrack = false});
}

void showAddToPlaylistDialog(BuildContext context, {required int currentTrackId, required String trackName}) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: AddToPlaylistScreen(trackId: currentTrackId, trackName: trackName),
    ),
  );
}

// --- Main Widget ---
class AddToPlaylistScreen extends StatefulWidget {
  final int trackId;
  final String trackName;

  const AddToPlaylistScreen({super.key, required this.trackId, required this.trackName});

  @override
  State<AddToPlaylistScreen> createState() => _AddToPlaylistScreenState();
}

class _AddToPlaylistScreenState extends State<AddToPlaylistScreen> {
  // Mock Data
  List<Playlist> _playlists = [];
  bool _isLoading = true;

  // Create Playlist State
  bool _isCreating = false;
  final TextEditingController _newPlaylistController = TextEditingController();

  final Color _spotifyGreen = const Color(0xFF1DB954);
  final String _fontFamily = 'SpotifyMixUI';

  @override
  void initState() {
    super.initState();
    _fetchMockData();
  }

  @override
  void dispose() {
    _newPlaylistController.dispose();
    super.dispose();
  }

  void _fetchMockData() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    setState(() {
      _playlists = [
        Playlist(
          id: 1,
          name: "Mussic Of Vincent",
          trackCount: 15,
          isContainsTrack: true,
          imageUrl: "https://picsum.photos/200/300?random=1",
        ),
        Playlist(
          id: 2,
          name: "Chill Vibes",
          trackCount: 42,
          isContainsTrack: false,
          imageUrl: "https://picsum.photos/200/300?random=2",
        ),
        Playlist(
          id: 3,
          name: "Gym Hard",
          trackCount: 20,
          isContainsTrack: false,
          imageUrl: "https://picsum.photos/200/300?random=3",
        ),
        Playlist(
          id: 4,
          name: "Sleepy Time",
          trackCount: 10,
          isContainsTrack: false,
          imageUrl: "https://picsum.photos/200/300?random=4",
        ),
        Playlist(
          id: 5,
          name: "Coding Focus",
          trackCount: 120,
          isContainsTrack: true,
          imageUrl: "https://picsum.photos/200/300?random=5",
        ),
      ];
      _isLoading = false;
    });
  }

  void _toggleTrackInPlaylist(int playlistId) {
    setState(() {
      final index = _playlists.indexWhere((p) => p.id == playlistId);
      if (index != -1) {
        _playlists[index].isContainsTrack = !_playlists[index].isContainsTrack;
      }
    });
  }

  void _createNewPlaylist() {
    if (_newPlaylistController.text.isNotEmpty) {
      setState(() {
        _playlists.insert(
          0,
          Playlist(
            id: DateTime.now().millisecondsSinceEpoch, // fake id
            name: _newPlaylistController.text,
            trackCount: 1,
            isContainsTrack: true,
          ),
        );
        _isCreating = false;
        _newPlaylistController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme styles
    final textStyleBold = TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: Colors.white);
    final textStyleNormal = TextStyle(fontFamily: _fontFamily, color: Colors.white);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212), // Background tối
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: const BoxConstraints(maxHeight: 600), // Giới hạn chiều cao
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                      style: textStyleBold.copyWith(fontSize: 20),
                      children: [
                        const TextSpan(text: "Adding "),
                        TextSpan(
                          text: widget.trackName,
                          style: const TextStyle(color: Color(0xFF1891FC)),
                        ),
                        const TextSpan(text: " to Playlist"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- Content (Scrollable) ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // Create New Playlist Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: !_isCreating
                              ? SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: () => setState(() => _isCreating = true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      shape: const StadiumBorder(),
                                    ),
                                    child: Text(
                                      "Create a new Playlist",
                                      style: textStyleBold.copyWith(color: Colors.black, fontSize: 16),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: [
                                    TextField(
                                      controller: _newPlaylistController,
                                      style: textStyleBold.copyWith(fontSize: 18),
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
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        TextButton(
                                          onPressed: () => setState(() => _isCreating = false),
                                          child: Text("Cancel", style: textStyleBold.copyWith(fontSize: 16)),
                                        ),
                                        const SizedBox(width: 16),
                                        ElevatedButton(
                                          onPressed: _createNewPlaylist,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _spotifyGreen,
                                            foregroundColor: Colors.black,
                                            shape: const StadiumBorder(),
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          ),
                                          child: Text(
                                            "Add",
                                            style: textStyleBold.copyWith(color: Colors.black, fontSize: 16),
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
                              Text("Most relevant playlists", style: textStyleBold.copyWith(fontSize: 18)),
                            ],
                          ),
                        ),

                      // Playlist Items
                      ..._playlists.map((playlist) => _buildPlaylistItem(playlist, textStyleBold, textStyleNormal)),

                      const SizedBox(height: 16),
                    ],
                  ),
          ),

          // --- Done Button (Sticky Bottom) ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // Handle Done logic here
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _spotifyGreen,
                foregroundColor: Colors.black,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
              ),
              child: Text("Done", style: textStyleBold.copyWith(color: Colors.black, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistItem(Playlist playlist, TextStyle titleStyle, TextStyle subtitleStyle) {
    return InkWell(
      onTap: () => _toggleTrackInPlaylist(playlist.id),
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
                child: Image.network(
                  playlist.imageUrl ?? "",
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[800],
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(playlist.name, style: titleStyle.copyWith(fontSize: 16)),
                  Text(
                    "${playlist.trackCount} tracks",
                    style: subtitleStyle.copyWith(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),

            // Custom Selection Indicator (Mimicking Radio/Checkbox)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: playlist.isContainsTrack ? Colors.white : Colors.grey, width: 2),
                color: playlist.isContainsTrack ? Colors.white : Colors.transparent,
              ),
              child: playlist.isContainsTrack
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
