import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/models/track.dart';

class TrackOptionsBottomSheet extends ConsumerWidget {
  final ScrollController scrollController;

  final Track track;

  const TrackOptionsBottomSheet({super.key, required this.track, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final playerController = ref.watch(playerControllerProvider);

    return Container(
      decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: Container(color: Colors.black.withAlpha(155)),
            ),
          ),

          Positioned.fill(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(2)),
                ),

                _buildTrackHeader(context),

                const SizedBox(height: 16),
                Divider(height: 1, color: Colors.grey.shade800),

                // Options List
                Flexible(
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: OptionTile(
                          icon: HugeIcons.strokeRoundedInformationCircle,
                          title: 'Track Info',
                          subtitle: 'View details about this track',
                          onTap: () {},
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: OptionTile(
                          icon: HugeIcons.strokeRoundedShare01,
                          title: 'Share',
                          subtitle: 'Share this track with friends',
                          onTap: () => _shareTrack(context),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: OptionTile(
                          icon: track.isFavorite ? HugeIcons.strokeRoundedHeartRemove : HugeIcons.strokeRoundedHeartAdd,
                          title: track.isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                          subtitle: track.isFavorite ? 'Remove from your liked songs' : 'Save to your liked songs',
                          onTap: () {},
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: OptionTile(
                          icon: HugeIcons.strokeRoundedPlayListAdd,
                          title: 'Add to Queue',
                          subtitle: 'Play this track next',
                          onTap: () {
                            // playerController.addToQueue(track);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added "${track.name}" to queue'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: OptionTile(
                          icon: HugeIcons.strokeRoundedMusicNoteSquare02,
                          title: 'Add to Playlist',
                          subtitle: 'Add to an existing or new playlist',
                          onTap: () {},
                        ),
                      ),
                      SliverToBoxAdapter(child: const Divider(height: 1, indent: 16, endIndent: 16)),

                      // Placeholder options
                      SliverToBoxAdapter(
                        child: OptionTile(
                          icon: HugeIcons.strokeRoundedUserAccount,
                          title: 'Go to Artist',
                          subtitle: 'View artist profile',
                          onTap: () => _placeholder(context, 'Go to Artist'),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: OptionTile(
                          icon: HugeIcons.strokeRoundedDish02,
                          title: 'Go to Album',
                          subtitle: 'View album details',
                          onTap: () => _placeholder(context, 'Go to Album'),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: OptionTile(
                          icon: HugeIcons.strokeRoundedSleeping,
                          title: 'Sleep Timer',
                          subtitle: 'Stop playing after a set time',
                          onTap: () => _placeholder(context, 'Sleep Timer'),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: OptionTile(
                          icon: HugeIcons.strokeRoundedVoice,
                          title: 'Equalizer',
                          subtitle: 'Adjust audio settings',
                          onTap: () => _placeholder(context, 'Equalizer'),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: OptionTile(
                          icon: HugeIcons.strokeRoundedBlockchain04,
                          title: 'View Credits',
                          subtitle: 'See song credits and contributors',
                          onTap: () => _placeholder(context, 'View Credits'),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Album Art
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: track.images.first,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.music_note, size: 32, color: Colors.white54),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Track Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.name,
                  style: const TextStyle(fontFamily: "SpotifyMixUI", fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  track.artistName ?? track.artistType.name,
                  style: TextStyle(
                    fontFamily: "SpotifyMixUI",
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha((0.7 * 255).toInt()),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _shareTrack(BuildContext context) {
    Navigator.pop(context);
    final shareText = 'Check out "${track.name}" by ${track.artistName ?? "Unknown Artist"}! 🎵';
    SharePlus.instance.share(ShareParams(text: shareText));
  }

  void _placeholder(BuildContext context, String feature) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming soon!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class OptionTile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const OptionTile({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      visualDensity: const VisualDensity(vertical: -2),
      minVerticalPadding: 0,
      leading: HugeIcon(icon: icon, size: 32, color: Theme.of(context).colorScheme.onSurface),
      title: Text(
        title,
        style: const TextStyle(fontFamily: "SpotifyMixUI", fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: "SpotifyMixUI",
          fontSize: 12,
          color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha((0.6 * 255).toInt()),
        ),
      ),
      onTap: onTap,
    );
  }
}
