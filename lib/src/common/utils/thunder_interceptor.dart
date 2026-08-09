import 'dart:convert';

import 'package:http/http.dart' as http_package;

import '../extension/middleware_extensions.dart';
import '../models/thunder_network_log.dart';

/// Middleware for Thunder
class ThunderMiddleware {
  /// Constructor for the [ThunderMiddleware] class.
  ThunderMiddleware({required this.onNetworkActivity, this.enabled = true});

  /// The callback to call when a network activity is detected
  final void Function(ThunderNetworkLog log) onNetworkActivity;

  /// Whether the middleware records network activity.
  ///
  /// Checked per request: when `false` the request is passed straight
  /// to the inner handler and no log is emitted. Can be flipped at
  /// runtime; requests already in flight still complete their log entry.
  bool enabled;

  /// The handler for the middleware
  ApiClientHandler call(ApiClientHandler innerHandler) =>
      (request, context) async {
        if (!enabled) return innerHandler(request, context);

        final startTime = DateTime.now();
        final logId = DateTime.now().microsecondsSinceEpoch.toString();

        var sendBytes = 0;
        if (request case final http_package.MultipartRequest request) {
          sendBytes = request.contentLength;
        } else {
          sendBytes = request.bodyBytes.length;
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

          onNetworkActivity(
            log.copyWith(
              receiveTime: DateTime.now(),
              isLoading: false,
              response: response,
              duration: duration,
              receiveBytes: response.contentLength,
              statusCode: response.statusCode,
            ),
          );

          return response;
        } on ApiClientException catch (error, _) {
          final duration = DateTime.now().difference(startTime);
          onNetworkActivity(
            log.copyWith(
              receiveTime: DateTime.now(),
              error: error,
              statusCode: error.statusCode,
              receiveBytes: utf8.encode(error.data?.toString() ?? '').length,
              duration: duration,
              isLoading: false,
            ),
          );

          rethrow;
        } on Object catch (error) {
          onNetworkActivity(
            log.copyWith(
              receiveTime: DateTime.now(),
              error: error,
              duration: DateTime.now().difference(startTime),
              isLoading: false,
            ),
          );

          rethrow;
        }
      };
}
