import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:thunder/src/common/models/thunder_network_log.dart';
import 'package:thunder/src/common/utils/thunder_interceptor.dart';
import 'package:thunder/thunder.dart';

final class _TestException extends ApiClientException {
  const _TestException();

  @override
  int get statusCode => 404;

  @override
  String get code => 'not_found';

  @override
  String get message => 'Not found';

  @override
  Object? get error => null;

  @override
  Object? get data => const <String, Object?>{'reason': 'missing'};
}

ApiClientRequest _request({String body = ''}) => ApiClientRequest(
  http.Request('POST', Uri.parse('https://api.example.com/items'))..body = body,
);

ApiClientResponse _response(ApiClientRequest request) => ApiClientResponse.json(
  const <String, Object?>{'ok': true},
  statusCode: 200,
  headers: const <String, String>{'content-type': 'application/json'},
  contentLength: 11,
  persistentConnection: false,
  request: request,
);

void main() {
  group('ThunderMiddleware', () {
    test('success path emits loading then completed with sizes', () async {
      final logs = <ThunderNetworkLog>[];
      final middleware = ThunderMiddleware(onNetworkActivity: logs.add);

      final handler = middleware.call(
        (request, context) async => _response(request),
      );

      final response = await handler(_request(body: '{"a":1}'), {});

      expect(response.statusCode, 200);
      expect(logs, hasLength(2));
      expect(logs.first.isLoading, isTrue);
      // The utf-8 length of '{"a":1}', not of the stringified byte list.
      expect(logs.first.sendBytes, 7);

      final done = logs.last;
      expect(done.id, logs.first.id);
      expect(done.isLoading, isFalse);
      expect(done.statusCode, 200);
      expect(done.duration, isNotNull);
      expect(done.receiveBytes, 11);
    });

    test('ApiClientException completes the log and rethrows', () async {
      final logs = <ThunderNetworkLog>[];
      final middleware = ThunderMiddleware(onNetworkActivity: logs.add);

      final handler = middleware.call(
        (request, context) async => throw const _TestException(),
      );

      await expectLater(
        () => handler(_request(), {}),
        throwsA(isA<_TestException>()),
      );

      expect(logs, hasLength(2));
      final done = logs.last;
      expect(done.isLoading, isFalse);
      expect(done.statusCode, 404);
      expect(done.error, isA<_TestException>());
    });

    test('generic exceptions complete the log and rethrow', () async {
      final logs = <ThunderNetworkLog>[];
      final middleware = ThunderMiddleware(onNetworkActivity: logs.add);

      final handler = middleware.call(
        (request, context) async => throw StateError('boom'),
      );

      await expectLater(() => handler(_request(), {}), throwsStateError);

      expect(logs, hasLength(2));
      final done = logs.last;
      expect(done.isLoading, isFalse, reason: 'row must not spin forever');
      expect(done.error, isA<StateError>());
      expect(done.duration, isNotNull);
    });
  });
}
