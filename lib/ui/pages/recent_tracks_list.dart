import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/utils/audio_helper.dart';
import 'package:flutter_ai_music/utils/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';

class TracksListPage extends ConsumerWidget {
  final List<Track> tracks;

  const TracksListPage({super.key, this.tracks = const []});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackService = ref.watch(trackServiceProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const HugeIcon(icon: HugeIconsStrokeRounded.arrowLeft01),
          onPressed: context.pop,
        ),
        title: const Text(
          'Recently Played',
          style: TextStyle(fontFamily: 'SpotifyMixUI', fontSize: 16, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<Track>>(
        stream: trackService.streamRecentTracks(limit: 50),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tracks = snapshot.data ?? [];
          if (tracks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade600),
                  const SizedBox(height: 16),
                  Text(
                    'No recently played tracks',
                    style: TextStyle(fontFamily: 'SpotifyMixUI', fontSize: 18, color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              return _RecentTrackListTile(
                track: track,
                onTap: () => AudioHelper.playTrackFromList(ref, allTracks: tracks, selectedIndex: index),
                onLongPress: () => showTrackOptions(track, context),
              );
            },
          );
        },
      ),
    );
  }
}

class _RecentTrackListTile extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _RecentTrackListTile({required this.track, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: track.images.isNotEmpty ? track.images.first : '',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(width: 56, height: 56, color: Colors.grey.shade800),
                errorWidget: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey.shade800,
                  child: const Icon(Icons.music_note, color: Colors.white54),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.name,
                    style: const TextStyle(
                      fontFamily: "SpotifyMixUI",
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: (-0.15),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.artistName ?? 'Unknown Artist',
                    style: TextStyle(
                      fontFamily: 'SpotifyMixUI',
                      fontSize: 14,
                      color: Colors.white.withAlpha((0.6 * 255).toInt()),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.more_vert_rounded), onPressed: onLongPress),
          ],
        ),
      ),
    );
  }
}
