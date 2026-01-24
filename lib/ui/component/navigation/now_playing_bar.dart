import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/provider/playlist_provider.dart';
import 'package:flutter_ai_music/ui/component/dialog/add_track_to_playlist_demo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:marquee/marquee.dart';

import '../../../provider/artist_provider.dart';
import '../../../provider/audio_provider.dart';
import '../../../provider/uistate_provider.dart';
import '../../../utils/functions.dart';

class NowPlayingBar extends ConsumerStatefulWidget {
  final VoidCallback? onTap;

  const NowPlayingBar({super.key, this.onTap});

  @override
  ConsumerState<NowPlayingBar> createState() => _NowPlayingBarState();
}

class _NowPlayingBarState extends ConsumerState<NowPlayingBar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTrackAsync = ref.watch(currentTrackProvider);
    final currentArtist = ref.watch(currentArtistProvider).value;
    final isPlayingAsync = ref.watch(isPlayingProvider);
    final isBufferingAsync = ref.watch(isBufferingProvider);
    final progressAsync = ref.watch(progressProvider);
    final ambientColor = ref.watch(ambientColorProvider);
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final player = ref.read(audioPlayerProvider);
    final currentIndex = player.currentIndex;
    final isFavourite = currentIndex != null ? ref.watch(queueProvider).rawTracks[currentIndex].isFavorite : false;

    return currentTrackAsync.when(
      data: (currentTrack) {
        if (currentTrack == null) {
          _animationController.reverse();
          return const SizedBox.shrink();
        }

        final isPlaying = isPlayingAsync.value ?? false;
        final isBuffering = isBufferingAsync.value ?? false;
        final progress = progressAsync.value;
        final progressPercent = progress != null && progress.duration != null
            ? (progress.position.inMilliseconds / progress.duration!.inMilliseconds * 100).clamp(0.0, 100.0)
            : 0.0;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _animationController.forward();
          }
        });

        final animatedColor = Color.lerp(ambientColor, Colors.grey, 0.0) ?? Colors.grey;

        final containerColor = mixColors([MapEntry(surfaceColor, 0.05), MapEntry(animatedColor, 0.95)]);

        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: GestureDetector(
                onTap: widget.onTap,
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! > 100) {
                      ref.read(playerControllerProvider).pause();
                    } else if (details.primaryVelocity! < -100) {
                      widget.onTap?.call();
                    }
                  }
                },
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! > 100) {
                      ref.read(playerControllerProvider).skipPrev();
                    } else if (details.primaryVelocity! < -100) {
                      ref.read(playerControllerProvider).skipNext();
                    }
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [containerColor, animatedColor, animatedColor, animatedColor],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.3 * 255).round()),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.only(top: 6, left: 6, right: 6, bottom: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Hero(
                              tag: "now-playing-track-${currentTrack.images.first}",
                              child: CachedNetworkImage(
                                imageUrl: currentTrack.images.isNotEmpty ? currentTrack.images.first : '',
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 44,
                                  height: 44,
                                  color: Colors.grey[900],
                                  child: const Icon(Icons.music_note, color: Colors.white54),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 44,
                                  height: 44,
                                  color: Colors.grey[900],
                                  child: const Icon(Icons.music_note, color: Colors.white54),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Track info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 18,
                                  child: currentTrack.name.length > 25
                                      ? Marquee(
                                          text: currentTrack.name,
                                          style: const TextStyle(
                                            fontFamily: "SpotifyMixUI",
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                          ),
                                          scrollAxis: Axis.horizontal,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          blankSpace: 20.0,
                                          velocity: 50.0,
                                          pauseAfterRound: const Duration(seconds: 1),
                                        )
                                      : Text(
                                          currentTrack.name,
                                          style: const TextStyle(
                                            fontFamily: "SpotifyMixUI",
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentArtist?.name ?? 'Unknown Artist',
                                  style: TextStyle(fontSize: 12, color: Colors.white.withAlpha((0.9 * 255).round())),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Controls
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 4,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (currentIndex == null) return;
                                    ref.read(playlistServiceProvider).toggleTrackToFavourite(currentTrack.id);
                                    ref.read(queueProvider.notifier).toggleFavoriteAtIndex(currentIndex);
                                    Fluttertoast.showToast(
                                      msg: currentTrack.isFavorite ? 'Removed from favorites' : 'Added to favorites',
                                    );
                                  },
                                  onLongPress: () =>
                                      showAddToPlaylistDialog(context, currentTrackId: 101, trackName: "Shape Of You"),
                                  child: isFavourite
                                      ? FaIcon(
                                          FontAwesomeIcons.solidHeart,
                                          size: 20,
                                          color: Theme.of(context).colorScheme.primary,
                                        )
                                      : HugeIcon(icon: HugeIcons.strokeRoundedHeartAdd, size: 22),
                                ),
                                SizedBox(width: 4),
                                isBuffering
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Theme.of(context).colorScheme.primaryFixedDim,
                                          ),
                                        ),
                                      )
                                    : GestureDetector(
                                        onTap: () {
                                          final controller = ref.read(playerControllerProvider);
                                          if (isPlaying) {
                                            controller.pause();
                                          } else {
                                            controller.play();
                                          }
                                        },
                                        child: FaIcon(
                                          isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
                                          size: 20,
                                        ),
                                      ),
                                SizedBox(width: 4),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(1),
                        child: LinearProgressIndicator(
                          value: progressPercent / 100,
                          minHeight: 2,
                          backgroundColor: Colors.white.withAlpha((0.2 * 255).round()),
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withAlpha((0.9 * 255).round())),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
