import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';

class ArtistShortcut extends StatefulWidget {
  final String? artistName;
  final VoidCallback onTap;

  const ArtistShortcut({
    super.key,
    required this.onTap,
    this.artistName,
  });

  @override
  State<ArtistShortcut> createState() => _ArtistShortcutState();
}

class _ArtistShortcutState extends State<ArtistShortcut> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Text(
        widget.artistName ?? "Unknown",
        style: TextStyle(
          fontFamily: "SpotifyMixUI",
          fontSize: 14,
          color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha((0.7 * 255).toInt()),
        ),
      ),
    );
  }
}
