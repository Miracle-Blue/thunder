import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

import '../extension/middleware_extensions.dart';
import '../extension/string_extension.dart';

/// Model class to store network request/response data
@immutable
final class ThunderNetworkLog {
  /// Constructor for the [ThunderNetworkLog] class.
  ThunderNetworkLog({
    required this.request,
    required this.isLoading,
    this.sendTime,
    this.receiveTime,
    this.sendBytes,
    this.receiveBytes,
    this.response,
    this.error,
    this.duration,
    this.statusCode,
    String? id,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  /// The time when the request was sent
  final DateTime? sendTime;

  /// The time when the request was received
  final DateTime? receiveTime;

  /// The request options
  final ApiClientRequest request;

  /// The response
  final ApiClientResponse? response;

  /// The error
  final Object? error;

  /// The duration of the request
  final Duration? duration;

  /// Whether the request is loading
  final bool isLoading;

  /// The number of bytes sent
  final int? sendBytes;

  /// The number of bytes received
  final int? receiveBytes;

  /// UUID of the log
  final String id;

  /// The status code
  final int? statusCode;

  /// Method to get the color of the method
  Color get methodColor => request.method.methodColor;

  /// Method to get the background color of the method
  Color get methodBackgroundColor => request.method.methodBackgroundColor;

  /// [copyWith] helper method to updated the log with new values
  ThunderNetworkLog copyWith({
    DateTime? sendTime,
    DateTime? receiveTime,
    ApiClientRequest? request,
    ApiClientResponse? response,
    ApiClientException? error,
    Duration? duration,
    int? sendBytes,
    int? receiveBytes,
    bool? isLoading,
    int? statusCode,
  }) => ThunderNetworkLog(
    sendTime: sendTime ?? this.sendTime,
    receiveTime: receiveTime ?? this.receiveTime,
    request: request ?? this.request,
    response: response ?? this.response,
    error: error ?? this.error,
    duration: duration ?? this.duration,
    isLoading: isLoading ?? this.isLoading,
    sendBytes: sendBytes ?? this.sendBytes,
    receiveBytes: receiveBytes ?? this.receiveBytes,
    id: id,
    statusCode: statusCode ?? this.statusCode,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ThunderNetworkLog &&
        other.id == id &&
        other.sendTime == sendTime &&
        other.receiveTime == receiveTime &&
        other.request == request &&
        other.response == response &&
        other.error == error &&
        other.duration == duration &&
        other.isLoading == isLoading &&
        other.sendBytes == sendBytes &&
        other.receiveBytes == receiveBytes &&
        other.statusCode == statusCode;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      sendTime.hashCode ^
      receiveTime.hashCode ^
      request.hashCode ^
      response.hashCode ^
      error.hashCode ^
      duration.hashCode ^
      isLoading.hashCode ^
      sendBytes.hashCode ^
      receiveBytes.hashCode ^
      statusCode.hashCode;

  @override
  String toString() =>
      'ThunderNetworkLog('
      'timestamp: $sendTime, '
      'request: $request, '
      'response: $response, '
      'error: $error, '
      'duration: $duration, '
      'isLoading: $isLoading, '
      'id: $id, '
      'sendBytes: $sendBytes, '
      'receiveBytes: $receiveBytes, '
      'statusCode: $statusCode)';
}
