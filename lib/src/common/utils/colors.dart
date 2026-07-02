import 'package:flutter/material.dart';

/// {@template app_colors}
/// Emphasis class
/// Logger colors for the application:
/// {@endtemplate}
@immutable
final class ThunderColors extends ThemeExtension<ThunderColors> {
  /// {@macro app_colors}
  const ThunderColors({
    required this.cWhite,
    required this.cBlack,
    required this.cYellow,
    required this.cRed,
    required this.cGreen,
    required this.cMagenta,
    required this.cBlue,
    required this.cCyan,
    required this.cDefault,
    required this.thunderBackground,
    required this.brilliantAzure,
    required this.gray,
    required this.surface,
  });

  /// Gets the logger colors from the theme.
  factory ThunderColors.of(BuildContext context) {
    try {
      final theme = Theme.of(context);

      return theme.extension<ThunderColors>() ??
          switch (theme.brightness) {
            Brightness.light => ThunderColors.light,
            Brightness.dark => ThunderColors.dark,
          };
    } on Object {
      return ThunderColors.light;
    }
  }

  /// The background color of the thunder.
  final Color thunderBackground;

  /// The white color of the thunder.
  final Color cWhite;

  /// The black color of the thunder.
  final Color cBlack;

  /// The yellow color of the thunder.
  final Color cYellow;

  /// The red color of the thunder.
  final Color cRed;

  /// The green color of the thunder.
  final Color cGreen;

  /// The magenta color of the thunder.
  final Color cMagenta;

  /// The blue color of the thunder.
  final Color cBlue;

  /// The cyan color of the thunder.
  final Color cCyan;

  /// The default color of the thunder.
  final Color cDefault;

  /// The brilliant azure color.
  final Color brilliantAzure;

  /// The gray color.
  final Color gray;

  /// The elevated surface color (cards, buttons, handle, snackbar).
  final Color surface;

  /// The default light theme colors.
  static const light = ThunderColors(
    thunderBackground: Color(0xFFf2f2f2),
    cWhite: Color(0xFF555555),
    cBlack: Color(0xFF000000),
    cYellow: Color(0xFF787a01),
    cRed: Color(0xFFcd3131),
    cGreen: Color(0xFF0e7c10),
    cMagenta: Color(0xFFbc06bc),
    cBlue: Color(0xFF0000FF),
    cCyan: Color(0xFF00FFFF),
    cDefault: Color(0xFF000000),
    brilliantAzure: Color(0xFF3794ff),
    gray: Color(0xFF808080),
    surface: Color(0xFFffffff),
  );

  /// The default dark theme colors.
  static const dark = ThunderColors(
    thunderBackground: Color(0xFF181818),
    cWhite: Color(0xFFe5e5e5),
    cBlack: Color(0xFFd6d6d6),
    cYellow: Color(0xFFe5e50e),
    cRed: Color(0xFFd75959),
    cGreen: Color(0xFF0fbc7a),
    cMagenta: Color(0xFFc353c3),
    cBlue: Color(0xFF0000FF),
    cCyan: Color(0xFF00FFFF),
    cDefault: Color(0xFF000000),
    brilliantAzure: Color(0xFF3794ff),
    gray: Color(0xFF808080),
    surface: Color(0xFF262626),
  );

  @override
  ThunderColors copyWith({
    Color? thunderBackground,
    Color? cWhite,
    Color? cBlack,
    Color? cYellow,
    Color? cRed,
    Color? cGreen,
    Color? cMagenta,
    Color? cBlue,
    Color? cCyan,
    Color? cDefault,
    Color? brilliantAzure,
    Color? gray,
    Color? surface,
  }) => ThunderColors(
    // logViewer colors
    thunderBackground: thunderBackground ?? this.thunderBackground,
    cWhite: cWhite ?? this.cWhite,
    cBlack: cBlack ?? this.cBlack,
    cYellow: cYellow ?? this.cYellow,
    cRed: cRed ?? this.cRed,
    cGreen: cGreen ?? this.cGreen,
    cMagenta: cMagenta ?? this.cMagenta,
    cBlue: cBlue ?? this.cBlue,
    cCyan: cCyan ?? this.cCyan,
    cDefault: cDefault ?? this.cDefault,
    brilliantAzure: brilliantAzure ?? this.brilliantAzure,
    gray: gray ?? this.gray,
    surface: surface ?? this.surface,
  );

  @override
  ThemeExtension<ThunderColors> lerp(
    ThemeExtension<ThunderColors>? other,
    double t,
  ) => other is! ThunderColors
      ? this
      : ThunderColors(
          thunderBackground: Color.lerp(
            thunderBackground,
            other.thunderBackground,
            t,
          )!,
          cWhite: Color.lerp(cWhite, other.cWhite, t)!,
          cBlack: Color.lerp(cBlack, other.cBlack, t)!,
          cYellow: Color.lerp(cYellow, other.cYellow, t)!,
          cRed: Color.lerp(cRed, other.cRed, t)!,
          cGreen: Color.lerp(cGreen, other.cGreen, t)!,
          cMagenta: Color.lerp(cMagenta, other.cMagenta, t)!,
          cBlue: Color.lerp(cBlue, other.cBlue, t)!,
          cCyan: Color.lerp(cCyan, other.cCyan, t)!,
          cDefault: Color.lerp(cDefault, other.cDefault, t)!,
          brilliantAzure: Color.lerp(brilliantAzure, other.brilliantAzure, t)!,
          gray: Color.lerp(gray, other.gray, t)!,
          surface: Color.lerp(surface, other.surface, t)!,
        );

  @override
  String toString() => 'ThunderColors{}';
}
