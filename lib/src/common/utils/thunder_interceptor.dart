import 'dart:convert';

import 'package:http/http.dart' as http_package;
import 'package:meta/meta.dart';

import '../extension/middleware_extensions.dart';
import '../models/thunder_network_log.dart';

/// Middleware for Thunder
@immutable
class ThunderMiddleware {
  /// Constructor for the [ThunderMiddleware] class.
  const ThunderMiddleware({required this.onNetworkActivity});

  /// The list of logs
  // final List<ThunderNetworkLog> _logs = [];

  /// The callback to call when a network activity is detected
  final void Function(ThunderNetworkLog log) onNetworkActivity;

  /// The handler for the middleware
  ApiClientHandler call(ApiClientHandler innerHandler) =>
      (request, context) async {
        final startTime = DateTime.now();
        final logId = DateTime.now().microsecondsSinceEpoch.toString();

        var sendBytes = 0;
        if (request case final http_package.MultipartRequest request) {
          sendBytes = request.contentLength;
        } else {
          sendBytes = utf8.encode(request.bodyBytes.toString()).length;
        }

        final log = ThunderNetworkLog(
          id: logId,
          request: request,
          isLoading: true,
          receiveTime: null,
          sendTime: startTime,
          sendBytes: sendBytes,
        );

        onNetworkActivity(log);

        try {
          final response = await innerHandler(request, context);

          final duration = DateTime.now().difference(startTime);

          onNetworkActivity(log.copyWith(
            receiveTime: DateTime.now(),
            isLoading: false,
            response: response,
            duration: duration,
            receiveBytes: response.contentLength,
            statusCode: response.statusCode,
          ));

          return response;
        } on ApiClientException catch (error, _) {
          final duration = DateTime.now().difference(startTime);
          onNetworkActivity(log.copyWith(
            receiveTime: DateTime.now(),
            error: error,
            statusCode: error.statusCode,
            receiveBytes: utf8.encode(error.data?.toString() ?? '').length,
            duration: duration,
            isLoading: false,
          ));

          rethrow;
        } finally {}
      };
}
