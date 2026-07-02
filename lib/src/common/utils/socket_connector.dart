import 'package:web_socket_channel/web_socket_channel.dart';

/// Opens a [WebSocketChannel] to [uri] on platforms without `dart:io`.
///
/// Browser WebSockets cannot send custom [headers] or protocol-level pings,
/// so those parameters are accepted for signature compatibility with the
/// `dart:io` connector but are ignored here.
WebSocketChannel connectWebSocketChannel(
  Uri uri, {
  Iterable<String>? protocols,
  Map<String, Object?>? headers,
  Duration? pingInterval,
}) => WebSocketChannel.connect(uri, protocols: protocols);
