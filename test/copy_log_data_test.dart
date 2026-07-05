import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:thunder/src/common/models/thunder_network_log.dart';
import 'package:thunder/src/common/utils/copy_log_data.dart';
import 'package:thunder/thunder.dart';

void main() {
  final request = ApiClientRequest(
    http.Request('GET', Uri.parse('https://example.com/users')),
  );

  test('a still-loading log copies without crashing', () {
    final log = ThunderNetworkLog(request: request, isLoading: true);

    final text = CopyLogData(log: log).toCopyableLogData;

    expect(text, contains('Status: -'));
    expect(text, contains('Response body is empty'));
  });

  test('a non-ApiClientException error copies without crashing', () {
    final log = ThunderNetworkLog(
      request: request,
      isLoading: false,
      error: StateError('boom'),
    );

    final text = CopyLogData(log: log).toCopyableLogData;

    expect(text, contains('Status: -'));
    expect(text, contains('Error: Bad state: boom'));
  });

  test('a response log prints exactly one Status line', () {
    final log = ThunderNetworkLog(
      request: request,
      isLoading: false,
      response: ApiClientResponse.json(
        const <String, Object?>{'ok': true},
        statusCode: 200,
        headers: const <String, String>{},
        contentLength: 11,
        persistentConnection: false,
        request: request,
      ),
    );

    final text = CopyLogData(log: log).toCopyableLogData;

    expect('Status:'.allMatches(text).length, 1);
    expect(text, contains('Status: 200'));
  });
}
