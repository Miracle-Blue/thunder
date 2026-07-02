import 'package:flutter/material.dart';

/// Extension on [String] to get the method color.
extension StringX on String {
  /// Get the method color.
  Color get methodColor => switch (toUpperCase()) {
    'GET' => const Color(0xFF61affe),
    'POST' => const Color(0xFF49cc90),
    'PUT' => const Color(0xFFfca130),
    'DELETE' => const Color(0xFFf93e3e),
    'PATCH' => const Color(0xFFfca130),
    'OPTIONS' => const Color(0xFF9012fe),
    'HEAD' => const Color(0xFF8a3ffc),
    'TRACE' => const Color(0xFF6c757d),
    'CONNECT' => const Color(0xFF4a5568),
    'LINK' => const Color(0xFF0284c7),
    'UNLINK' => const Color(0xFFdc2626),
    _ => const Color(0xFF61affe),
  };

  /// Get the method background color: a dark tint of the method color
  /// (~12% of [methodColor] blended over the dark panel background).
  Color get methodBackgroundColor => switch (toUpperCase()) {
    'GET' => const Color(0xFF212A34),
    'POST' => const Color(0xFF1E2E26),
    'PUT' => const Color(0xFF33281B),
    'DELETE' => const Color(0xFF331D1D),
    'PATCH' => const Color(0xFF33281B),
    'OPTIONS' => const Color(0xFF261734),
    'HEAD' => const Color(0xFF261D33),
    'TRACE' => const Color(0xFF222324),
    'CONNECT' => const Color(0xFF1E1F22),
    'LINK' => const Color(0xFF15252D),
    'UNLINK' => const Color(0xFF301A1A),
    _ => const Color(0xFF212A34),
  };
}
