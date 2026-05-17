import 'package:flutter/material.dart';

TextTheme createTextTheme(BuildContext context, String bodyFontFamily, String displayFontFamily) {
  final baseTextTheme = Theme.of(context).textTheme;

  final bodyTextTheme = baseTextTheme.apply(fontFamily: bodyFontFamily);

  final displayTextTheme = baseTextTheme.apply(fontFamily: displayFontFamily);

  return displayTextTheme.copyWith(
    bodyLarge: bodyTextTheme.bodyLarge,
    bodyMedium: bodyTextTheme.bodyMedium,
    bodySmall: bodyTextTheme.bodySmall,
    labelLarge: bodyTextTheme.labelLarge,
    labelMedium: bodyTextTheme.labelMedium,
    labelSmall: bodyTextTheme.labelSmall,
  );
}
