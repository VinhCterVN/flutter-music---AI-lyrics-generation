import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/enums/ui_state.dart';
import 'package:flutter_ai_music/data/models/playlist.dart';
import 'package:flutter_ai_music/data/models/search.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/ui/component/element/search/track_top_search.dart';
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

    if (!mounted) return;
    setState(() {
      _tracks.clear();
      _tracks.addAll(res);
      _uiState = UIState.ready;
    });
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
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  "Top result",
                  style: TextStyle(fontFamily: "SpotifyMixUI", fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: TrackTopSearch(
                track: _tracks.first,
                onTap: () => Fluttertoast.showToast(msg: "Track ${_tracks.first.name} tapped"),
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
                    itemCount: _tracks.length,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: 140,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: CachedNetworkImage(imageUrl: _tracks[index].images.first, fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _tracks[index].name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
      _ => const Center(child: Text('Unknown state')),
    };
  }
}
