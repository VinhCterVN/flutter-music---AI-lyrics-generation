import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/provider/playlist_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../data/models/track.dart';

class TrackCardDemo extends ConsumerStatefulWidget {
  final Track track;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onFavorite;

  const TrackCardDemo({super.key, required this.track, this.onTap, this.onPlay, this.onFavorite});

  @override
  ConsumerState<TrackCardDemo> createState() => _TrackCardDemoState();
}

class _TrackCardDemoState extends ConsumerState<TrackCardDemo> with SingleTickerProviderStateMixin {
  late bool isFavorite = widget.track.isFavorite;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void handlePressIn() => _scaleController.forward();

  void handlePressOut() => _scaleController.reverse();

  Future<void> _toggleFavourite() async {
    final res = await ref.read(playlistServiceProvider).toggleTrackToFavourite(widget.track.id);
    if (res == "added") {
      setState(() => isFavorite = true);
    } else if (res == "removed") {
      setState(() => isFavorite = false);
    }
    Fluttertoast.showToast(
      msg: res == "added" ? "Added to favourites" : "Removed from favourites",
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  @override
  Widget build(BuildContext context) {
    final artistName = widget.track.artistName ?? widget.track.artistType.name;
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => handlePressIn(),
        onTapUp: (_) {
          handlePressOut();
          widget.onTap?.call();
        },
        onTapCancel: handlePressOut,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha((0.3 * 255).toInt()), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                    child: Hero(
                      tag: "track-${widget.track.id}",
                      child: CachedNetworkImage(
                        imageUrl: widget.track.images.first,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                          child: Center(child: Icon(Icons.error_rounded)),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withAlpha((0.3 * 255).toInt()),
                          Colors.black.withAlpha((0.6 * 255).toInt()),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: GestureDetector(
                              onTap: () => Fluttertoast.showToast(msg: artistName),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      artistName,
                                      style: TextStyle(
                                        fontFamily: "SpotifyMixUI",
                                        color: Theme.of(context).colorScheme.onSurface.withAlpha((0.9 * 255).toInt()),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        shadows: const [
                                          Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 3),
                                        ],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: true,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            child: GestureDetector(
                              onTap: _toggleFavourite,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha((0.2 * 255).toInt()),
                                  shape: BoxShape.circle,
                                ),
                                child: FaIcon(
                                  isFavorite ? FontAwesomeIcons.solidCircleCheck : FontAwesomeIcons.heartPulse,
                                  color: isFavorite ? Colors.green : Theme.of(context).colorScheme.onSurface,
                                  size: isFavorite ? 18 : 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.track.name,
                              style: TextStyle(
                                fontFamily: "SpotifyMixUI",
                                fontSize: 18,
                                color: Colors.white.withAlpha(200),
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 4)],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsetsGeometry.zero,
                            constraints: const BoxConstraints(),
                            onPressed: widget.onPlay,
                            icon: Icon(
                              Icons.play_circle_rounded,
                              size: 48,
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(200),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
