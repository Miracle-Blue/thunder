import 'dart:async';
import 'dart:developer' show log;

import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/socket_state.dart';
import 'socket_connector.dart' if (dart.library.io) 'socket_connector_io.dart';
import 'thunder_ws_interceptor.dart';

/// A reconnecting WebSocket client built on `package:web_socket_channel`.
///
/// The client dials [uri] when [connect] is called and keeps the connection
/// alive: whenever it drops (network error, server close, failed dial) a new
/// attempt is scheduled after [reconnectInterval], indefinitely, until
/// [close] is called.
///
/// ```dart
/// final socket = Thunder.socketClient(
///   uri: Uri.parse('wss://echo.websocket.org'),
/// );
///
/// socket.states.listen(onStateChanged);
/// socket.messages.listen(onMessage);
///
/// await socket.connect();
/// socket.send('hello');
/// // ...
/// await socket.close();
/// ```
///
/// Lifecycle notes:
///
/// - [connect] is idempotent: concurrent calls share one dial, calling it
///   while connected is a no-op, and calling it while a retry timer is
///   armed retries immediately. It never throws on connection failure —
///   failures surface on [states] as [SocketDisconnected] followed by
///   [SocketReconnecting].
/// - [close] is terminal: both streams complete, and [connect]/[send]
///   throw a [StateError] afterwards. Create a new client to reconnect.
/// - [messages] and [states] are broadcast streams without replay:
///   subscribe before calling [connect] to observe the first events, and
///   read [state] for the current value.
class SocketClient {
  /// Creates a client for [uri].
  ///
  /// No network activity happens until [connect] is called. Pass an
  /// [interceptor] to record the connection in Thunder's Socket tab —
  /// `Thunder.socketClient` does that for you.
  SocketClient({
    required this.uri,
    this.protocols,
    this.headers,
    this.reconnectInterval = const Duration(seconds: 5),
    this.connectTimeout,
    this.pingInterval,
    ThunderWebSocketInterceptor? interceptor,
  }) : _interceptor = interceptor;

  /// The WebSocket endpoint to connect to.
  final Uri uri;

  /// WebSocket subprotocols to negotiate, if any.
  final Iterable<String>? protocols;

  /// Extra HTTP headers for the upgrade request.
  ///
  /// Only supported on `dart:io` platforms; browsers ignore this.
  final Map<String, Object?>? headers;

  /// Delay between a connection loss and the next reconnect attempt.
  final Duration reconnectInterval;

  /// Maximum time a single connection attempt may take before it is
  /// aborted and retried. Unlimited when `null`.
  final Duration? connectTimeout;

  /// Interval of protocol-level ping frames keeping the connection alive.
  ///
  /// Only supported on `dart:io` platforms; browsers ignore this.
  final Duration? pingInterval;

  final ThunderWebSocketInterceptor? _interceptor;

  final StreamController<Object?> _messagesController =
      StreamController<Object?>.broadcast();

  final StreamController<SocketState> _statesController =
      StreamController<SocketState>.broadcast();

  SocketState _state = const SocketDisconnected();

  WebSocketChannel? _channel;
  StreamSubscription<Object?>? _channelSub;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  Future<void>? _connectFuture;
  Future<void>? _closeFuture;
  bool _closed = false;

  /// The current connection state.
  SocketState get state => _state;

  /// Broadcast stream of received frames (data only, never errors).
  ///
  /// Transport errors are reported through [states] and the Thunder
  /// timeline instead.
  Stream<Object?> get messages => _messagesController.stream;

  /// Broadcast stream of connection state transitions.
  Stream<SocketState> get states => _statesController.stream;

  /// Opens the connection.
  ///
  /// Returns a future that completes when the first attempt settles —
  /// successfully or not. On failure the client keeps retrying on its own;
  /// listen to [states] for the outcome. Throws a [StateError] when the
  /// client has been closed.
  Future<void> connect() {
    if (_closed) throw StateError('SocketClient has been closed');
    if (_state is SocketConnected) return Future<void>.value();

    return _connectOnce();
  }

  /// Sends a text ([String]) or binary (`List<int>`) frame.
  ///
  /// Throws an [ArgumentError] for other payload types and a [StateError]
  /// when the client is closed or not currently connected.
  void send(Object data) {
    if (_closed) throw StateError('SocketClient has been closed');
    if (data is! String && data is! List<int>) {
      throw ArgumentError.value(
        data,
        'data',
        'Only String or List<int> payloads are supported',
      );
    }

    final channel = _channel;
    if (channel == null || _state is! SocketConnected) {
      throw StateError('SocketClient is not connected (state: $_state)');
    }

    _interceptor?.logSent(data);
    channel.sink.add(data);
  }

  /// Closes the connection and disposes the client.
  ///
  /// Sends a close frame with [code] (defaults to `1000`, normal closure)
  /// and [reason] when a connection is open, emits a final
  /// [SocketDisconnected] and completes both streams. Terminal: [connect]
  /// and [send] throw afterwards. Calling [close] again returns the first
  /// call's future; later arguments are ignored.
  Future<void> close([int? code, String? reason]) {
    final pending = _closeFuture;
    if (pending != null) return pending;

    _closed = true;
    return _closeFuture = _doClose(code, reason);
  }

