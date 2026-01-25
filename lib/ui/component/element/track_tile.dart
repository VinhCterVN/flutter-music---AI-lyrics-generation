import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../data/models/track.dart';

class TrackTile extends StatefulWidget {
  final Track? track;
  final Function onTap;
  final Function onLongPress;
  final int? currentTrackId;

  const TrackTile({
    super.key,
    required this.track,
    required this.onTap,
    required this.onLongPress,
    required this.currentTrackId,
  });

  @override
  State<TrackTile> createState() => _TrackTileState();
}

class _TrackTileState extends State<TrackTile> {
  @override
  Widget build(BuildContext context) {
    if (widget.track == null) {
      return ListTile(
        visualDensity: VisualDensity(vertical: -3),
        minVerticalPadding: 0,
        leading: CircleAvatar(child: Icon(Icons.music_note_outlined)),
        title: Text(
          "Unknown Track",
          maxLines: 1,
          style: TextStyle(fontFamily: "SpotifyMixUI", fontWeight: FontWeight.bold),
        ),
        subtitle: Text("Unknown Artist", style: TextStyle(fontFamily: "SpotifyMixUI")),
      );
    }
    return ListTile(
      visualDensity: VisualDensity(vertical: -3),
      minVerticalPadding: 0,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        clipBehavior: Clip.antiAlias,
        child: CachedNetworkImage(
          imageUrl: widget.track!.images.first,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => const Icon(Icons.music_note_outlined),
          placeholder: (context, url) => Container(color: Colors.grey[800]),
        ),
      ),
      title: Text(
        widget.track!.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontFamily: "SpotifyMixUI", fontWeight: FontWeight.bold),
      ),
      titleAlignment: ListTileTitleAlignment.center,
      subtitle: Text(
        widget.track!.artistName ?? widget.track!.artistType.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontFamily: "SpotifyMixUI"),
      ),
      trailing: widget.currentTrackId == widget.track!.id ? HugeIcon(icon: HugeIcons.strokeRoundedWave) : null,
      onTap: () => widget.onTap(),
      onLongPress: () => widget.onLongPress(),
    );
  }
}
