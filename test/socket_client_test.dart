import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thunder/thunder.dart';

/// A local WebSocket echo server that can be shut down and rebound on the
/// same port to exercise the reconnect path.
final class EchoServer {
  EchoServer._(this._server);

  final HttpServer _server;
  final List<WebSocket> _sockets = <WebSocket>[];

  int get port => _server.port;

  static Future<EchoServer> bind({int port = 0}) async {
    final httpServer = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      port,
    );
    final server = EchoServer._(httpServer);

    httpServer.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      server._sockets.add(socket);
      socket.listen(socket.add, onError: (Object _) {}, cancelOnError: true);
    });

    return server;
  }

  /// Closes the listening socket and every upgraded connection (upgraded
  /// WebSockets are detached from the HttpServer, so `close(force: true)`
  /// alone would leave them alive).
  Future<void> shutdown() async {
    await _server.close(force: true);
    for (final socket in _sockets) {
      await socket.close();
    }
    _sockets.clear();
  }
}

Future<void> waitFor(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Condition not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

SocketClient clientFor(EchoServer server) => SocketClient(
  uri: Uri.parse('ws://127.0.0.1:${server.port}'),
  reconnectInterval: const Duration(milliseconds: 100),
  connectTimeout: const Duration(seconds: 5),
);

void main() {
  const testTimeout = Timeout(Duration(seconds: 15));

  group('SocketClient', () {
    test('connects and echoes messages', timeout: testTimeout, () async {
      final server = await EchoServer.bind();
      addTearDown(server.shutdown);

      final client = clientFor(server);
      addTearDown(client.close);

      final firstMessage = client.messages.first;

      await client.connect();
      expect(client.state, isA<SocketConnected>());

      client.send('hello');
      expect(await firstMessage, 'hello');
    });

    test('emits Connecting then Connected', timeout: testTimeout, () async {
      final server = await EchoServer.bind();
      addTearDown(server.shutdown);

      final client = clientFor(server);
      addTearDown(client.close);

      final states = <SocketState>[];
      final subscription = client.states.listen(states.add);
      addTearDown(subscription.cancel);

      await client.connect();
      await pumpEventQueue();

      expect(states, [isA<SocketConnecting>(), isA<SocketConnected>()]);
    });

    test(
      'reconnects after the server drops the connection',
      timeout: testTimeout,
      () async {
        var server = await EchoServer.bind();
        final port = server.port;

        final client = clientFor(server);
        addTearDown(client.close);
        addTearDown(() => server.shutdown());

        final states = <SocketState>[];
        final subscription = client.states.listen(states.add);
        addTearDown(subscription.cancel);

        await client.connect();
        expect(client.state, isA<SocketConnected>());

        // Drop the connection server-side.
        await server.shutdown();
        await waitFor(() => states.any((state) => state is SocketReconnecting));

        expect(states.whereType<SocketDisconnected>(), isNotEmpty);
        expect(
          states.whereType<SocketReconnecting>().first,
          isA<SocketReconnecting>().having(
            (state) => state.attempt,
            'attempt',
            1,
          ),
        );

        // Bring the server back on the same port; the client must recover
        // on its own.
        server = await EchoServer.bind(port: port);
        await waitFor(() => client.state is SocketConnected);

        final echo = client.messages.first;
        client.send('back');
        expect(await echo, 'back');
      },
    );

    test('close is terminal and idempotent', timeout: testTimeout, () async {
      final server = await EchoServer.bind();
      addTearDown(server.shutdown);

      final client = clientFor(server);

      final states = <SocketState>[];
      final subscription = client.states.listen(states.add);
      addTearDown(subscription.cancel);

      await client.connect();
      expect(client.state, isA<SocketConnected>());

      final first = client.close();
      final second = client.close();
      expect(identical(first, second), isTrue);
      await first;

      expect(
        client.state,
        isA<SocketDisconnected>().having(
          (state) => state.closeCode,
          'closeCode',
          1000,
        ),
      );
      expect(() => client.send('x'), throwsStateError);
      expect(client.connect, throwsStateError);

      // New subscribers of a closed client observe completed streams.
      await expectLater(client.messages, emitsDone);
      await expectLater(client.states, emitsDone);

      // No further events arrive after close.
      await pumpEventQueue();
      final observedEvents = states.length;
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(states.length, observedEvents);
    });

    test('concurrent connects share one dial', timeout: testTimeout, () async {
      final server = await EchoServer.bind();
      addTearDown(server.shutdown);

      final client = clientFor(server);
      addTearDown(client.close);

      final states = <SocketState>[];
      final subscription = client.states.listen(states.add);
      addTearDown(subscription.cancel);

      await Future.wait([client.connect(), client.connect()]);
      await pumpEventQueue();

      expect(client.state, isA<SocketConnected>());
      expect(states.whereType<SocketConnecting>().length, 1);
      expect(states.whereType<SocketConnected>().length, 1);
    });

    test(
      'keeps retrying while the endpoint is unreachable',
      timeout: testTimeout,
      () async {
        // Bind and immediately shut down to get a dead port.
        final server = await EchoServer.bind();
        final client = clientFor(server);
        addTearDown(client.close);
        await server.shutdown();

        final states = <SocketState>[];
        final subscription = client.states.listen(states.add);
        addTearDown(subscription.cancel);

        // connect() must not throw even though the dial fails.
        await client.connect();

        await waitFor(() => states.whereType<SocketReconnecting>().length >= 2);

        final attempts = states
            .whereType<SocketReconnecting>()
            .map((state) => state.attempt)
            .take(2)
            .toList();
        expect(attempts, [1, 2]);
        expect(states.whereType<SocketDisconnected>().first.error, isNotNull);
      },
    );

    test(
      'close completes while a silent dial is in flight',
      timeout: testTimeout,
      () async {
        // A raw TCP server that accepts and never answers the upgrade:
        // channel.ready would hang forever without the dial timeout.
        final accepted = <Socket>[];
        final silent = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        silent.listen(accepted.add);
        addTearDown(() async {
          for (final socket in accepted) {
            socket.destroy();
          }
          await silent.close();
        });

        final client = SocketClient(
          uri: Uri.parse('ws://127.0.0.1:${silent.port}'),
          reconnectInterval: const Duration(milliseconds: 100),
          connectTimeout: const Duration(milliseconds: 200),
        );

        final connectFuture = client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Must not hang on the in-flight dial.
        await client.close().timeout(const Duration(seconds: 5));
        await connectFuture;

        expect(client.state, isA<SocketDisconnected>());
      },
    );

    test('send rejects invalid payloads and states', () async {
      final server = await EchoServer.bind();
      addTearDown(server.shutdown);

      final client = clientFor(server);
      addTearDown(client.close);

      // Not connected yet.
      expect(() => client.send('nope'), throwsStateError);

      await client.connect();
      expect(() => client.send(42), throwsArgumentError);
    });
  });
}
