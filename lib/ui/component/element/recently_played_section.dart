import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/utils/audio_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';

class RecentlyPlayedSection extends ConsumerWidget {
  const RecentlyPlayedSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackService = ref.watch(trackServiceProvider);

    return StreamBuilder<List<Track>>(
      stream: trackService.streamRecentTracks(limit: 10),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final tracks = snapshot.data ?? [];
        if (tracks.isEmpty) return const SizedBox.shrink();

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
                      style: TextStyle(fontFamily: "SpotifyMixUI", fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    TextButton(
                      onPressed: () => context.push('/recent-tracks'),
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
                  itemCount: tracks.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return _RecentTrackCard(track: track, onTap: () => _playTrack(ref, tracks, index));
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _playTrack(WidgetRef ref, List<Track> tracks, int index) {
    try {
      AudioHelper.playTrackFromList(ref, allTracks: tracks, selectedIndex: index);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error playing track: $e');
    }
  }
}

class _RecentTrackCard extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;

  const _RecentTrackCard({required this.track, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: GestureDetector(
        onTap: onTap,
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
              style: const TextStyle(fontFamily: "SpotifyMixUI", fontSize: 14, fontWeight: FontWeight.w500),
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
  }
}
