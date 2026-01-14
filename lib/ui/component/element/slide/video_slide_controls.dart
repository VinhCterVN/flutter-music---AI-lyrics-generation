import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoSlideControls extends StatefulWidget {
  final VideoState state;
  const VideoSlideControls({super.key, required this.state});

  @override
  State<VideoSlideControls> createState() => _VideoSlideControlsState();
}

class _VideoSlideControlsState extends State<VideoSlideControls> {


  @override
  Widget build(BuildContext context) {
    return Positioned.fill(child: GestureDetector(

    ));
  }
}
