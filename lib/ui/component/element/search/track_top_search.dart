import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/utils/functions.dart';
import 'package:hugeicons/hugeicons.dart';

class TrackTopSearch extends StatefulWidget {
  final Track track;
  final VoidCallback onTap;
  final EdgeInsets padding;

  const TrackTopSearch({super.key, required this.track, required this.onTap, this.padding = const EdgeInsets.all(12)});

  @override
  State<TrackTopSearch> createState() => _TrackTopSearchState();
}

class _TrackTopSearchState extends State<TrackTopSearch> {
  Color _shadowColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _updateShadowColor();
  }

  Future<void> _updateShadowColor() async {
    final dominantColor = await getDominantColor(widget.track.images.first);
    if (!mounted) return;
    setState(() => _shadowColor = dominantColor);
  }

  @override
  Widget build(BuildContext context) {
    bool hasColor = _shadowColor != Colors.transparent;
    return Padding(
      padding: widget.padding,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasColor ? _shadowColor.withAlpha(75) : Theme.of(context).colorScheme.primaryContainer.withAlpha(100),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: 100,
                  height: 100,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: hasColor ? _shadowColor : Colors.black.withAlpha(50),
                        blurRadius: hasColor ? 160 : 4,
                        spreadRadius: hasColor ? 48 : 0,
                        offset: hasColor ? const Offset(0, 0) : const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CachedNetworkImage(imageUrl: widget.track.images.first),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.track.name,
                  style: const TextStyle(fontFamily: "SpotifyMixUI", fontSize: 32, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                Text(
                  widget.track.artistName ?? widget.track.artistType.name,
                  style: TextStyle(
                    fontFamily: "SpotifyMixUI",
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(155),
                  ),
                ),
              ],
            ),

            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                ),
                child: IconButton(
                  onPressed: widget.onTap,
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedPlay),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
