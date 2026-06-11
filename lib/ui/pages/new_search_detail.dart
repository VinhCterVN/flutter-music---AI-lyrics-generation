import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/playlist.dart';
import 'package:flutter_ai_music/data/models/search.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/playlist_provider.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/ui/component/element/press_scale.dart';
import 'package:flutter_ai_music/ui/theme/theme.dart';
import 'package:flutter_ai_music/utils/audio_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:permission_handler/permission_handler.dart';

class NewSearchDetailPage extends ConsumerStatefulWidget {
  final String? initialQuery;

  const NewSearchDetailPage({super.key, this.initialQuery});

  @override
  ConsumerState<NewSearchDetailPage> createState() => _NewSearchDetailPageState();
}

class _NewSearchDetailPageState extends ConsumerState<NewSearchDetailPage> with SingleTickerProviderStateMixin {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  late final AnimationController _animationController;

  List<Search> _histories = [];
  List<Search> _trending = [];
  List<Search> _filteredHistories = [];

  List<Track> _tracksResult = [];
  List<Playlist> _playlistsResult = [];

  bool _isLoading = false;
  bool _showResults = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
      // if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      //   _textController.text = widget.initialQuery!;
      //   _performSearch(widget.initialQuery!);
      // } else {
      // }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final searchService = ref.read(searchServiceProvider);
      final results = await Future.wait([searchService.getSearchHistory(), searchService.getTrendingSearch()]);

      if (!mounted) return;
      setState(() {
        _histories = results[0];
        _filteredHistories = _histories;
        _trending = results[1];
      });
    } catch (e) {
      debugPrint("Error loading search meta: $e");
    }
  }

  void _onQueryChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredHistories = _histories;
        _showResults = false;
      } else {
        _filteredHistories = _histories.where((e) => e.keyword.toLowerCase().contains(query.toLowerCase())).toList();
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    _focusNode.unfocus();
    setState(() {
      _isLoading = true;
      _showResults = false;
      _tracksResult.clear();
      _playlistsResult.clear();
    });

    try {
      final searchService = ref.read(searchServiceProvider);
      final searchResult = await searchService.search(query);

      final tracks = await ref.read(trackServiceProvider).getTracksByIds(searchResult.trackIds);
      final playlists = await ref.read(playlistServiceProvider).getPlaylistByIds(searchResult.playlistIds);

      if (!mounted) return;
      setState(() {
        _tracksResult = tracks;
        _playlistsResult = playlists;
        _isLoading = false;
        _showResults = true;
      });

      // Reload search history to include the new query
      _loadData();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(msg: "Search failed: $e");
    }
  }

  Future<void> _deleteHistory(String keyword) async {
    try {
      await ref.read(searchServiceProvider).deleteSearchLog(keyword);
      _loadData();
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to delete history: $e");
    }
  }

  Future<void> _startVoiceSearch() async {
    if (await Permission.microphone.request().isGranted) {
      setState(() => _isListening = true);
      Fluttertoast.showToast(msg: "Listening... (Voice input placeholder)");

      // Simulate listening for 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() => _isListening = false);
    } else {
      Fluttertoast.showToast(msg: "Microphone permission is required for voice search");
    }
  }

  void _playTrack(List<Track> tracks, int index) {
    try {
      AudioHelper.playTrackFromList(ref, allTracks: tracks, selectedIndex: index);
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceDim,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopSearchBar(theme, scheme),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _showResults
                  ? _buildSearchResults(scheme)
                  : _buildSuggestionsAndHistory(scheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSearchBar(ThemeData theme, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: scheme.surfaceDim,
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          ),
          Expanded(
            child: Hero(
              tag: 'search_bar_hero',
              child: Material(
                color: Colors.transparent,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    onChanged: _onQueryChanged,
                    onSubmitted: _performSearch,
                    textInputAction: TextInputAction.search,
                    cursorColor: scheme.primary,
                    decoration: InputDecoration(
                      hintText: "What should we listen to?",
                      hintStyle: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.25,
                      ),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: Colors.black87),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
                    ),
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, letterSpacing: -0.25),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _startVoiceSearch,
            icon: HugeIcon(
              icon: HugeIconsStrokeRounded.aiMic,
              color: _isListening ? Colors.redAccent : Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsAndHistory(ColorScheme scheme) {
    final hasHistory = _filteredHistories.isNotEmpty;
    final hasTrending = _trending.isNotEmpty;

    if (!hasHistory && !hasTrending) {
      return Center(
        child: Text(
          "Search for songs, artists, or playlists",
          style: TextStyle(color: Colors.white38, fontFamily: appFontFamily),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (hasHistory) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Searches",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              if (_textController.text.isEmpty)
                TextButton(
                  onPressed: () {
                    for (var log in _histories) {
                      _deleteHistory(log.keyword);
                    }
                  },
                  child: const Text("Clear All", style: TextStyle(color: Colors.white54, fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _filteredHistories.map((history) {
              return PressScale(
                onTap: () {
                  _textController.text = history.keyword;
                  _performSearch(history.keyword);
                },
                child: Chip(
                  label: Text(
                    history.keyword,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: Colors.white.withAlpha(20),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                  deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white60),
                  onDeleted: () => _deleteHistory(history.keyword),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
        if (hasTrending) ...[
          const Text(
            "Trending Searches",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _trending.length,
            separatorBuilder: (context, index) => const Divider(color: Colors.white12, height: 1),
            itemBuilder: (context, index) {
              final trend = _trending[index];
              return ListTile(
                onTap: () {
                  _textController.text = trend.keyword;
                  _performSearch(trend.keyword);
                },
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: index < 3 ? scheme.primary.withAlpha(50) : Colors.white.withAlpha(15),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(
                      color: index < 3 ? scheme.primary : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                title: Text(
                  trend.keyword,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.trending_up, color: Colors.white30, size: 18),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSearchResults(ColorScheme scheme) {
    if (_tracksResult.isEmpty && _playlistsResult.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: Colors.white30),
            const SizedBox(height: 16),
            Text(
              "No results found for \"${_textController.text}\"",
              style: const TextStyle(color: Colors.white54, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: CustomScrollView(
        slivers: [
          if (_tracksResult.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Row(
                children: const [
                  Icon(Icons.music_note_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Songs",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final track = _tracksResult[index];
                final image = track.images.isNotEmpty ? track.images.first : '';
                return PressScale(
                  onTap: () => _playTrack(_tracksResult, index),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey.shade900,
                        child: image.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: image,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.music_note, color: Colors.white30),
                              )
                            : const Icon(Icons.music_note, color: Colors.white30),
                      ),
                    ),
                    title: Text(
                      track.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: (-0.15)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      track.artistName ?? 'Unknown Artist',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: HugeIcon(icon: HugeIconsStrokeRounded.moreVertical),
                  ),
                );
              }, childCount: _tracksResult.length),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
          if (_playlistsResult.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Row(
                children: const [
                  Icon(Icons.playlist_play_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text(
                    "Playlists",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final playlist = _playlistsResult[index];
                final photoUrl = playlist.photoUrl;
                return PressScale(
                  onTap: () => _playPlaylist(playlist),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              color: Colors.grey.shade900,
                              child: photoUrl != null && photoUrl.isNotEmpty
                                  ? CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover)
                                  : Center(
                                      child: Icon(
                                        Icons.queue_music_rounded,
                                        size: 40,
                                        color: scheme.primary.withAlpha(150),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          playlist.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${playlist.trackIds.length} tracks',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              }, childCount: _playlistsResult.length),
            ),
          ],
        ],
      ),
    );
  }
}
