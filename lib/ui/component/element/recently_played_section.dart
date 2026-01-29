import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/enums/ui_state.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/utils/audio_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

class RecentlyPlayedSection extends ConsumerStatefulWidget {
  const RecentlyPlayedSection({super.key});

  @override
  ConsumerState<RecentlyPlayedSection> createState() => _RecentlyPlayedSectionState();
}

class _RecentlyPlayedSectionState extends ConsumerState<RecentlyPlayedSection> {
  List<Track> _tracks = [];
  UIState _state = UIState.loading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchRecentTracks());
  }

  Future<void> _fetchRecentTracks() async {
    setState(() => _state = UIState.loading);
    try {
      final tracks = await ref.read(trackServiceProvider).getRecentTracks(pageSize: 10);
      if (!mounted) return;
      setState(() {
        _tracks = tracks.data;
        _state = UIState.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _state = UIState.error);
    }
  }

  Future<void> _playTrack(int index) async {
    try {
      AudioHelper.playTrackFromList(ref, allTracks: _tracks, selectedIndex: index);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error playing track: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state == UIState.loading || _tracks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recently Played",
                  style: TextStyle(fontFamily: "SpotifyMixUI", fontSize: 22, fontWeight: FontWeight.w800),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to full recently played list
                  },
                  child: const Text(
                    "See All",
                    style: TextStyle(fontFamily: "SpotifyMixUI", fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              itemCount: _tracks.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final track = _tracks[index];
                return SizedBox(
                  width: 140,
                  child: GestureDetector(
                    onTap: () => _playTrack(index),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: CachedNetworkImage(
                              imageUrl: track.images.isNotEmpty ? track.images.first : '',
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: Colors.grey.shade800),
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.grey.shade800,
                                child: const Icon(Icons.music_note, color: Colors.white54),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          track.name,
                          style: const TextStyle(fontFamily: "SpotifyMixUI", fontSize: 14, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          track.artistName ?? "Unknown Artist",
                          style: TextStyle(
                            fontFamily: "SpotifyMixUI",
                            fontSize: 12,
                            color: Colors.white.withAlpha((0.6 * 255).toInt()),
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
        ],
      ),
    );
  }
}
