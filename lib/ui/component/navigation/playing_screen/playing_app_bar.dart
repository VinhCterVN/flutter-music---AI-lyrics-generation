import 'package:flutter/material.dart';

import '../../../../data/models/track.dart';
import '../../../../utils/widgets.dart';

/// Extracted SliverAppBar for the playing screen.
/// This is a plain StatelessWidget with no providers — it never rebuilds
/// unless [track] identity changes (which only happens on song switch).
class PlayingAppBar extends StatelessWidget {
  final Track track;

  const PlayingAppBar({super.key, required this.track});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      toolbarHeight: kToolbarHeight + 18,
      leading: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.keyboard_arrow_down),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: IconButton(
            onPressed: () => showTrackOptions(track, context),
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ),
      ],
      flexibleSpace: const FlexibleSpaceBar(
        title: Text(
          'Playing View',
          style: TextStyle(
            fontSize: 22,
            fontFamily: "SpotifyMixUI",
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.transparent,
    );
  }
}
