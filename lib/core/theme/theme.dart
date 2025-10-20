import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextTheme createTextTheme(
  BuildContext context,
  String bodyFontString,
  String displayFontString,
) {
  TextTheme baseTextTheme = Theme.of(context).textTheme;
  TextTheme bodyTextTheme = GoogleFonts.getTextTheme(
    bodyFontString,
    baseTextTheme,
  );
  TextTheme displayTextTheme = GoogleFonts.getTextTheme(
    displayFontString,
    baseTextTheme,
  );
  TextTheme textTheme = displayTextTheme.copyWith(
    bodyLarge: bodyTextTheme.bodyLarge,
    bodyMedium: bodyTextTheme.bodyMedium,
    bodySmall: bodyTextTheme.bodySmall,
    labelLarge: bodyTextTheme.labelLarge,
    labelMedium: bodyTextTheme.labelMedium,
    labelSmall: bodyTextTheme.labelSmall,
  );
  return textTheme;
}

class ColorFamily {
  final Color color;

  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });
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

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  List<ExtendedColor> get extendedColors => [];

  ThemeData dark() {
    return theme(darkScheme());
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
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

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffedefff),
      surfaceTint: Color(0xffb3c5ff),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xffaec1ff),
      onPrimaryContainer: Color(0xff000927),
      secondary: Color(0xffd0ff92),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xff99d44c),
      onSecondaryContainer: Color(0xff050e00),
      tertiary: Color(0xffe8f0ff),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xff9ec6f6),
      onTertiaryContainer: Color(0xff000c1b),
      error: Color(0xffffecea),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea8),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff11131a),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xffedefff),
      outlineVariant: Color(0xffbfc2d2),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe2e2ec),
      inversePrimary: Color(0xff0040a8),
      primaryFixed: Color(0xffdbe1ff),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xffb3c5ff),
      onPrimaryFixedVariant: Color(0xff000e34),
      secondaryFixed: Color(0xffb8f569),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xff9dd84f),
      onSecondaryFixedVariant: Color(0xff091400),
      tertiaryFixed: Color(0xffd1e4ff),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffa2cafa),
      onTertiaryFixedVariant: Color(0xff001225),
      surfaceDim: Color(0xff11131a),
      surfaceBright: Color(0xff4e5058),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff1d1f27),
      surfaceContainer: Color(0xff2e3038),
      surfaceContainerHigh: Color(0xff393b43),
      surfaceContainerHighest: Color(0xff45464e),
    );
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffd2dbff),
      surfaceTint: Color(0xffb3c5ff),
      onPrimary: Color(0xff00215f),
      primaryContainer: Color(0xff5f8bff),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffb2ee63),
      onSecondary: Color(0xff182b00),
      secondaryContainer: Color(0xff8bc43e),
      onSecondaryContainer: Color(0xff1a2d00),
      tertiary: Color(0xffc6deff),
      onTertiary: Color(0xff002746),
      tertiaryContainer: Color(0xff99c1f1),
      onTertiaryContainer: Color(0xff003257),
      error: Color(0xffffd2ce),
      onError: Color(0xff540007),
      errorContainer: Color(0xffff5451),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff11131a),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffd9dbec),
      outline: Color(0xffaeb1c1),
      outlineVariant: Color(0xff8d909f),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe2e2ec),
      inversePrimary: Color(0xff0040a8),
      primaryFixed: Color(0xffdbe1ff),
      onPrimaryFixed: Color(0xff000e34),
      primaryFixedDim: Color(0xffb3c5ff),
      onPrimaryFixedVariant: Color(0xff003082),
      secondaryFixed: Color(0xffb8f569),
      onSecondaryFixed: Color(0xff091400),
      secondaryFixedDim: Color(0xff9dd84f),
      onSecondaryFixedVariant: Color(0xff243d00),
      tertiaryFixed: Color(0xffd1e4ff),
      onTertiaryFixed: Color(0xff001225),
      tertiaryFixedDim: Color(0xffa2cafa),
      onTertiaryFixedVariant: Color(0xff013861),
      surfaceDim: Color(0xff11131a),
      surfaceBright: Color(0xff42444c),
      surfaceContainerLowest: Color(0xff06070d),
      surfaceContainerLow: Color(0xff1b1d24),
      surfaceContainer: Color(0xff26282f),
      surfaceContainerHigh: Color(0xff31323a),
      surfaceContainerHighest: Color(0xff3c3d45),
    );
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffb3c5ff),
      surfaceTint: Color(0xffb3c5ff),
      onPrimary: Color(0xff002a76),
      primaryContainer: Color(0xff0048bc),
      onPrimaryContainer: Color(0xffb0c3ff),
      secondary: Color(0xffa5e157),
      onSecondary: Color(0xff203700),
      secondaryContainer: Color(0xff8bc43e),
      onSecondaryContainer: Color(0xff2f4e00),
      tertiary: Color(0xffc1dcff),
      onTertiary: Color(0xff003257),
      tertiaryContainer: Color(0xff99c1f1),
      onTertiaryContainer: Color(0xff244f79),
      error: Color(0xffffb3ad),
      onError: Color(0xff68000a),
      errorContainer: Color(0xffff5451),
      onErrorContainer: Color(0xff410004),
      surface: Color(0xff11131a),
      onSurface: Color(0xffe2e2ec),
      onSurfaceVariant: Color(0xffc3c6d6),
      outline: Color(0xff8d909f),
      outlineVariant: Color(0xff434653),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe2e2ec),
      inversePrimary: Color(0xff2056ca),
      primaryFixed: Color(0xffdbe1ff),
      onPrimaryFixed: Color(0xff00184a),
      primaryFixedDim: Color(0xffb3c5ff),
      onPrimaryFixedVariant: Color(0xff003ea6),
      secondaryFixed: Color(0xffb8f569),
      onSecondaryFixed: Color(0xff102000),
      secondaryFixedDim: Color(0xff9dd84f),
      onSecondaryFixedVariant: Color(0xff304f00),
      tertiaryFixed: Color(0xffd1e4ff),
      onTertiaryFixed: Color(0xff001d36),
      tertiaryFixedDim: Color(0xffa2cafa),
      onTertiaryFixedVariant: Color(0xff1c4972),
      surfaceDim: Color(0xff11131a),
      surfaceBright: Color(0xff373941),
      surfaceContainerLowest: Color(0xff0c0e15),
      surfaceContainerLow: Color(0xff191b22),
      surfaceContainer: Color(0xff1d1f27),
      surfaceContainerHigh: Color(0xff282a31),
      surfaceContainerHighest: Color(0xff33343c),
    );
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff00266d),
      surfaceTint: Color(0xff2056ca),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff0041ab),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff1d3200),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff325200),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff002e51),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff1f4b75),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600009),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff970014),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffaf8ff),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff282c38),
      outlineVariant: Color(0xff454956),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2e3038),
      inversePrimary: Color(0xffb3c5ff),
      primaryFixed: Color(0xff0041ab),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff002c7b),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff325200),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff213900),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff1f4b75),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff00345b),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffb8b8c2),
      surfaceBright: Color(0xfffaf8ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff0f0fa),
      surfaceContainer: Color(0xffe2e2ec),
      surfaceContainerHigh: Color(0xffd3d4de),
      surfaceContainerHighest: Color(0xffc5c6d0),
    );
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff003082),
      surfaceTint: Color(0xff2056ca),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff0048bc),
      onPrimaryContainer: Color(0xfff0f1ff),
      secondary: Color(0xff243d00),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff4c7900),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff013861),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff47709b),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff73000d),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c30),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffaf8ff),
      onSurface: Color(0xff0f1118),
      onSurfaceVariant: Color(0xff323642),
      outline: Color(0xff4f525f),
      outlineVariant: Color(0xff696c7b),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2e3038),
      inversePrimary: Color(0xffb3c5ff),
      primaryFixed: Color(0xff3566d9),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff0b4cc0),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff4c7900),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff3a5e00),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff47709b),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff2d5781),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc5c6d0),
      surfaceBright: Color(0xfffaf8ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff3f3fd),
      surfaceContainer: Color(0xffe7e7f1),
      surfaceContainerHigh: Color(0xffdcdce6),
      surfaceContainerHighest: Color(0xffd1d1db),
    );
  }

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff00338b),
      surfaceTint: Color(0xff2056ca),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff0048bc),
      onPrimaryContainer: Color(0xffb0c3ff),
      secondary: Color(0xff416900),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff8bc43e),
      onSecondaryContainer: Color(0xff2f4e00),
      tertiary: Color(0xff38618c),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff99c1f1),
      onTertiaryContainer: Color(0xff244f79),
      error: Color(0xffb61722),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffda3437),
      onErrorContainer: Color(0xfffffbff),
      surface: Color(0xfffaf8ff),
      onSurface: Color(0xff191b22),
      onSurfaceVariant: Color(0xff434653),
      outline: Color(0xff737685),
      outlineVariant: Color(0xffc3c6d6),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2e3038),
      inversePrimary: Color(0xffb3c5ff),
      primaryFixed: Color(0xffdbe1ff),
      onPrimaryFixed: Color(0xff00184a),
      primaryFixedDim: Color(0xffb3c5ff),
      onPrimaryFixedVariant: Color(0xff003ea6),
      secondaryFixed: Color(0xffb8f569),
      onSecondaryFixed: Color(0xff102000),
      secondaryFixedDim: Color(0xff9dd84f),
      onSecondaryFixedVariant: Color(0xff304f00),
      tertiaryFixed: Color(0xffd1e4ff),
      onTertiaryFixed: Color(0xff001d36),
      tertiaryFixedDim: Color(0xffa2cafa),
      onTertiaryFixedVariant: Color(0xff1c4972),
      surfaceDim: Color(0xffd9d9e3),
      surfaceBright: Color(0xfffaf8ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff3f3fd),
      surfaceContainer: Color(0xffededf7),
      surfaceContainerHigh: Color(0xffe7e7f1),
      surfaceContainerHighest: Color(0xffe2e2ec),
    );
  }
}
