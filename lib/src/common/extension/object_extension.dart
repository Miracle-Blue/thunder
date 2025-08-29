import 'dart:convert';
import 'dart:isolate';

/// Extension on [Object] to convert it to a pretty JSON string.
extension ObjectExtension on Object? {
  /// Convert the object to a pretty JSON string asynchronously using an isolate.
  /// This method is asynchronous and returns a [Future] that resolves to a [String].
  ///
  /// Example:
  /// ```dart
  /// final json = await object.prettyJsonAsync;
  /// ```
  Future<String> get prettyJsonAsync async {
    if (this == null) return 'null';

    final receivePort = ReceivePort();
    await Isolate.spawn<List<Object?>>(_prettyJsonIsolate, [
      receivePort.sendPort,
      this,
    ]);

    return (await receivePort.first).toString();
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

void _prettyJsonIsolate(List<Object?> args) {
  final sendPort = args[0] as SendPort;
  final data = args[1];

  final prettyJson = const JsonEncoder.withIndent('  ').convert(data);
  sendPort.send(prettyJson);

  // Close the isolate
  Isolate.exit();
}
