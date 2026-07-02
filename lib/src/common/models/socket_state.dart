/// The lifecycle state of a WebSocket connection.
///
/// Emitted by `SocketClient.states` and recorded in the Thunder Socket
/// timeline. The concrete states are:
///
/// - [SocketConnecting] — the very first connection attempt is in progress
/// - [SocketConnected] — the connection is established
/// - [SocketReconnecting] — the connection dropped and a retry is pending
/// - [SocketDisconnected] — the connection is down
sealed class SocketState {
  /// Const constructor shared by all concrete states.
  const SocketState();
}

/// The initial connection attempt is in progress.
final class SocketConnecting extends SocketState {
  /// Creates a [SocketConnecting] state.
  const SocketConnecting();

  @override
  String toString() => 'SocketConnecting()';
}

/// The connection is established and messages can be exchanged.
final class SocketConnected extends SocketState {
  /// Creates a [SocketConnected] state.
  const SocketConnected();

  @override
  String toString() => 'SocketConnected()';
}

/// The connection dropped and a reconnect attempt is pending or running.
final class SocketReconnecting extends SocketState {
  /// Creates a [SocketReconnecting] state for the given [attempt].
  const SocketReconnecting({required this.attempt});

  /// The 1-based number of the pending reconnect attempt.
  ///
  /// Resets after every successful connection.
  final int attempt;

  @override
  String toString() => 'SocketReconnecting(attempt: $attempt)';
}

/// The connection is down.
///
/// Carries optional details about why it went down: a close frame's
/// [closeCode]/[closeReason] or the [error] that broke the connection.
final class SocketDisconnected extends SocketState {
  /// Creates a [SocketDisconnected] state.
  const SocketDisconnected({this.closeCode, this.closeReason, this.error});

  /// The WebSocket close code, when a close frame was received or sent.
  final int? closeCode;

  /// The WebSocket close reason, when a close frame was received or sent.
  final String? closeReason;

  /// The error that caused the disconnect, when the connection failed
  /// rather than closed cleanly.
  final Object? error;

  @override
  String toString() =>
      'SocketDisconnected('
      'closeCode: $closeCode, '
      'closeReason: $closeReason, '
      'error: $error)';
}
