import 'dart:convert';

import '../models/socket_state.dart';
import '../models/thunder_web_socket_log.dart';

/// Signature of the callback receiving every [ThunderWebSocketLog] produced
/// by a [ThunderWebSocketInterceptor].
typedef ThunderWebSocketLogCallback = void Function(ThunderWebSocketLog log);

/// Converts raw WebSocket activity into [ThunderWebSocketLog] events.
///
/// One interceptor represents exactly one connection (one session row in
/// Thunder's Socket tab): it owns a unique [connectionId] and stamps every
/// event with it.
///
/// Obtain an instance wired into the Thunder overlay via
/// `Thunder.webSocketInterceptor` and call the `log*` methods around your
/// own WebSocket, or construct one directly with a custom [onLog] callback
/// (e.g. in tests):
///
/// ```dart
/// final interceptor = Thunder.webSocketInterceptor(uri: uri);
/// interceptor.logState(const SocketConnecting());
/// channel.stream.listen(interceptor.logReceived);
/// interceptor.logSent('hello');
/// channel.sink.add('hello');
/// ```
class ThunderWebSocketInterceptor {
  /// Creates an interceptor for a single WebSocket connection to [uri].
  ThunderWebSocketInterceptor({required this.uri, this.label, this.onLog})
    : connectionId =
          '${DateTime.now().microsecondsSinceEpoch}-${_connectionSeq++}';

  /// The remote endpoint of the connection.
  final Uri uri;

  /// Optional human-readable name for the session row.
  final String? label;

  /// Callback invoked with every produced log event.
  final ThunderWebSocketLogCallback? onLog;

  /// Unique identifier of the connection (session) this interceptor logs.
  final String connectionId;

  static int _connectionSeq = 0;

  int _eventSeq = 0;

  /// Records an outgoing frame.
  void logSent(Object? data) => _add(
    direction: ThunderWebSocketDirection.sent,
    message: data,
    byteSize: _byteSizeOf(data),
  );

  /// Records an incoming frame.
  void logReceived(Object? data) => _add(
    direction: ThunderWebSocketDirection.received,
    message: data,
    byteSize: _byteSizeOf(data),
  );

  /// Records a connection state transition.
  ///
  /// When [state] is a [SocketDisconnected], its close code, close reason
  /// and error are copied onto the log entry.
  void logState(SocketState state) {
    final disconnected = state is SocketDisconnected ? state : null;

    _add(
      direction: ThunderWebSocketDirection.state,
      state: state,
      closeCode: disconnected?.closeCode,
      closeReason: disconnected?.closeReason,
      error: disconnected?.error,
    );
  }

  /// Records a transport or protocol error.
  void logError(Object error, [StackTrace? stackTrace]) => _add(
    direction: ThunderWebSocketDirection.error,
    error: error,
    stackTrace: stackTrace,
  );

  /// Records a free-form informational annotation.
  void logSystem(String message) =>
      _add(direction: ThunderWebSocketDirection.system, message: message);

  void _add({
    required ThunderWebSocketDirection direction,
    Object? message,
    int byteSize = 0,
    SocketState? state,
    int? closeCode,
    String? closeReason,
    Object? error,
    StackTrace? stackTrace,
  }) => onLog?.call(
    ThunderWebSocketLog(
      id: '$connectionId-${_eventSeq++}',
      connectionId: connectionId,
      uri: uri,
      direction: direction,
      timestamp: DateTime.now(),
      byteSize: byteSize,
      message: message,
      state: state,
      closeCode: closeCode,
      closeReason: closeReason,
      error: error,
      stackTrace: stackTrace,
    ),
  );
}

int _byteSizeOf(Object? data) => switch (data) {
  null => 0,
  final String text => utf8.encode(text).length,
  final List<int> bytes => bytes.length,
  final Object object => utf8.encode(object.toString()).length,
};
