import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/thunder_network_log.dart';

/// Custom Dio interceptor for Thunder
final class ThunderInterceptor extends Interceptor {
  /// Constructor for the [ThunderInterceptor] class.
  ThunderInterceptor({required this.onNetworkActivity});

  /// The callback to call when a network activity is detected
  final void Function(ThunderNetworkLog log) onNetworkActivity;

  /// The map of request hash codes to their start times
  final Map<String, DateTime> _requestStartTimes = <String, DateTime>{};

  /// The map of request hash codes to their log IDs
  final Map<String, String> _requestIdMap = <String, String>{};

  /// Creates a stable key for the request based on its properties
  String _getRequestKey(RequestOptions options) {
    // Use or create a unique identifier for this request
    const thunderIdKey = 'thunder_request_id';
    if (!options.extra.containsKey(thunderIdKey)) {
      options.extra[thunderIdKey] =
          DateTime.now().microsecondsSinceEpoch.toString();
    }
    return options.extra[thunderIdKey] as String? ?? '';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final requestKey = _getRequestKey(options);
    final logId = DateTime.now().microsecondsSinceEpoch.toString();

    // Store the start time
    _requestStartTimes[requestKey] = DateTime.now();

    // Map the request hash to the log ID
    _requestIdMap[requestKey] = logId;

    final log = ThunderNetworkLog(
      id: logId,
      sendTime: DateTime.now(),
      request: options,
      isLoading: true,
      receiveTime: null,
    );

    onNetworkActivity(log);
    handler.next(options);
  }

  @override
  void onResponse(
    Response<Object?> response,
    ResponseInterceptorHandler handler,
  ) {
    final requestKey = _getRequestKey(response.requestOptions);
    final startTime = _requestStartTimes[requestKey];
    final logId = _requestIdMap[requestKey];

    Duration? duration;
    if (startTime != null) {
      duration = DateTime.now().difference(startTime);
      _requestStartTimes.remove(requestKey);
    }

    final log = ThunderNetworkLog(
      id: logId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      sendTime: startTime,
      receiveTime: DateTime.now(),
      isLoading: false,
      request: response.requestOptions,
      response: response,
      duration: duration,
      receiveBytes: utf8.encode(response.data.toString()).length,
      sendBytes: utf8.encode(response.requestOptions.data.toString()).length,
    );

    onNetworkActivity(log);
    _requestIdMap.remove(requestKey);

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final requestKey = _getRequestKey(err.requestOptions);
    final startTime = _requestStartTimes[requestKey];
    final logId = _requestIdMap[requestKey];

    Duration? duration;
    if (startTime != null) {
      duration = DateTime.now().difference(startTime);
      _requestStartTimes.remove(requestKey);
    }

    final log = ThunderNetworkLog(
      id: logId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      sendTime: startTime,
      request: err.requestOptions,
      receiveTime: DateTime.now(),
      error: err,
      duration: duration,
      isLoading: false,
      receiveBytes: utf8.encode(err.response?.data.toString() ?? '').length,
      sendBytes: utf8.encode(err.requestOptions.data.toString()).length,
    );

    onNetworkActivity(log);
    _requestIdMap.remove(requestKey);
    handler.next(err);
  }
}
