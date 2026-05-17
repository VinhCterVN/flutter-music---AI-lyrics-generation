import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/provider/playlist_provider.dart';
import 'package:flutter_ai_music/ui/component/dialog/add_track_to_playlist.dart';
import 'package:flutter_ai_music/ui/component/element/press_scale.dart';
import 'package:flutter_ai_music/ui/layout/animated_ambient_color_builder.dart';
import 'package:flutter_ai_music/ui/theme/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:marquee/marquee.dart';

import '../../../provider/artist_provider.dart';
import '../../../provider/audio_provider.dart';
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
    final surfaceColor = Theme.of(context).colorScheme.surface;

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
            child: _NowPlayingBarBody(
              surfaceColor: surfaceColor,
              onVisibilityChanged: (visible) {
                if (!mounted) return;
                if (visible) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NowPlayingBarBody extends ConsumerWidget {
  final Color surfaceColor;
  final ValueChanged<bool> onVisibilityChanged;

  const _NowPlayingBarBody({required this.surfaceColor, required this.onVisibilityChanged});

  void _notifyVisibility(bool visible) {
    WidgetsBinding.instance.addPostFrameCallback((_) => onVisibilityChanged(visible));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrackAsync = ref.watch(currentTrackProvider);
    final currentArtist = ref.watch(currentArtistProvider).value;

    return currentTrackAsync.when(
      data: (currentTrack) {
        if (currentTrack == null) {
          _notifyVisibility(false);
          return const SizedBox.shrink();
        }

        _notifyVisibility(true);

        return AnimatedAmbientColorBuilder(
          builder: (color) {
            final containerColor = mixColors([MapEntry(surfaceColor, 0.05), MapEntry(color, 0.95)]);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [containerColor, color, color, color],
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
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha((0.4 * 255).round()),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: _NowPlayingTrackInfo(
                          trackName: currentTrack.name,
                          artistName: currentArtist?.name ?? 'Unknown Artist',
                          artistRoute: artistRouteLocation(
                            artistId: currentTrack.artistId,
                            artistType: currentTrack.artistType,
                            artistName: currentTrack.artistName,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _NowPlayingControls(trackId: currentTrack.id, trackName: currentTrack.name),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const _NowPlayingProgress(),
                ],
              ),
            );
          },
        );
      },
      loading: () {
        _notifyVisibility(false);
        return const SizedBox.shrink();
      },
      error: (error, stack) {
        _notifyVisibility(false);
        return const SizedBox.shrink();
      },
    );
  }
}

class _NowPlayingTrackInfo extends StatelessWidget {
  final String trackName;
  final String artistName;
  final String artistRoute;

  const _NowPlayingTrackInfo({required this.trackName, required this.artistName, required this.artistRoute});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 18,
          child: trackName.length > 25
              ? Marquee(
                  text: trackName,
                  style: appTextStyle,
                  textDirection: TextDirection.ltr,
                  scrollAxis: Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  blankSpace: 20.0,
                  velocity: 50.0,
                  pauseAfterRound: const Duration(seconds: 1),
                )
              : Text(
                  trackName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
        const SizedBox(height: 4),
        PressScale(
          onTap: () => context.push(artistRoute),
          child: Text(
            artistName,
            style: TextStyle(fontSize: 12, color: Colors.white.withAlpha((0.9 * 255).round())),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _NowPlayingControls extends ConsumerWidget {
  final int trackId;
  final String trackName;

  const _NowPlayingControls({required this.trackId, required this.trackName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(queueProvider.select((state) => state.currentIndex));
    final isFavourite = ref.watch(
      queueProvider.select((state) {
        if (state.rawTracks.isEmpty || state.currentIndex < 0 || state.currentIndex >= state.rawTracks.length) {
          return false;
        }

        return state.rawTracks[state.currentIndex].isFavorite;
      }),
    );
    final isPlaying = ref.watch(isPlayingProvider).value ?? false;
    final isBuffering = ref.watch(isBufferingProvider).value ?? false;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            GestureDetector(
              onTap: () {
                final queue = ref.read(queueProvider);
                if (currentIndex < 0 || currentIndex >= queue.rawTracks.length) {
                  return;
                }

                ref.read(playlistServiceProvider).toggleTrackToFavourite(trackId);
                ref.read(queueProvider.notifier).toggleFavoriteAtIndex(currentIndex);
                Fluttertoast.showToast(msg: isFavourite ? 'Removed from favorites' : 'Added to favorites');
              },
              onLongPress: () {
                showGeneralDialog(
                  context: context,
                  barrierDismissible: true,
                  barrierLabel: "Dialog",
                  barrierColor: Colors.black54,
                  transitionDuration: const Duration(milliseconds: 50),
                  pageBuilder: (context, animation, secondaryAnimation) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.all(16),
                    child: AddToPlaylistScreen(trackId: trackId, trackName: trackName),
                  ),
                );
              },
              child: isFavourite
                  ? FaIcon(
                      FontAwesomeIcons.solidHeart,
                      size: 22,
                      color: Theme.of(context).colorScheme.primary,
                      semanticLabel: "Favourite",
                    )
                  : HugeIcon(icon: HugeIcons.strokeRoundedHeartAdd, size: 22),
            ),
            const SizedBox(width: 4),
            isBuffering
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primaryFixedDim),
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
                      size: 22,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54.withAlpha(100))],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _NowPlayingProgress extends ConsumerWidget {
  const _NowPlayingProgress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider).value;
    final progressPercent = progress != null && progress.duration != null
        ? (progress.position.inMilliseconds / progress.duration!.inMilliseconds * 100).clamp(0.0, 100.0)
        : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(1),
      child: LinearProgressIndicator(
        value: progressPercent / 100,
        minHeight: 2,
        backgroundColor: Colors.white.withAlpha((0.2 * 255).round()),
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withAlpha((0.9 * 255).round())),
      ),
    );
  }
}
