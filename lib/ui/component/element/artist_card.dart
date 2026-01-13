import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/provider/artist_provider.dart';
import 'package:flutter_ai_music/utils/functions.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navigation/fullscreen_image_page.dart';

class ArtistCard extends ConsumerStatefulWidget {
  final BorderRadius borderRadius;
  final BorderRadius imageBorderRadius;

  const ArtistCard({super.key, required this.borderRadius, required this.imageBorderRadius});

  @override
  ConsumerState<ArtistCard> createState() => _ArtistCardState();
}

class _ArtistCardState extends ConsumerState<ArtistCard> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final currentArtist = ref.watch(currentArtistProvider).value;
    final currentSummary = ref.watch(artistSummaryProvider).value;

    final fallbackRandom = Random().nextInt(100000);
    final imageUrl = currentArtist != null
        ? currentArtist.images.first.url
        : 'https://picsum.photos/1000/500?random=$fallbackRandom';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(color: Colors.black.withAlpha((0.3 * 255).toInt()), borderRadius: widget.borderRadius),
      constraints: BoxConstraints(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context, rootNavigator: true).push(
                  PageRouteBuilder(
                    opaque: false,
                    barrierColor: Colors.black54,
                    transitionDuration: Duration(milliseconds: 300),
                    pageBuilder: (_, __, ___) => FullscreenImagePage(imageUrl: imageUrl),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: widget.borderRadius.topLeft,
                    topRight: widget.borderRadius.topRight,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeIn,
                    switchOutCurve: Curves.easeOut,
                    transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                    child: CachedNetworkImage(
                      key: ValueKey(imageUrl),
                      imageUrl: imageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Information about the artist",
                    style: TextStyle(
                      color: Colors.white.withAlpha((0.9 * 255).toInt()),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      shadows: const [Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 3)],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  spacing: 10,
                  children: [
                    Text(
                      "Artist Rating",
                      style: TextStyle(
                        color: Colors.white.withAlpha((0.9 * 255).toInt()),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    RatingBar(
                      initialRating: (currentArtist?.popularity ?? 0) / 100 * 5,
                      minRating: 0,
                      maxRating: 100,
                      allowHalfRating: true,
                      ratingWidget: RatingWidget(
                        full: Icon(Icons.star_rounded, color: Colors.amber, size: 8),
                        half: Icon(Icons.star_half_rounded, color: Colors.amber, size: 8),
                        empty: Icon(Icons.star_border_rounded, color: Colors.amber, size: 8),
                      ),
                      onRatingUpdate: (double value) {},
                      ignoreGestures: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '#28 in Vietnam',
                      style: TextStyle(color: Colors.white.withAlpha((0.6 * 255).toInt()), fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      currentArtist?.name ?? 'Unknown',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.verified, color: Colors.blue[400], size: 20),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withAlpha((0.2 * 255).toInt()),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text(
                        'Follow',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '68,2 millions of monthly listeners',
                  style: TextStyle(color: Colors.white.withAlpha((0.6 * 255).toInt()), fontSize: 12),
                ),
                const SizedBox(height: 12),
                Text(
                  stripHtml(currentSummary?.extract ?? "No summary available for this artist."),
                  style: TextStyle(color: Colors.white.withAlpha((0.7 * 255).toInt()), fontSize: 13, height: 1.4),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
