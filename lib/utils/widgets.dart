import 'package:flutter/material.dart';
import 'package:flutter_ai_music/ui/component/element/avatar.dart';
import 'package:flutter_ai_music/ui/component/element/dashed_circle_painter.dart';

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