  Future<void> _connectOnce() =>
      _connectFuture ??= _establish().whenComplete(() => _connectFuture = null);

  Future<void> _establish() async {
    if (_closed) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    if (_reconnectAttempt == 0) _emitState(const SocketConnecting());

    log('Thunder SocketClient: connecting to $uri', name: 'TSC');

    final channel = connectWebSocketChannel(
      uri,
      protocols: protocols,
      headers: headers,
      pingInterval: pingInterval,
    );
    _channel = channel;

    try {
      final timeout = connectTimeout;
      await (timeout == null ? channel.ready : channel.ready.timeout(timeout));
    } on Object catch (error, stackTrace) {
      unawaited(_closeChannelQuietly(channel, status.goingAway));
      if (identical(_channel, channel)) _channel = null;
      if (_closed) return;

      _interceptor?.logError(error, stackTrace);
      log(
        'Thunder SocketClient: connect to $uri failed',
        error: error,
        stackTrace: stackTrace,
        name: 'TSC',
      );
      _scheduleReconnect(error: error);
      return;
    }

    if (_closed) {
      // close() raced the dial: tear the fresh channel down and bail out.
      unawaited(_closeChannelQuietly(channel, status.normalClosure));
      if (identical(_channel, channel)) _channel = null;
      return;
    }

    _reconnectAttempt = 0;
    _channelSub = channel.stream.listen(
      _onData,
      onError: _onStreamError,
      onDone: () => _onDone(channel),
      cancelOnError: false,
    );
    _emitState(const SocketConnected());
    log('Thunder SocketClient: connected to $uri', name: 'TSC');
  }

  void _scheduleReconnect({
    int? closeCode,
    String? closeReason,
    Object? error,
  }) {
    if (_closed) return;

    _emitState(
      SocketDisconnected(
        closeCode: closeCode,
        closeReason: closeReason,
        error: error,
      ),
    );
    _reconnectAttempt += 1;
    _emitState(SocketReconnecting(attempt: _reconnectAttempt));

    log(
      'Thunder SocketClient: retry #$_reconnectAttempt to $uri '
      'in ${reconnectInterval.inMilliseconds}ms',
      name: 'TSC',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectInterval, () {
      _reconnectTimer = null;
      if (_closed) return;
      unawaited(_connectOnce());
    });
  }

  void _emitState(SocketState next) {
    _state = next;
    _interceptor?.logState(next);
    if (!_statesController.isClosed) _statesController.add(next);
  }

  void _onData(Object? data) {
    if (_closed) return;

    _interceptor?.logReceived(data);
    if (!_messagesController.isClosed) _messagesController.add(data);
  }

  void _onStreamError(Object error, StackTrace stackTrace) {
    if (_closed) return;

    // The channel always follows an error with a done event; the reconnect
    // is scheduled in _onDone.
    _interceptor?.logError(error, stackTrace);
    log(
      'Thunder SocketClient: stream error ($uri)',
      error: error,
      stackTrace: stackTrace,
      name: 'TSC',
    );
  }

  void _onDone(WebSocketChannel channel) {
    // Ignore late callbacks of channels that were already replaced.
    if (!identical(channel, _channel)) return;

    unawaited(_channelSub?.cancel());
    _channelSub = null;
    _channel = null;

    if (_closed) return;

    log(
      'Thunder SocketClient: connection to $uri closed remotely',
      name: 'TSC',
    );
    _scheduleReconnect(
      closeCode: channel.closeCode,
      closeReason: channel.closeReason,
    );
  }

  Future<void> _doClose(int? code, String? reason) async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    // Let an in-flight dial settle; _establish never throws and tears its
    // own channel down once it observes the closed flag.
    await _connectFuture;

    await _channelSub?.cancel();
    _channelSub = null;

    final channel = _channel;
    _channel = null;
    if (channel != null) {
      await _closeChannelQuietly(channel, code ?? status.normalClosure, reason);
    }

    _emitState(
      SocketDisconnected(
        closeCode: channel == null ? code : (code ?? status.normalClosure),
        closeReason: reason,
      ),
    );

    // Not awaited: a paused broadcast subscription would delay the done
    // event indefinitely and deadlock close().
    unawaited(_messagesController.close());
    unawaited(_statesController.close());

    log('Thunder SocketClient: closed ($uri)', name: 'TSC');
  }

  Future<void> _closeChannelQuietly(
    WebSocketChannel channel, [
    int? code,
    String? reason,
  ]) async {
    try {
      await channel.sink.close(code, reason);
    } on Object catch (error, stackTrace) {
      log(
        'Thunder SocketClient: error closing channel',
        error: error,
        stackTrace: stackTrace,
        name: 'TSC',
      );
    }
  }
}
