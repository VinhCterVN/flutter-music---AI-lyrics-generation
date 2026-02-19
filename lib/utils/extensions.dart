import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:just_audio/just_audio.dart';

extension LoopModeX on LoopMode {
  List<List<dynamic>> get icon {
    switch (this) {
      case LoopMode.one:
        return HugeIcons.strokeRoundedRepeatOne01;
      case LoopMode.all:
        return HugeIcons.strokeRoundedRepeat;
      case LoopMode.off:
        return HugeIcons.strokeRoundedRepeatOff;
    }
  }

  double get strokeWidth => this == LoopMode.off ? 1.5 : 3.0;

  Color color(BuildContext context) =>
      this == LoopMode.off ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.primary;
}

extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
