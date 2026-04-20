import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/service/local_audio_service.dart';
import 'package:flutter_ai_music/utils/audio_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// Converts an [on_audio_query] [SongModel] into a [Track] compatible with
/// the existing audio pipeline. Local songs use the file URI directly.
Track _songModelToTrack(SongModel song) {
  return Track(
    id: song.id,
    name: song.title,
    artistId: '',
    uri: song.uri ?? 'file://${song.data}',
    images: [],
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      song.dateAdded != null ? song.dateAdded! * 1000 : 0,
    ),
    artistName: song.artist != null && song.artist != '<unknown>' ? song.artist : 'Unknown Artist',
    artistType: ArtistType.NestArtist,
  );
}

class LocalFolderSongsPage extends ConsumerStatefulWidget {
  final String folderPath;
  final String folderName;

  const LocalFolderSongsPage({
    super.key,
    required this.folderPath,
    required this.folderName,
  });

  @override
  ConsumerState<LocalFolderSongsPage> createState() => _LocalFolderSongsPageState();
}

class _LocalFolderSongsPageState extends ConsumerState<LocalFolderSongsPage> {
  List<SongModel> _songs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final songs = await LocalAudioService.instance.getSongsInFolder(widget.folderPath);
    if (!mounted) return;
    setState(() {
      _songs = songs;
      _loading = false;
    });
  }

  void _play(int index) {
    final tracks = _songs.map(_songModelToTrack).toList();
    try {
      AudioHelper.playTrackFromList(ref, allTracks: tracks, selectedIndex: index);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Cannot play: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const HugeIcon(icon: HugeIconsStrokeRounded.arrowLeft01),
          onPressed: context.pop,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.folderName,
              style: const TextStyle(
                fontFamily: 'SpotifyMixUI',
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (!_loading)
              Text(
                '${_songs.length} songs',
                style: TextStyle(
                  fontFamily: 'SpotifyMixUI',
                  fontSize: 12,
                  color: Colors.white.withAlpha(140),
                ),
              ),
          ],
        ),
        actions: [
          if (!_loading && _songs.isNotEmpty)
            IconButton(
              tooltip: 'Shuffle all',
              icon: const Icon(Icons.shuffle_rounded),
              onPressed: () {
                final tracks = _songs.map(_songModelToTrack).toList()..shuffle();
                AudioHelper.playTrackFromList(ref, allTracks: tracks, selectedIndex: 0);
              },
            ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _songs.length,
                  itemBuilder: (context, index) {
                    final song = _songs[index];
                    return _LocalSongTile(
                      song: song,
                      query: LocalAudioService.instance.query,
                      onTap: () => _play(index),
                    );
                  },
                ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_off_rounded, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'No audio files in this folder',
              style: TextStyle(
                fontFamily: 'SpotifyMixUI',
                fontSize: 16,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
}

// ─── Local song tile ────────────────────────────────────────────────────────

class _LocalSongTile extends StatelessWidget {
  final SongModel song;
  final OnAudioQuery query;
  final VoidCallback onTap;

  const _LocalSongTile({
    required this.song,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Album art via QueryArtworkWidget
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: QueryArtworkWidget(
                id: song.id,
                type: ArtworkType.AUDIO,
                artworkWidth: 54,
                artworkHeight: 54,
                artworkFit: BoxFit.cover,
                nullArtworkWidget: Container(
                  width: 54,
                  height: 54,
                  color: Colors.grey.shade800,
                  child: const Icon(Icons.music_note_rounded, color: Colors.white38),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'SpotifyMixUI',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    song.artist != null && song.artist != '<unknown>'
                        ? song.artist!
                        : 'Unknown Artist',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'SpotifyMixUI',
                      fontSize: 13,
                      color: Colors.white.withAlpha(160),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDuration(song.duration),
              style: TextStyle(
                fontFamily: 'SpotifyMixUI',
                fontSize: 12,
                color: Colors.white.withAlpha(100),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int? ms) {
    if (ms == null) return '';
    final dur = Duration(milliseconds: ms);
    final m = dur.inMinutes;
    final s = (dur.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
