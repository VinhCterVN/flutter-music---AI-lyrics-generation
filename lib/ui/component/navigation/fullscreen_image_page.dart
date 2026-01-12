import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FullscreenImagePage extends StatelessWidget {
  final String imageUrl;
  final String tag;

  const FullscreenImagePage({required this.imageUrl, required this.tag, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: PhotoView(
        imageProvider: CachedNetworkImageProvider(imageUrl),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
        backgroundDecoration: const BoxDecoration(color: Colors.transparent),
        heroAttributes: PhotoViewHeroAttributes(tag: tag),
      ),
    );
  }
}
