import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

class CreatePlaylistSection extends StatelessWidget {
  const CreatePlaylistSection({
    super.key,
    required this.isCreating,
    required this.buttonKey,
    required this.onButtonVisibilityChanged,
    required this.onStartCreating,
    required this.onCancelCreating,
    required this.onCreatePlaylist,
    required this.newPlaylistController,
  });

  final bool isCreating;
  final Key buttonKey;
  final ValueChanged<bool> onButtonVisibilityChanged;

  final VoidCallback onStartCreating;
  final VoidCallback onCancelCreating;
  final VoidCallback onCreatePlaylist;

  final TextEditingController newPlaylistController;

  static const Color spotifyGreen = Color(0xFF1DB954);
  static const String _fontFamily = 'SpotifyMixUI';
  static const TextStyle textStyleBold = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: !isCreating
            ? VisibilityDetector(
                key: buttonKey,
                onVisibilityChanged: (info) => onButtonVisibilityChanged(info.visibleFraction > 0),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onStartCreating,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      "Create a new Playlist",
                      style: const TextStyle(
                        fontFamily: _fontFamily,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              )
            : Column(
                children: [
                  TextField(
                    controller: newPlaylistController,
                    style: textStyleBold.copyWith(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: "Playlist name",
                      hintStyle: textStyleBold.copyWith(color: Colors.grey),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: onCancelCreating,
                        child: Text("Cancel", style: textStyleBold.copyWith(fontSize: 14)),
                      ),
                      const SizedBox(width: 14),
                      ElevatedButton(
                        onPressed: onCreatePlaylist,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: spotifyGreen,
                          foregroundColor: Colors.black,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        ),
                        child: Text("Add", style: textStyleBold.copyWith(color: Colors.black, fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Divider(color: Colors.grey),
                ],
              ),
      ),
    );
  }
}
