import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/enums/ui_state.dart';
import 'package:flutter_ai_music/data/models/playlist.dart';
import 'package:flutter_ai_music/data/models/search.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/playlist_provider.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/ui/component/element/search/track_top_search.dart';
import 'package:flutter_ai_music/utils/audio_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SearchResultDetail extends ConsumerStatefulWidget {
  final SearchResult? result;

  const SearchResultDetail({super.key, required this.result});

  @override
  ConsumerState<SearchResultDetail> createState() => _SearchResultDetailState();
}

class _SearchResultDetailState extends ConsumerState<SearchResultDetail> {
  final List<Track> _tracks = [];
  final List<Playlist> _playlists = [];
  UIState _uiState = UIState.loading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchResult());
  }

  Future<void> _fetchResult() async {
    if (widget.result == null) {
      setState(() => _uiState = UIState.ready);
      return;
    }
    setState(() => _uiState = UIState.loading);
    final res = await ref.read(trackServiceProvider).getTracksByIds(widget.result!.trackIds);
    final playlists = await ref.read(playlistServiceProvider).getPlaylistByIds(widget.result!.playlistIds);
    if (!mounted) return;
    setState(() {
      _tracks.clear();
      _tracks.addAll(res);
      _playlists.clear();
      _playlists.addAll(playlists);
      _uiState = UIState.ready;
    });
  }

  Future<void> _playTrack(WidgetRef ref, List<Track> allTracks, int selectedIndex) async {
    try {
      AudioHelper.playTrackFromList(ref, allTracks: allTracks, selectedIndex: selectedIndex);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error playing track: $e');
    }
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
    if (widget.result == null) {
      return const Center(child: Text('No result found'));
    }
    return switch (_uiState) {
      UIState.loading => const Center(child: CircularProgressIndicator()),
      UIState.ready => CustomScrollView(
        key: PageStorageKey('search_result_${widget.result!.id}'),
        scrollDirection: Axis.vertical,
        slivers: [
          if (_tracks.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  "Top result",
                  style: TextStyle(fontFamily: "SpotifyMixUI", fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: TrackTopSearch(
                track: _tracks.first,
                onTap: () => _playTrack(ref, _tracks, 0),
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              ),
            ),
            if (_tracks.length > 1) ...[
              SliverToBoxAdapter(
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    "Songs",
                    style: TextStyle(fontFamily: "SpotifyMixUI", fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  height: 220,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: ListView.separated(
                    itemCount: _tracks.length - 1,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => SizedBox(
                      width: 140,
                      child: GestureDetector(
                        onTap: () => _playTrack(ref, _tracks, index + 1),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: CachedNetworkImage(imageUrl: _tracks[index + 1].images.first, fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _tracks[index + 1].name,
                              style: const TextStyle(
                                fontFamily: "SpotifyMixUI",
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
          if (_playlists.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  "Playlists",
                  style: TextStyle(fontFamily: "SpotifyMixUI", fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                height: 220,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: ListView.separated(
                  itemCount: _playlists.length,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final playlist = _playlists[index];
                    return SizedBox(
                      width: 140,
                      child: GestureDetector(
                        onTap: () => _playPlaylist(playlist),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Theme.of(context).colorScheme.primary.withAlpha((0.7 * 255).round()),
                                        Theme.of(context).colorScheme.secondary.withAlpha((0.7 * 255).round()),
                                      ],
                                    ),
                                  ),
                                  child: playlist.photoUrl != null
                                      ? CachedNetworkImage(imageUrl: playlist.photoUrl!, fit: BoxFit.cover)
                                      : Center(
                                          child: Icon(
                                            Icons.queue_music_rounded,
                                            size: 48,
                                            color: Colors.white.withAlpha((0.9 * 255).round()),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              playlist.name,
                              style: const TextStyle(
                                fontFamily: "SpotifyMixUI",
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${playlist.trackIds.length} tracks',
                              style: TextStyle(
                                fontFamily: "SpotifyMixUI",
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
      _ => const Center(child: Text('Unknown state')),
    };
  }
}
