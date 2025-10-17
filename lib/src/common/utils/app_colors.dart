import 'dart:ui' show Color;

/// Constant class for colors of the package
sealed class AppColors {
  const AppColors._();

  /// The black color
  static const Color black = Color(0xFF000000);

  /// The white color
  static const Color white = Color(0xFFFFFFFF);

  /// The red color
  static const Color red = Color(0xFFFF2F22);

  /// The lava stone color
  static const Color lavaStone = Color(0xFF3b4151);

  /// The gunmetal color
  static const Color gunmetal = Color(0xFF2c303b);

  /// The gray russian color
  static const Color grayRussian = Color(0xFF909498);

  /// The magical malachite color
  static Color mainColor = const Color(0xFF2ccc84);

  /// The red light color
  static const Color redLight = Color(0xFFffecec);

  /// The red dark color
  static const Color redDark = Color(0xFFf93e3e);

  /// The green light color
  static const Color greenLight = Color(0xFFeefaf4);

  /// The green dark color
  static const Color greenDark = Color(0xFF49cc90);
}
