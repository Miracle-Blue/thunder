import 'dart:convert';
import 'dart:developer';

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
        onNetworkActivity(
          ThunderNetworkLog(
            id: logId,
            request: request,
            isLoading: true,
            receiveTime: null,
            sendTime: startTime,
            sendBytes: utf8.encode(request.bodyBytes.toString()).length,
          ),
        );

        try {
          final response = await innerHandler(request, context);

          final duration = DateTime.now().difference(startTime);

          onNetworkActivity(ThunderNetworkLog(
            id: logId,
            sendTime: startTime,
            receiveTime: DateTime.now(),
            isLoading: false,
            request: response.request,
            response: response,
            duration: duration,
            receiveBytes: response.contentLength,
            sendBytes:
                utf8.encode(response.request.bodyBytes.toString()).length,
          ));

          return response;
        } on ApiClientException catch (error, _) {
          final duration = DateTime.now().difference(startTime);
          onNetworkActivity(ThunderNetworkLog(
            id: logId,
            sendTime: startTime,
            request: request,
            receiveTime: DateTime.now(),
            error: error,
            statusCode: error.statusCode,
            duration: duration,
            isLoading: false,
            receiveBytes: utf8.encode(error.data?.toString() ?? '').length,
            sendBytes: utf8.encode(request.bodyBytes.toString()).length,
          ));

          rethrow;
        } finally {
          log('--=-=-=-==--==-=--==-=--==----==-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=');
        }
      };
}
