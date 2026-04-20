import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/ui/component/element/avatar.dart';
import 'package:flutter_ai_music/ui/component/element/dashed_circle_painter.dart';
import 'package:flutter_ai_music/ui/component/navigation/track_options_bottom_sheet.dart';

Widget avatarWithUploadingBorder({required BuildContext context, required String photoUrl, required bool isUploading}) {
  return SizedBox(
    width: 72,
    height: 72,
    child: CustomPaint(
      painter: isUploading ? DashedCirclePainter(color: Colors.yellow, strokeWidth: 3) : null,
      child: Padding(
        padding: EdgeInsets.all(isUploading ? 2 : 0),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: AvatarContent(photoUrl: photoUrl),
        ),
      ),
    ),
  );
}

void showTrackOptions(Track track, BuildContext context) {
  showModalBottomSheet(
    context: context,
    isDismissible: true,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      snap: true,
      snapSizes: [0.5, 0.75],
      initialChildSize: 0.5,
      minChildSize: 0.5,
      maxChildSize: 0.75,
      builder: (context, scrollController) => TrackOptionsBottomSheet(track: track, scrollController: scrollController),
    ),
  );
}
