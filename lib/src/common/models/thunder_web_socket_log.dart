import 'package:flutter/foundation.dart';

import 'socket_state.dart';

/// The kind of event a [ThunderWebSocketLog] describes.
enum ThunderWebSocketDirection {
  /// A message sent to the server.
  sent,

  /// A message received from the server.
  received,

  /// A connection state transition (connecting, connected, ...).
  state,

  /// A transport or protocol error.
  error,

  /// A free-form informational annotation.
  system;

  /// Whether this is a [ThunderWebSocketDirection.sent] event.
  bool get isSent => this == ThunderWebSocketDirection.sent;

  /// Whether this is a [ThunderWebSocketDirection.received] event.
  bool get isReceived => this == ThunderWebSocketDirection.received;

  /// Whether this is a [ThunderWebSocketDirection.state] event.
  bool get isState => this == ThunderWebSocketDirection.state;

  /// Whether this is a [ThunderWebSocketDirection.error] event.
  bool get isError => this == ThunderWebSocketDirection.error;

  /// Whether this is a [ThunderWebSocketDirection.system] event.
  bool get isSystem => this == ThunderWebSocketDirection.system;
}

/// A single immutable event on a WebSocket connection's timeline:
/// a sent/received frame, a state transition, an error or an annotation.
@immutable
final class ThunderWebSocketLog {
  /// Constructor for the [ThunderWebSocketLog] class.
  const ThunderWebSocketLog({
    required this.id,
    required this.connectionId,
    required this.uri,
    required this.direction,
    required this.timestamp,
    required this.byteSize,
    this.message,
    this.state,
    this.closeCode,
    this.closeReason,
    this.error,
    this.stackTrace,
  });

  /// Unique identifier of this event.
  final String id;

  /// Identifier of the connection (session) this event belongs to.
  final String connectionId;

  /// The remote endpoint of the connection.
  final Uri uri;

  /// The kind of event.
  final ThunderWebSocketDirection direction;

  /// When the event happened.
  final DateTime timestamp;

  /// Payload size in bytes; `0` for non-frame events.
  final int byteSize;

  /// The frame payload (usually a [String] or a `List<int>`), when the
  /// event is a sent/received frame or an annotation.
  final Object? message;

  /// The new connection state, when [direction] is
  /// [ThunderWebSocketDirection.state].
  final SocketState? state;

  /// The WebSocket close code, when the event describes a disconnect.
  final int? closeCode;

  /// The WebSocket close reason, when the event describes a disconnect.
  final String? closeReason;

  /// The error, when [direction] is [ThunderWebSocketDirection.error] or
  /// the disconnect was caused by a failure.
  final Object? error;

  /// The stack trace accompanying [error], if any.
  final StackTrace? stackTrace;

  /// Human-readable text of this event, used for display and copying.
  String get messageText => switch (direction) {
    ThunderWebSocketDirection.sent ||
    ThunderWebSocketDirection.received => switch (message) {
      final String text => text,
      final List<int> bytes => 'Binary frame (${bytes.length} bytes)',
      null => '',
      final Object object => object.toString(),
    },
    ThunderWebSocketDirection.state => _stateText,
    ThunderWebSocketDirection.error => error?.toString() ?? 'Unknown error',
    ThunderWebSocketDirection.system => message?.toString() ?? '',
  };

  String get _stateText => switch (state) {
    SocketConnecting() => 'Connecting…',
    SocketConnected() => 'Connected',
    SocketReconnecting(:final attempt) => 'Reconnecting (attempt $attempt)',
    final SocketDisconnected disconnected => _disconnectedText(disconnected),
    null => 'Unknown state',
  };

  static String _disconnectedText(SocketDisconnected disconnected) {
    final details = <String>[
      if (disconnected.closeCode case final int code) 'code $code',
      if (disconnected.closeReason case final String reason
          when reason.isNotEmpty)
        reason,
      if (disconnected.error case final Object error) '$error',
    ];

    if (details.isEmpty) return 'Disconnected';

    return 'Disconnected (${details.join(', ')})';
  }

  @override
  String toString() =>
      'ThunderWebSocketLog('
      'id: $id, '
      'connectionId: $connectionId, '
      'uri: $uri, '
      'direction: $direction, '
      'timestamp: $timestamp, '
      'byteSize: $byteSize, '
      'message: $message, '
      'state: $state, '
      'closeCode: $closeCode, '
      'closeReason: $closeReason, '
      'error: $error)';
}
