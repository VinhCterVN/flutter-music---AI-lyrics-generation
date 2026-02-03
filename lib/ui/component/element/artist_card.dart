import 'dart:developer' as developer;
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/artist_provider.dart';
import 'package:flutter_ai_music/utils/functions.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';

import '../navigation/fullscreen_image_page.dart';

class ArtistCard extends ConsumerStatefulWidget {
  final BorderRadius borderRadius;
  final BorderRadius imageBorderRadius;

  const ArtistCard({super.key, required this.borderRadius, required this.imageBorderRadius});

  @override
  ConsumerState<ArtistCard> createState() => _ArtistCardState();
}

class _ArtistCardState extends ConsumerState<ArtistCard> {
  bool _followed = false;
  int? _maxLine = 4;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      developer.log("Fetching artist summary...");
      final currentArtist = ref.read(currentArtistProvider).value;
      if (currentArtist == null) return;
      final status = await ref.read(artistServiceProvider).getFollowStatus(currentArtist.id);
      if (!mounted) return;
      setState(() => _followed = status);
    });
  }

  Future<void> getFollowStatus(String artistId) async {
    final status = await ref.read(artistServiceProvider).getFollowStatus(artistId);
    setState(() => _followed = status);
  }

  Future<String> _toggleFollow(String artistId, ArtistType type) async {
    final message = await ref.read(artistServiceProvider).toggleFollowArtist(artistId, type);
    final status = await ref.read(artistServiceProvider).getFollowStatus(artistId);
    setState(() => _followed = status);
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final currentArtist = ref.watch(currentArtistProvider).value;
    final currentSummary = ref.watch(artistSummaryProvider).value;
    ref.listen(currentArtistProvider, (prev, nex) {
      if (prev?.value?.id == nex.value?.id) return;

      getFollowStatus(nex.value?.id ?? '');
    });

    final imageUrl = currentArtist != null
        ? currentArtist.images.first.url
        : 'https://picsum.photos/1000/500?random=1000';

    return AnimatedSize(
      alignment: Alignment.topCenter,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha((0.3 * 255).toInt()),
          borderRadius: widget.borderRadius,
        ),
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
                      pageBuilder: (_, __, ___) => FullscreenImagePage(imageUrl: imageUrl),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: widget.borderRadius.topLeft,
                      topRight: widget.borderRadius.topRight,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
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
                      "About the artist",
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
                        onPressed: () async {
                          final message = await _toggleFollow(currentArtist?.id ?? '', ArtistType.SpotifyArtist);
                          Fluttertoast.showToast(msg: message);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withAlpha((0.2 * 255).toInt()),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          child: Row(
                            spacing: 4,
                            children: [
                              HugeIcon(
                                icon: _followed
                                    ? HugeIconsStrokeRounded.tickDouble01
                                    : HugeIcons.strokeRoundedLinkForward,
                              ),
                              Text(
                                _followed ? 'Following' : 'Follow',
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
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
                  GestureDetector(
                    onTap: () => setState(() {
                      if (_maxLine == 4) {
                        _maxLine = null;
                      } else {
                        _maxLine = 4;
                      }
                    }),
                    child: Text(
                      stripHtml(currentSummary?.extract ?? "No summary available for this artist."),
                      style: TextStyle(color: Colors.white.withAlpha((0.7 * 255).toInt()), fontSize: 13, height: 1.4),
                      maxLines: _maxLine,
                      overflow: _maxLine == null ? TextOverflow.visible : TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
