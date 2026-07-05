import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Extension on [Object] to convert it to a pretty JSON string.
extension ObjectExtension on Object? {
  /// Convert the object to a pretty JSON string on a background isolate
  /// (on the main isolate on web, where isolates are unavailable).
  /// This method is asynchronous and returns a
  /// [Future] that resolves to a [String].
  ///
  /// Example:
  /// ```dart
  /// final json = await object.prettyJsonAsync;
  /// ```
  Future<String> get prettyJsonAsync async {
    if (this == null) return 'null';

    return compute(_prettyJson, this);
  }

  /// Convert the object to a pretty JSON string synchronously.
  ///
  /// Example:
  /// ```dart
  /// final json = object.prettyJson;
  /// ```
  String get prettyJson => const JsonEncoder.withIndent('  ').convert(this);

  /// Convert the encoded body to a pretty JSON string synchronously.
  ///
  /// Example:
  /// ```dart
  /// final json = object.prettyJsonEncodedBody;
  /// ```
  String get prettyJsonEncodedBody {
    try {
      if (this == null || (this is String && (this as String).isEmpty)) {
        return const JsonEncoder.withIndent('  ').convert(toString());
      }

      return const JsonEncoder.withIndent('  ').convert(jsonDecode(toString()));
    } on Object catch (e) {
      return 'Error: $e';
    }
  }
}

String _prettyJson(Object? data) =>
    const JsonEncoder.withIndent('  ').convert(data);
