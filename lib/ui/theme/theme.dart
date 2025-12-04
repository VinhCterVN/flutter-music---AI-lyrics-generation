import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff495d92),
      surfaceTint: Color(0xff495d92),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffdae2ff),
      onPrimaryContainer: Color(0xff314578),
      secondary: Color(0xff8b4a63),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffffd9e4),
      onSecondaryContainer: Color(0xff6f334b),
      tertiary: Color(0xff5a631e),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffdfe995),
      onTertiaryContainer: Color(0xff434b06),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfffaf8ff),
      onSurface: Color(0xff1a1b21),
      onSurfaceVariant: Color(0xff45464f),
      outline: Color(0xff757780),
      outlineVariant: Color(0xffc5c6d0),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2f3036),
      inversePrimary: Color(0xffb2c5ff),
      primaryFixed: Color(0xffdae2ff),
      onPrimaryFixed: Color(0xff001848),
      primaryFixedDim: Color(0xffb2c5ff),
      onPrimaryFixedVariant: Color(0xff314578),
      secondaryFixed: Color(0xffffd9e4),
      onSecondaryFixed: Color(0xff39071f),
      secondaryFixedDim: Color(0xffffb0cb),
      onSecondaryFixedVariant: Color(0xff6f334b),
      tertiaryFixed: Color(0xffdfe995),
      onTertiaryFixed: Color(0xff191e00),
      tertiaryFixedDim: Color(0xffc3cd7c),
      onTertiaryFixedVariant: Color(0xff434b06),
      surfaceDim: Color(0xffdad9e0),
      surfaceBright: Color(0xfffaf8ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff4f3fa),
      surfaceContainer: Color(0xffeeedf4),
      surfaceContainerHigh: Color(0xffe8e7ef),
      surfaceContainerHighest: Color(0xffe3e2e9),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff1f3466),
      surfaceTint: Color(0xff495d92),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff586ba2),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff5b233a),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff9c5872),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff333a00),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff69722c),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffaf8ff),
      onSurface: Color(0xff101116),
      onSurfaceVariant: Color(0xff34363e),
      outline: Color(0xff50525b),
      outlineVariant: Color(0xff6b6d75),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2f3036),
      inversePrimary: Color(0xffb2c5ff),
      primaryFixed: Color(0xff586ba2),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff3f5387),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff9c5872),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff7f4159),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff69722c),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff515915),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc6c6cd),
      surfaceBright: Color(0xfffaf8ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff4f3fa),
      surfaceContainer: Color(0xffe8e7ef),
      surfaceContainerHigh: Color(0xffdddce3),
      surfaceContainerHighest: Color(0xffd2d1d8),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff13295c),
      surfaceTint: Color(0xff495d92),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff33477b),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff4e1830),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff72354e),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff292f00),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff454d08),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffaf8ff),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff2a2c34),
      outlineVariant: Color(0xff474951),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2f3036),
      inversePrimary: Color(0xffb2c5ff),
      primaryFixed: Color(0xff33477b),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff1b3063),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff72354e),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff561f37),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff454d08),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff2f3600),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffb8b8bf),
      surfaceBright: Color(0xfffaf8ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff1f0f7),
      surfaceContainer: Color(0xffe3e2e9),
      surfaceContainerHigh: Color(0xffd4d4db),
      surfaceContainerHighest: Color(0xffc6c6cd),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffb2c5ff),
      surfaceTint: Color(0xffb2c5ff),
      onPrimary: Color(0xff182e60),
      primaryContainer: Color(0xff314578),
      onPrimaryContainer: Color(0xffdae2ff),
      secondary: Color(0xffffb0cb),
      onSecondary: Color(0xff541d35),
      secondaryContainer: Color(0xff6f334b),
      onSecondaryContainer: Color(0xffffd9e4),
      tertiary: Color(0xffc3cd7c),
      onTertiary: Color(0xff2d3400),
      tertiaryContainer: Color(0xff434b06),
      onTertiaryContainer: Color(0xffdfe995),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff121318),
      onSurface: Color(0xffe3e2e9),
      onSurfaceVariant: Color(0xffc5c6d0),
      outline: Color(0xff8f909a),
      outlineVariant: Color(0xff45464f),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe3e2e9),
      inversePrimary: Color(0xff495d92),
      primaryFixed: Color(0xffdae2ff),
      onPrimaryFixed: Color(0xff001848),
      primaryFixedDim: Color(0xffb2c5ff),
      onPrimaryFixedVariant: Color(0xff314578),
      secondaryFixed: Color(0xffffd9e4),
      onSecondaryFixed: Color(0xff39071f),
      secondaryFixedDim: Color(0xffffb0cb),
      onSecondaryFixedVariant: Color(0xff6f334b),
      tertiaryFixed: Color(0xffdfe995),
      onTertiaryFixed: Color(0xff191e00),
      tertiaryFixedDim: Color(0xffc3cd7c),
      onTertiaryFixedVariant: Color(0xff434b06),
      surfaceDim: Color(0xff090d13),
      surfaceBright: Color(0xff38393f),
      surfaceContainerLowest: Color(0xff0d0e13),
      surfaceContainerLow: Color(0xff1a1b21),
      surfaceContainer: Color(0xff1e1f25),
      surfaceContainerHigh: Color(0xff292a2f),
      surfaceContainerHighest: Color(0xff33343a),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffd2dbff),
      surfaceTint: Color(0xffb2c5ff),
      onPrimary: Color(0xff0a2355),
      primaryContainer: Color(0xff7c8fc8),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffffd0de),
      onSecondary: Color(0xff46122a),
      secondaryContainer: Color(0xffc57b96),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffd9e390),
      onTertiary: Color(0xff232800),
      tertiaryContainer: Color(0xff8d964c),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff121318),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffdbdbe6),
      outline: Color(0xffb0b1bb),
      outlineVariant: Color(0xff8f9099),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe3e2e9),
      inversePrimary: Color(0xff32467a),
      primaryFixed: Color(0xffdae2ff),
      onPrimaryFixed: Color(0xff000e33),
      primaryFixedDim: Color(0xffb2c5ff),
      onPrimaryFixedVariant: Color(0xff1f3466),
      secondaryFixed: Color(0xffffd9e4),
      onSecondaryFixed: Color(0xff2b0015),
      secondaryFixedDim: Color(0xffffb0cb),
      onSecondaryFixedVariant: Color(0xff5b233a),
      tertiaryFixed: Color(0xffdfe995),
      onTertiaryFixed: Color(0xff101300),
      tertiaryFixedDim: Color(0xffc3cd7c),
      onTertiaryFixedVariant: Color(0xff333a00),
      surfaceDim: Color(0xff121318),
      surfaceBright: Color(0xff43444a),
      surfaceContainerLowest: Color(0xff06070c),
      surfaceContainerLow: Color(0xff1c1d23),
      surfaceContainer: Color(0xff26282d),
      surfaceContainerHigh: Color(0xff313238),
      surfaceContainerHighest: Color(0xff3c3d43),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffedefff),
      surfaceTint: Color(0xffb2c5ff),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xffadc1fd),
      onPrimaryContainer: Color(0xff000926),
      secondary: Color(0xffffebf0),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xfffdabc8),
      onSecondaryContainer: Color(0xff20000e),
      tertiary: Color(0xffecf7a1),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffbfc978),
      onTertiaryContainer: Color(0xff0a0d00),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff121318),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xffefeffa),
      outlineVariant: Color(0xffc1c2cc),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe3e2e9),
      inversePrimary: Color(0xff32467a),
      primaryFixed: Color(0xffdae2ff),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xffb2c5ff),
      onPrimaryFixedVariant: Color(0xff000e33),
      secondaryFixed: Color(0xffffd9e4),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffffb0cb),
      onSecondaryFixedVariant: Color(0xff2b0015),
      tertiaryFixed: Color(0xffdfe995),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffc3cd7c),
      onTertiaryFixedVariant: Color(0xff101300),
      surfaceDim: Color(0xff121318),
      surfaceBright: Color(0xff4f5056),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff1e1f25),
      surfaceContainer: Color(0xff2f3036),
      surfaceContainerHigh: Color(0xff3a3b41),
      surfaceContainerHighest: Color(0xff45464c),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }


  ThemeData theme(ColorScheme colorScheme) => ThemeData(
     useMaterial3: true,
     brightness: colorScheme.brightness,
     colorScheme: colorScheme,
     textTheme: textTheme.apply(
       bodyColor: colorScheme.onSurface,
       displayColor: colorScheme.onSurface,
     ),
     scaffoldBackgroundColor: colorScheme.surface,
     canvasColor: colorScheme.surface,
  );


  List<ExtendedColor> get extendedColors => [
  ];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
