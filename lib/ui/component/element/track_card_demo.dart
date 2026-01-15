import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../data/models/track.dart';

class TrackCardDemo extends StatefulWidget {
  final Track track;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onFavorite;

  const TrackCardDemo({super.key, required this.track, this.onTap, this.onPlay, this.onFavorite});

  @override
  State<TrackCardDemo> createState() => _TrackCardDemoState();
}

class _TrackCardDemoState extends State<TrackCardDemo> with SingleTickerProviderStateMixin {
  bool isFavorite = false;
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

  void handlePressIn() {
    _scaleController.forward();
  }

  void handlePressOut() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
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
                    imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.track.name,
                                  style: TextStyle(
                                    fontFamily: "SpotifyMixUI",
                                    fontSize: 18,
                                    color: Colors.white.withAlpha(200),
                                    fontWeight: FontWeight.bold,
                                    shadows: [Shadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 4)],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.fade,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.track.artistId,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant.withAlpha((0.9 * 255).toInt()),
                                    fontSize: 14,
                                    shadows: const [Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 3)],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.fade,
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isFavorite = !isFavorite;
                              });
                              widget.onFavorite?.call();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha((0.2 * 255).toInt()),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: IconButton(
                          padding: EdgeInsetsGeometry.zero,
                          constraints: const BoxConstraints(),
                          onPressed: widget.onPlay,
                          icon: Icon(
                            Icons.play_circle_rounded,
                            size: 48,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(200),
                          ),
                        ),
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
