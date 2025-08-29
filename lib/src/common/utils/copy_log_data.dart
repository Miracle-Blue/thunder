import '../extension/duration_extension.dart';
import '../extension/middleware_extensions.dart';
import '../extension/object_extension.dart';
import '../models/thunder_network_log.dart';

/// Class that helps convert the [ThunderNetworkLog] to a copyable log data string
///
/// Example:
/// Server: jsonplaceholder.typicode.com
/// Method: PUT
/// Endpoint: /posts/1
/// Status: 200
/// Duration: 1.50s
///
/// ───────────────
/// REQUEST
/// ───────────────
///
/// Request headers:
/// ```
/// {
///   "content-type": "application/json",
///   "content-length": "162"
/// }
/// Request body:
/// ```
/// {
///   "title": "foo",
///   "body": "bar",
///   "userId": "1",
///   "isFlutterCool": true,
///   "socials": null,
///   "hobbies": [
///     "Music",
///     "Filmmaking"
///   ],
///   "score": 7.6,
///   "id": 24,
///   "name": "John Doe",
///   "isJson": true
/// }
///
/// ───────────────
/// RESPONSE
/// ───────────────
///
/// Response body:
/// ```
/// {
///   "title": "foo",
///   "body": "bar",
///   "userId": "1",
///   "isFlutterCool": true,
///   "socials": null,
///   "hobbies": [
///     "Music",
///     "Filmmaking"
///   ],
///   "score": 7.6,
///   "id": 1,
///   "name": "John Doe",
///   "isJson": true
/// }
class CopyLogData {
  /// Constructor for the [CopyLogData] class.
  const CopyLogData({required this.log});

  /// The log to convert to a copyable log data string
  final ThunderNetworkLog log;
  static final _lines = '─' * 15;

  String get _requestHeaders => switch (log.request.headers.isNotEmpty) {
        true =>
          'Request headers: ```json\n${log.request.headers.prettyJson}```\n',
        false => '\r',
      };

  String get _queryParams =>
      switch (log.request.url.queryParameters.isNotEmpty) {
        true =>
          'Request query params: ```json\n${log.request.url.queryParameters.prettyJson}```\n',
        false => '\r',
      };

  String get _requestBody => switch (log.request.body.isNotEmpty) {
        true => 'Request body: ```json\n${log.request.body.prettyJson}```\n',
        false => '\r',
      };

  String get _responseBody => switch (log.response?.body) {
        Map<String, Object?> body =>
          'Response body: ```json\n${body.prettyJson}```\n',
        _ when log.error != null && log.error is ApiClientException =>
          'Error body: ```json\n${(log.error as ApiClientException).data?.prettyJson}```\n',
        _ => '\r',
      };

  /// Method that converts the [ThunderNetworkLog] to a copyable log data string
  String get toCopyableLogData {
    final buffer = StringBuffer()
      ..writeln('Server: ${log.request.url.host}')
      ..writeln('Method: ${log.request.method}')
      ..writeln('Endpoint: ${log.request.url.path}')
      ..writeln(
        'Status: ${log.response?.statusCode ?? (log.error as ApiClientException).statusCode}',
      );

    if (log.response?.statusCode != null) {
      buffer.writeln('Status: ${log.response?.statusCode}');
    }

    if (log.duration != null) {
      buffer.writeln('Duration: ${log.duration?.formatCompactDuration}');
    }

    buffer
      ..write('\n$_lines\n')
      ..write('REQUEST\n')
      ..write('$_lines\n');

    final queryParams = _queryParams;
    final requestBody = _requestBody;
    final requestHeaders = _requestHeaders;

    if (requestHeaders.isNotEmpty) buffer.write(requestHeaders);

    if (queryParams.isNotEmpty) buffer.write(queryParams);

    if (requestBody.isNotEmpty) buffer.write(requestBody);

    buffer
      ..write('\n$_lines\n')
      ..write('RESPONSE\n')
      ..write('$_lines\n');

    final responseBody = _responseBody;
    if (responseBody.trim().isNotEmpty) {
      buffer.write('\n$responseBody');
    } else {
      if (log.error != null) {
        buffer.write(
          '```json\n${(log.error as ApiClientException).data?.prettyJson}```',
        );
      } else {
        buffer.write('Response body is empty');
      }
    }

    return buffer.toString();
  }
}
