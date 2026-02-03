import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/enums/ui_state.dart';
import 'package:flutter_ai_music/data/models/playlist.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/data/models/user.dart';
import 'package:flutter_ai_music/provider/auth_provider.dart';
import 'package:flutter_ai_music/provider/playlist_provider.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/ui/layout/loading_scaffold.dart';
import 'package:flutter_ai_music/utils/functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../utils/audio_helper.dart';

class PlaylistDetails extends ConsumerStatefulWidget {
  final String playlistId;

  const PlaylistDetails({super.key, required this.playlistId});

  @override
  ConsumerState<PlaylistDetails> createState() => _PlaylistDetailsState();
}

class _PlaylistDetailsState extends ConsumerState<PlaylistDetails> {
  late final ScrollController _controller;
  late Playlist _playlist;

  late String _photoUrl;
  late Color _ambientColor;
  late User _author;

  double titleOpacity = 1.0;
  List<Track> _tracks = [];
  UIState _state = UIState.loading;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchPlaylist();
      await _loadPhotoUrl();
      await _fetchAmbientColor();
      setState(() => _state = UIState.ready);
      await _fetchTracks();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  Future<void> _fetchPlaylist() async {
    setState(() => _state = UIState.loading);
    final res = await ref.read(playlistServiceProvider).getPlaylistByIds([widget.playlistId]);
    final user = await ref.read(userServiceProvider).getUserFromId(res.first.userId);
    setState(() {
      _playlist = res.first;
      _author = user;
    });
  }

  Future<void> _loadPhotoUrl() async {
    if (_playlist.photoUrl != null) {
      setState(() => _photoUrl = _playlist.photoUrl!);
      return;
    }
    if (_playlist.trackIds.isEmpty) {
      setState(() => _photoUrl = "https://i.pravatar.cc/300?u=${_playlist.id}");
      return;
    }
    final track = await ref.read(trackServiceProvider).getTracksByIds([_playlist.trackIds.first.toString()]);
    if (!mounted) return;
    setState(() => _photoUrl = track.first.images.first);
  }

  Future<void> _fetchAmbientColor() async {
    final res = await getDominantColor(_photoUrl);
    if (!mounted) return;
    setState(() => _ambientColor = res);
  }

  Future<void> _fetchTracks() async {
    final tracks = await ref
        .read(trackServiceProvider)
        .getTracksByIds(_playlist.trackIds.map((e) => e.toString()).toList());
    if (!mounted) return;
    setState(() => _tracks = tracks);
  }

  Future<void> _playTrack(WidgetRef ref, List<Track> allTracks, int selectedIndex) async {
    try {
      AudioHelper.playTrackFromList(ref, allTracks: allTracks, selectedIndex: selectedIndex);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error playing track: $e');
    }
  }

  String formatDateTime(DateTime time) {
    return '${time.month.toString().padLeft(2, '0')}/${time.day.toString().padLeft(2, '0')}/${time.year}';
  }

