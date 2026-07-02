import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Opens a [WebSocketChannel] to [uri] using `dart:io` sockets.
///
/// Unlike the browser connector, this one supports custom [headers] and a
/// protocol-level [pingInterval].
WebSocketChannel connectWebSocketChannel(
  Uri uri, {
  Iterable<String>? protocols,
  Map<String, Object?>? headers,
  Duration? pingInterval,
}) => IOWebSocketChannel.connect(
  uri,
  protocols: protocols,
  headers: headers,
  pingInterval: pingInterval,
);
