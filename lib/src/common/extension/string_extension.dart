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

  /// Get the method background color.
  Color get methodBackgroundColor => switch (toUpperCase()) {
    'GET' => const Color(0xFFf0f7ff),
    'POST' => const Color(0xFFeefaf4),
    'PUT' => const Color(0xFFfff6ec),
    'DELETE' => const Color(0xFFffecec),
    'PATCH' => const Color(0xFFfff6ec),
    'OPTIONS' => const Color(0xFFf5f0ff),
    'HEAD' => const Color(0xFFf0f0ff),
    'TRACE' => const Color(0xFFf1f3f5),
    'CONNECT' => const Color(0xFFedf2f7),
    'LINK' => const Color(0xFFe0f2fe),
    'UNLINK' => const Color(0xFFfef2f2),
    _ => const Color(0xFFf0f7ff),
  };
}
