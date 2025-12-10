import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ArtistCard extends ConsumerStatefulWidget {
  final BorderRadius borderRadius;
  final BorderRadius imageBorderRadius;
  final String artistId;
  final ArtistType artistType;

  const ArtistCard({
    super.key,
    required this.borderRadius,
    required this.imageBorderRadius,
    required this.artistId,
    required this.artistType,
  });

  @override
  ConsumerState<ArtistCard> createState() => _ArtistCardState();
}

class _ArtistCardState extends ConsumerState<ArtistCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(color: Colors.black.withAlpha((0.3 * 255).toInt()), borderRadius: widget.borderRadius),
      constraints: BoxConstraints(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: widget.borderRadius.topLeft,
                  topRight: widget.borderRadius.topRight,
                ),
                child: Image.network(
                  'https://picsum.photos/1000/500?random=${Random(1000)}',
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),

              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Giới thiệu về nghệ sĩ',
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
                Text(
                  'Giới thiệu về nghệ sĩ',
                  style: TextStyle(
                    color: Colors.white.withAlpha((0.9 * 255).toInt()),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '#28 trên thế giới',
                      style: TextStyle(color: Colors.white.withAlpha((0.6 * 255).toInt()), fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Dua Lipa',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
                        'Theo dõi',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '61,9 Tr người nghe hàng tháng',
                  style: TextStyle(color: Colors.white.withAlpha((0.6 * 255).toInt()), fontSize: 12),
                ),
                const SizedBox(height: 12),
                Text(
                  'Inspired by Dua\'s own self-discovery, Radical Optimism (out May 3) is the third album from 3x GRAMMY and 7x BRIT Award-wi... xem thêm',
                  style: TextStyle(color: Colors.white.withAlpha((0.7 * 255).toInt()), fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