  @override
  Widget build(BuildContext context) {
    final Size(:width, :height) = MediaQuery.sizeOf(context);
    final topPadding = MediaQuery.paddingOf(context).top;

    return switch (_state) {
      UIState.loading => const LoadingScaffold(),
      _ => Scaffold(
        backgroundColor: mixColors([MapEntry(_ambientColor, 0.25), MapEntry(Colors.black54, 0.75)]),
        body: Stack(
          clipBehavior: Clip.antiAlias,
          children: [
            Positioned.fill(
              child: CustomScrollView(
                controller: _controller,
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.fromLTRB(18, topPadding + 18, 18, 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: AlignmentGeometry.topCenter,
                          end: AlignmentGeometry.bottomCenter,
                          // stops: const [0.0, 0.75, 1.0],
                          colors: [
                            mixColors([MapEntry(_ambientColor, 0.9), MapEntry(Colors.white, 0.1)]),
                            mixColors([MapEntry(_ambientColor, 0.9), MapEntry(Colors.black54, 0.1)]),
                            mixColors([MapEntry(_ambientColor, 0.25), MapEntry(Colors.black54, 0.75)]),
                          ],
                        ),
                        // border: Border(bottom: BorderSide(color: Colors.black54.withAlpha(100), width: 1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(100),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: CachedNetworkImage(
                                imageUrl: _photoUrl,
                                width: width * 0.6,
                                height: width * 0.6,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: Colors.grey.shade800),
                                errorWidget: (_, __, ___) => Container(
                                  color: Colors.grey.shade800,
                                  child: const Icon(Icons.music_note, color: Colors.white54),
                                ),
                              ),
                            ),
                          ),
                          VisibilityDetector(
                            key: const Key("playlist_title_visibility_detector"),
                            onVisibilityChanged: (info) {
                              if (!mounted) return;
                              setState(() => titleOpacity = info.visibleFraction.clamp(0.0, 1.0));
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                _playlist.name,
                                style: const TextStyle(
                                  fontFamily: "SpotifyMixUI",
                                  fontWeight: FontWeight.w800,
                                  fontSize: 28,
                                ),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            spacing: 8,
                            children: [
                              ClipOval(
                                clipBehavior: Clip.antiAlias,
                                child: CachedNetworkImage(
                                  imageUrl: _author.photoUrl ?? "https://i.pravatar.cc/300?u=${_author.id}",
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    color: Colors.grey.shade800,
                                    child: const Icon(Icons.person, color: Colors.white54, size: 16),
                                  ),
                                ),
                              ),

                              Text(
                                "${_author.displayName.isNotEmpty ? _author.displayName : "Author"}  •  ${_playlist.trackIds.length} songs",
                                style: TextStyle(
                                  fontFamily: "SpotifyMixUI",
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: (-0.5),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              spacing: 8,
                              children: [
                                const HugeIcon(icon: HugeIconsStrokeRounded.playlist01, color: Colors.white54),
                                Text(
                                  "Playlist • ${formatDateTime(_playlist.createdAt)}",
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontFamily: "SpotifyMixUI",
                                    fontSize: 14,
                                    color: Colors.white.withAlpha((0.7 * 255).toInt()),
                                    letterSpacing: (-0.25),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Row(
                            spacing: 4,
                            children: [
                              Container(
                                width: 36,
                                height: 48,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white54, width: 2),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: CachedNetworkImage(imageUrl: _photoUrl, fit: BoxFit.cover, scale: 1.1),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: const HugeIcon(icon: HugeIconsStrokeRounded.downloadCircle01),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: const HugeIcon(icon: HugeIconsStrokeRounded.share08),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: const HugeIcon(icon: HugeIconsStrokeRounded.moreVertical),
                              ),
                              const Spacer(),
                              IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.greenAccent.shade400,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.all(0),
                                ),
                                onPressed: () => _playTrack(ref, _tracks, 0),
                                icon: const Icon(Icons.play_arrow_rounded),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_tracks.isEmpty)
                    SliverToBoxAdapter(child: Center(child: const Text("No tracks found.")))
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      sliver: SliverReorderableList(
                        itemCount: _tracks.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex--;
                            final track = _tracks.removeAt(oldIndex);
                            _tracks.insert(newIndex, track);
                          });
                        },
                        itemBuilder: (context, index) {
                          final track = _tracks[index];
                          return ReorderableDelayedDragStartListener(
                            key: ValueKey(track.id),
                            index: index,
                            child: ListTile(
                              // leading: ClipRRect(
                              //   borderRadius: BorderRadius.circular(4),
                              //   child: CachedNetworkImage(
                              //     imageUrl: track.images.first,
                              //     width: 48,
                              //     height: 48,
                              //     fit: BoxFit.cover,
                              //     errorWidget: (_, __, ___) => Container(
                              //       color: Colors.grey.shade800,
                              //       child: const Icon(Icons.music_note, color: Colors.white54),
                              //     ),
                              //   ),
                              // ),
                              title: Text(
                                track.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: "SpotifyMixUI",
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: (-0.15),
                                ),
                              ),
                              subtitle: Text(
                                track.artistName ?? "Unknown Artist",
                                style: TextStyle(
                                  fontFamily: "SpotifyMixUI",
                                  fontSize: 14,
                                  color: Colors.white.withAlpha((0.7 * 255).toInt()),
                                ),
                              ),
                              trailing: ReorderableDragStartListener(
                                index: index,
                                child: const Icon(Icons.drag_handle, color: Colors.white54),
                              ),
                              onTap: () => _playTrack(ref, _tracks, index)
                            ),
                          );
                        },
                      ),
                    ),

                  SliverToBoxAdapter(child: SizedBox(height: 150)),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 100),
                opacity: 1.0 - titleOpacity,
                child: Container(
                  height: 86,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        mixColors([MapEntry(_ambientColor, 0.9), MapEntry(Colors.white, 0.1)]),
                        _ambientColor,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                    child: Center(
                      child: Text(
                        _playlist.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: "SpotifyMixUI", fontWeight: FontWeight.w800, fontSize: 20),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Align(
              alignment: AlignmentDirectional.topStart,
              child: SafeArea(
                top: true,
                child: GestureDetector(
                  onTap: context.pop,
                  child: ClipOval(
                    child: Padding(padding: const EdgeInsets.all(12), child: const Icon(Icons.arrow_back_rounded)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    };
  }
}
