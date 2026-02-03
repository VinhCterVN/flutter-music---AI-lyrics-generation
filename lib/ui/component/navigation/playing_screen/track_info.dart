import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../data/models/track.dart';
import '../../../../provider/artist_provider.dart';
import '../queue_bottom_sheet.dart';

class TrackInfo extends ConsumerWidget {
  final Track track;

  const TrackInfo({super.key, required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentArtist = ref.watch(currentArtistProvider).value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.name,
                  style: const TextStyle(fontFamily: "SpotifyMixUI", fontSize: 18, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  currentArtist?.name ?? track.artistType.name,
                  style: TextStyle(
                    fontFamily: "SpotifyMixUI",
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha((0.7 * 255).toInt()),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.queue_music_rounded),
                iconSize: 24,
                onPressed: () => showModalBottomSheet(
                  context: context,
                  useRootNavigator: true,
                  isScrollControlled: true,
                  useSafeArea: true,
                  isDismissible: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.5,
                    minChildSize: 0.5,
                    maxChildSize: 1.0,
                    snap: true,
                    snapSizes: const [0.5, 0.75, 1.0],
                    builder: (context, scrollController) => QueueBottomSheet(scrollController: scrollController),
                  ),
                ),
              ),
              IconButton(
                icon: track.isFavorite
                    ? FaIcon(FontAwesomeIcons.solidHeart, size: 20)
                    : HugeIcon(icon: HugeIcons.strokeRoundedHeartAdd, size: 22),
                color: track.isFavorite
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).textTheme.bodyLarge?.color,
                iconSize: 24,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
