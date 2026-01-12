import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/audio_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

class QueueBottomSheet extends ConsumerStatefulWidget {
  const QueueBottomSheet({super.key});

  @override
  ConsumerState<QueueBottomSheet> createState() => _QueueBottomSheetState();
}

class _QueueBottomSheetState extends ConsumerState<QueueBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final queue = ref.read(queueProvider);
    final currentTrack = ref.watch(currentTrackProvider).value!;

    return Column(
      children: [
        // Current Track
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
                child: ClipRRect(
                  clipBehavior: Clip.antiAlias,
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(imageUrl: currentTrack.images.first, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentTrack.name,
                      style: const TextStyle(
                        fontFamily: "SpotifyMixUI",
                        color: Colors.green,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentTrack.artistType.name,
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow, color: Colors.black, size: 28),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.shuffle, color: Colors.grey.shade400, size: 16),
              const SizedBox(width: 8),
              Text('Phát ngẫu nhiên từ:', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
            ],
          ),
        ),

        // Queue List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: queue.tracks.length,
            itemBuilder: (context, index) {
              final track = queue.tracks[index] as UriAudioSource;
              final tag = track.tag as Map<String, Object>;
              return InkWell(
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
                        child: ClipRRect(
                          clipBehavior: Clip.hardEdge,
                          borderRadius: BorderRadius.circular(4),
                          child: CachedNetworkImage(imageUrl: (tag["images"] as List<String>).first, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tag["title"] as String? ?? 'Unknown',
                              style: const TextStyle(
                                fontFamily: "SpotifyMixUI",
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (tag["artistType"] as ArtistType).name,
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.drag_handle_rounded, color: Colors.grey.shade400),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}