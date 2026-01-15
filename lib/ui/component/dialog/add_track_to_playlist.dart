import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/playlist.dart';
import 'package:flutter_ai_music/provider/playlist_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class AddTrackToPlaylist extends ConsumerStatefulWidget {
  final int trackId;

  const AddTrackToPlaylist({super.key, required this.trackId});

  @override
  ConsumerState<AddTrackToPlaylist> createState() => _AddTrackToPlaylistState();
}

class _AddTrackToPlaylistState extends ConsumerState<AddTrackToPlaylist> {
  bool _isLoading = true;
  List<Playlist> _playlists = [];

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
    _playlists = res;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_isLoading) {
      true => SimpleDialog(
        clipBehavior: Clip.hardEdge,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16, 16, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 10,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Text(
                  "Loading Playlists...",
                  style: GoogleFonts.roboto().copyWith(fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
      false => SimpleDialog(
        title: const Text(
          "Adding track to Playlist",
          style: TextStyle(fontFamily: "SpotifyMixUI", fontWeight: FontWeight.bold, fontSize: 18),
        ),
        clipBehavior: Clip.hardEdge,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Here you can implement the functionality to add the track to a playlist.",
              style: TextStyle(
                fontFamily: "SpotifyMixUI",
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    };
  }
}
