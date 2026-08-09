import 'package:flutter_test/flutter_test.dart';
import 'package:thunder/thunder.dart';

void main() {
  group('ThunderWebSocketInterceptor', () {
    test('produces correctly shaped logs for every direction', () {
      final logs = <ThunderWebSocketLog>[];
      ThunderWebSocketInterceptor(
          uri: Uri.parse('wss://example.com/ws'),
          label: 'Test',
          onLog: logs.add,
        )
        ..logSent('abc')
        ..logReceived(<int>[1, 2, 3, 4])
        ..logState(
          const SocketDisconnected(closeCode: 1001, closeReason: 'bye'),
        )
        ..logError(StateError('boom'), StackTrace.current)
        ..logSystem('note');

      expect(logs, hasLength(5));

      final sent = logs[0];
      expect(sent.direction.isSent, isTrue);
      expect(sent.byteSize, 3);
      expect(sent.message, 'abc');
      expect(sent.messageText, 'abc');

      final received = logs[1];
      expect(received.direction.isReceived, isTrue);
      expect(received.byteSize, 4);
      expect(received.messageText, 'Binary frame (4 bytes)');

      final state = logs[2];
      expect(state.direction.isState, isTrue);
      expect(state.state, isA<SocketDisconnected>());
      expect(state.closeCode, 1001);
      expect(state.closeReason, 'bye');
      expect(state.messageText, 'Disconnected (code 1001, bye)');

      final error = logs[3];
      expect(error.direction.isError, isTrue);
      expect(error.error, isA<StateError>());
      expect(error.stackTrace, isNotNull);

      final system = logs[4];
      expect(system.direction.isSystem, isTrue);
      expect(system.messageText, 'note');

      expect(
        logs.map((log) => log.id).toSet(),
        hasLength(5),
        reason: 'every event id must be unique',
      );
      expect(
        logs.map((log) => log.connectionId).toSet(),
        hasLength(1),
        reason: 'all events belong to the same connection',
      );
      expect(logs.every((log) => log.uri.host == 'example.com'), isTrue);
    });

    test('interceptors get distinct connection ids', () {
      final first = ThunderWebSocketInterceptor(uri: Uri.parse('ws://a'));
      final second = ThunderWebSocketInterceptor(uri: Uri.parse('ws://a'));

      expect(first.connectionId, isNot(second.connectionId));
    });

    test('utf-8 byte sizes are computed for multi-byte text', () {
      final logs = <ThunderWebSocketLog>[];
      ThunderWebSocketInterceptor(
        uri: Uri.parse('ws://a'),
        onLog: logs.add,
      ).logSent('⚡');

      expect(logs.single.byteSize, 3);
    });

    test('disabled interceptor drops every event until re-enabled', () {
      final logs = <ThunderWebSocketLog>[];
      final interceptor =
          ThunderWebSocketInterceptor(
              uri: Uri.parse('ws://a'),
              onLog: logs.add,
              enabled: false,
            )
            ..logSent('abc')
            ..logReceived(<int>[1, 2])
            ..logState(const SocketConnected())
            ..logError(StateError('boom'))
            ..logSystem('note');

      expect(logs, isEmpty);

      interceptor
        ..enabled = true
        ..logSent('abc');

      expect(logs, hasLength(1));
      expect(logs.single.direction.isSent, isTrue);
    });

    test('state logs render human-readable text', () {
      final logs = <ThunderWebSocketLog>[];
      ThunderWebSocketInterceptor(uri: Uri.parse('ws://a'), onLog: logs.add)
        ..logState(const SocketConnecting())
        ..logState(const SocketConnected())
        ..logState(const SocketReconnecting(attempt: 2))
        ..logState(const SocketDisconnected());

      expect(logs.map((log) => log.messageText), [
        'Connecting…',
        'Connected',
        'Reconnecting (attempt 2)',
        'Disconnected',
      ]);
    });
  });
}
