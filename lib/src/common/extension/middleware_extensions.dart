import 'dart:typed_data' show Uint8List;

import 'package:http/http.dart' as http_package;
import 'package:meta/meta.dart';

/// A function that takes a [http_package.BaseRequest] and returns a [http_package.StreamedResponse].
/// The [context] parameter is a map that can be used to store data that should be available to all middleware.
typedef ApiClientHandler = Future<ApiClientResponse> Function(
    ApiClientRequest request, Map<String, Object?> context);

/// A function that takes a [ApiClientHandler] and returns a [ApiClientHandler].
typedef ApiClientMiddleware = ApiClientHandler Function(
    ApiClientHandler innerHandler);

/// A wrapper for [ApiClientMiddleware] that allows for optional handlers.
extension type ApiClientMiddlewareWrapper._(ApiClientMiddleware _fn) {
  /// Creates a new [ApiClientMiddleware] from the given callbacks.
  factory ApiClientMiddlewareWrapper({
    Future<void> Function(
            ApiClientRequest request, Map<String, Object?> context)?
        onRequest,
    Future<void> Function(
            ApiClientResponse response, Map<String, Object?> context)?
        onResponse,
    Future<void> Function(
            Object error, StackTrace stackTrace, Map<String, Object?> context)?
        onError,
  }) =>
      ApiClientMiddlewareWrapper._(
        (innerHandler) => (request, context) async {
          await onRequest?.call(request, context);
          try {
            final response = await innerHandler(request, context);
            await onResponse?.call(response, context);
            return response;
          } on Object catch (error, stackTrace) {
            await onError?.call(error, stackTrace, context);
            rethrow;
          }
        },
      );

  /// Merges the given [middlewares] into a single [ApiClientMiddleware].
  factory ApiClientMiddlewareWrapper.merge(
          List<ApiClientMiddleware> middlewares) =>
      ApiClientMiddlewareWrapper._(
        middlewares.length == 1
            ? middlewares.single
            : (handler) => middlewares.reversed
                .fold(handler, (handler, middleware) => middleware(handler)),
      );

  /// Call the wrapped [ApiClientMiddleware] with the given [innerHandler].
  ApiClientHandler call(ApiClientHandler innerHandler) => _fn(innerHandler);
}

/// An HTTP request with a JSON-encoded body.
extension type ApiClientRequest(http_package.BaseRequest _request)
    implements http_package.BaseRequest {
  /// The body of the request.
  String get body => switch (_request) {
        http_package.Request request => request.body,
        http_package.MultipartRequest request =>
          request.fields.values.join('\n'),
        _ => '',
      };

  /// The body bytes of the request.
  Uint8List get bodyBytes => switch (_request) {
        http_package.Request request => request.bodyBytes,
        _ => Uint8List(0),
      };

  /// The file bytes of the request.
  int get fileBytes => switch (_request) {
        http_package.MultipartRequest request => request.contentLength,
        _ => 0,
      };
}

/// An HTTP response with a JSON-encoded body.
final class ApiClientResponse {
  /// Create a new HTTP response with a JSON-encoded body.
  ApiClientResponse.json(
    this.body, {
    required this.statusCode,
    required this.headers,
    required this.contentLength,
    required this.persistentConnection,
    required this.request,
  });

  /// A status code of HTTP Response
  final int statusCode;

  /// HTTP Response headers
  final Map<String, String> headers;

  /// The length of the response body in bytes.
  final int contentLength;

  /// The parsed JSON body of the HTTP response.
  final Object? body;

  /// Whether the connection should be kept alive for future requests.
  final bool persistentConnection;

  /// The original request that generated this response.
  final ApiClientRequest request;
}

// --- Errors --- //

/// A base class for all API client exceptions.
@immutable
abstract base class ApiClientException implements Exception {
  /// base API client exception constructor
  const ApiClientException();

  /// HTTP status code.
  /// If the request was not sent, this will be 0.
  abstract final int statusCode;

  /// Error code.
  abstract final String code;

  /// Error message.
  abstract final String message;

  /// The source error object.
  abstract final Object? error;

  /// Additional data.
  abstract final Object? data;

  @override
  String toString() => message;
}
