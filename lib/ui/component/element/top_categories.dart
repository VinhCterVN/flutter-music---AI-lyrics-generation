import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/playlist.dart';
import 'package:flutter_ai_music/provider/playlist_provider.dart';
import 'package:flutter_ai_music/utils/audio_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';

import '../../../provider/track_provider.dart';

class TopCategories extends ConsumerStatefulWidget {
  const TopCategories({super.key});

  @override
  ConsumerState<TopCategories> createState() => _TopCategoriesState();
}

class _TopCategoriesState extends ConsumerState<TopCategories> {
  List<Playlist> _playlists = [];

  @override
  void initState() {
    super.initState();
    fetchPlaylists();
  }

  Future<void> fetchPlaylists() async {
    final res = await ref.read(playlistServiceProvider).getPlaylists();

    if (!mounted) return;
    setState(() => _playlists = res);
  }

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 48,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _QuickPlayCard(playlist: _playlists[index]),
        childCount: _playlists.length,
      ),
    );
  }
}

class _QuickPlayCard extends ConsumerStatefulWidget {
  final Playlist playlist;

  const _QuickPlayCard({required this.playlist});

  @override
  ConsumerState<_QuickPlayCard> createState() => _QuickPlayCardState();
}

class _QuickPlayCardState extends ConsumerState<_QuickPlayCard> {
  late String? _photoUrl = widget.playlist.photoUrl;

  @override
  void initState() {
    super.initState();
    _loadPhotoUrl();
  }

  Future<void> _loadPhotoUrl() async {
    if (widget.playlist.trackIds.isEmpty) {
      setState(() => _photoUrl = "https://i.pravatar.cc/300?u=${widget.playlist.id}");
      return;
    }
    final track = await ref.read(trackServiceProvider).getTracksByIds([widget.playlist.trackIds.first.toString()]);
    if (!mounted) return;
    setState(() => _photoUrl = track.first.images.first);
  }

  Future<void> _playPlaylist(Playlist playlist) async {
    try {
      if (playlist.trackIds.isEmpty) {
        Fluttertoast.showToast(msg: 'Playlist is empty');
        return;
      }
      final trackIdStrings = playlist.trackIds.map((id) => id.toString()).toList();
      final tracks = await ref.read(trackServiceProvider).getTracksByIds(trackIdStrings);
      if (tracks.isEmpty) {
        Fluttertoast.showToast(msg: 'No tracks found in playlist');
        return;
      }
      if (!mounted) return;
      AudioHelper.playTrackFromList(ref, allTracks: tracks, selectedIndex: 0);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error playing playlist: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/playlist/${widget.playlist.id}'),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        decoration: BoxDecoration(color: Colors.white70.withAlpha(30), borderRadius: BorderRadius.circular(4)),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 48,
                height: 48,
                child: GestureDetector(
                  onTap: () => _playPlaylist(widget.playlist) ,
                  child: _photoUrl == null
                      ? Container(
                          color: Colors.grey.shade800,
                          child: Center(child: const Icon(Icons.music_note, color: Colors.white54)),
                        )
                      : CachedNetworkImage(
                          imageUrl: _photoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: Colors.grey.shade800),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey.shade800,
                            child: const Icon(Icons.music_note, color: Colors.white54),
                          ),
                        ),
                ),
              ),
            ),
            // Title
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  widget.playlist.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: "SpotifyMixUI",
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
