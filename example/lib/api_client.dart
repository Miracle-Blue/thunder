import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http_package;
import 'package:thunder/thunder.dart';

/// {@template api_client}
/// An HTTP client that sends requests to a REST API.
/// {@endtemplate}
class ApiClient /* with http_package.BaseClient implements http_package.Client */ {
  ApiClient(
      {required Uri uri,
      http_package.Client? client,
      Iterable<ApiClientMiddleware>? middlewares})
      : _baseUri = uri,
        assert(!uri.path.endsWith('//'), 'Invalid base URI.') {
    // Create the HTTP client.
    final internalClient = client ?? http_package.Client();

    // Create the final middleware.
    final mw = ApiClientMiddlewareWrapper.merge([
      /* default middlewares before custom middlewares */
      ...?middlewares,
      /* default middlewares after custom middlewares */
    ]);

    // Create the handler.
    _handler = _createHandler(internalClient, mw.call);
  }

  final Uri _baseUri;

  late final ApiClientHandler _handler;

  /// Merges the given [path] with the base URL.
  static Uri _mergePath(Uri base, String path) {
    if (path.startsWith('http')) return Uri.parse(path);
    var method = path;
    while (method.startsWith('/')) {
      method = method.substring(1);
    }
    return base.replace(path: '${base.path}/$method');
  }

  /// Sends a non-streaming [http_package.Request] and returns a non-streaming [http_package.Response].
  static Future<ApiClientResponse> _sendUnstreamed({
    required ApiClientHandler handler,
    required String method,
    required Uri url,
    required Map<String, String>? headers,
    required Map<String, Object?>? body,
    required Map<String, Object?> context,
  }) {
    final request = http_package.Request(method, url)..maxRedirects = 5;
    request.headers['Accept'] = 'application/json';
    if (headers != null) request.headers.addAll(headers);
    if (body != null) {
      final bytes = const JsonEncoder().fuse(const Utf8Encoder()).convert(body);
      request.headers
        ..['Content-Type'] = 'application/json; charset=UTF-8'
        ..['Content-Length'] = bytes.length.toString();
      request.bodyBytes = bytes;
    }
    return handler(ApiClientRequest(request), context);
  }

  /// Sends a GET request to the given [path].
  Future<ApiClientResponse> get(String path,
          {Map<String, String>? headers, Map<String, Object?>? context}) =>
      _sendUnstreamed(
        handler: _handler,
        method: 'GET',
        url: _mergePath(_baseUri, path),
        headers: headers,
        body: null,
        context: context ?? <String, Object?>{},
      );

  /// Sends a POST request to the given [path].
  Future<ApiClientResponse> post(String path,
          {Map<String, String>? headers, Map<String, Object?>? body}) =>
      _sendUnstreamed(
        handler: _handler,
        method: 'POST',
        url: _mergePath(_baseUri, path),
        headers: headers,
        body: body,
        context: <String, Object?>{},
      );

  /// Sends a PUT request to the given [path].
  Future<ApiClientResponse> put(String path,
          {Map<String, String>? headers, Map<String, Object?>? body}) =>
      _sendUnstreamed(
        handler: _handler,
        method: 'PUT',
        url: _mergePath(_baseUri, path),
        headers: headers,
        body: body,
        context: <String, Object?>{},
      );

  /// Sends a DELETE request to the given [path].
  Future<ApiClientResponse> delete(String path,
          {Map<String, String>? headers, Map<String, Object?>? body}) =>
      _sendUnstreamed(
        handler: _handler,
        method: 'DELETE',
        url: _mergePath(_baseUri, path),
        headers: headers,
        body: body,
        context: <String, Object?>{},
      );
}

/// Creates a new [ApiClientHandler] from the given [internalClient] and [middleware].
ApiClientHandler _createHandler(
    http_package.Client internalClient, ApiClientMiddleware middleware) {
  // Check if the completer is completed and throw an error if it is.
  void throwError(Completer<ApiClientResponse> completer, Object error,
      StackTrace stackTrace) {
    if (completer.isCompleted) {
      return;
    } else if (error is ApiClientException) {
      completer.completeError(error, stackTrace);
    } else {
      completer.completeError(
        ApiClientException$Client(
          code: 'unknown_error',
          message: 'Unknown error.',
          statusCode: 0,
          error: error,
          data: null,
        ),
        stackTrace,
      );
    }
  }

  // JSON decoder.
  final jsonDecoderMap = const Utf8Decoder()
      .fuse(const JsonDecoder())
      .cast<Object?, Map<String, Object?>>();
  final jsonDecoderList = const Utf8Decoder()
      .fuse(const JsonDecoder())
      .cast<Object?, List<Object?>>();

  // HTTP handler.
  Future<ApiClientResponse> httpHandler(
      ApiClientRequest request, Map<String, Object?> context) {
    final completer = Completer<ApiClientResponse>();
    // Handle top level errors.
    runZonedGuarded<void>(
      () async {
        assert(request.url.scheme.startsWith('http'),
            'Invalid URL: ${request.url}');

        // Send a base request.
        final http_package.StreamedResponse streamedResponse;
        try {
          streamedResponse = await internalClient.send(request);
        } on Object catch (error, stackTrace) {
          throwError(
            completer,
            ApiClientException$Network(
              code: 'network_error',
              message: 'Failed to send request due to a network error.',
              statusCode: 0,
              error: error,
              data: null,
            ),
            stackTrace,
          );
          return;
        }

        // Check response.
        int statusCode;
        try {
          statusCode = streamedResponse.statusCode;
          switch (statusCode) {
            case > 499:
              throw ApiClientException$Network(
                code: 'internal_server_error',
                message: 'Internal server error.',
                statusCode: statusCode,
                error: null,
                data: null,
              );
            case 401 || 403:
              throw ApiClientException$Authentication(
                code: 'unauthorized_error',
                message: 'User is not authorized.',
                statusCode: statusCode,
                error: null,
                data: null,
              );
            case > 399:
              throw ApiClientException$Client(
                code: 'bad_request_error',
                message: 'Bad request.',
                statusCode: statusCode,
                error: null,
                data: null,
              );
            case > 299:
              throw ApiClientException$Client(
                code: 'redirection_error',
                message: 'Request was redirected.',
                statusCode: statusCode,
                error: null,
                data: null,
              );
            default:
              break;
          }
        } on Object catch (error, stackTrace) {
          throwError(completer, error, stackTrace);
          return;
        }

        // Read the response stream.
        int contentLength;
        Uint8List bytes;
        try {
          // contentLength = streamedResponse.contentLength ?? 0;
          // if (contentLength > 0) {

          final contentType =
              streamedResponse.headers['content-type']?.toLowerCase() ?? '';
          if (!contentType.contains('application/json')) {
            throwError(
              completer,
              ApiClientException$Client(
                code: 'invalid_content_type_error',
                message: 'Response content type is not application/json.',
                statusCode: statusCode,
                error: null,
                data: null,
              ),
              StackTrace.current,
            );
            return;
          }
          bytes = await streamedResponse.stream.toBytes();
          contentLength = bytes.length;

          log('content-type: ${streamedResponse.headers['content-type']}');
          log('content-length: ${streamedResponse.headers['content-length']}');
          log('bytes: ${bytes.length}');
          log('contentLength: ${streamedResponse.contentLength}');

          // } else {
          //   bytes = Uint8List(0);
          // }
        } on Object catch (error, stackTrace) {
          throwError(
            completer,
            ApiClientException$Network(
              code: 'body_stream_error',
              message: 'Failed to read response stream.',
              statusCode: streamedResponse.statusCode,
              error: error,
              data: null,
            ),
            stackTrace,
          );
          return;
        }

        // Decode the response.
        ApiClientResponse response;
        try {
          final body = switch (bytes) {
            final a when a.isEmpty => <String, Object?>{},
            final a when a.first == 91 => jsonDecoderList.convert(bytes),
            final a when a.first == 123 => jsonDecoderMap.convert(bytes),
            _ => <String, Object?>{},
          };

          response = ApiClientResponse.json(
            switch (body) {
              final a when a is Map => a.cast<String, Object?>(),
              final a when a is List => {'data': a.cast<Object?>()},
              _ => <String, Object?>{},
            },
            statusCode: streamedResponse.statusCode,
            headers: streamedResponse.headers,
            contentLength: contentLength,
            persistentConnection: streamedResponse.persistentConnection,
            request: request,
          );
        } on Object catch (error, stackTrace) {
          throwError(
            completer,
            ApiClientException$Client(
              code: 'decoding_error',
              message: 'Failed to decode response.',
              statusCode: streamedResponse.statusCode,
              error: error,
              data: bytes,
            ),
            stackTrace,
          );
          return;
        }

        // Complete the completer.
        if (!completer.isCompleted) completer.complete(response);
      },
      (error, stackTrace) {
        throwError(completer, error, stackTrace);
      },
    );
    return completer.future;
  }

  return middleware(httpHandler);
}

// --- Errors --- //

/// A base class for all API client exceptions.
@immutable
sealed class ApiClientExceptionI extends ApiClientException {
  const ApiClientExceptionI();

  @override
  String toString() => message;
}

/// Client exception.
final class ApiClientException$Client extends ApiClientException {
  const ApiClientException$Client({
    required this.code,
    required this.message,
    required this.statusCode,
    this.error,
    this.data,
  });

  @override
  final String code;

  @override
  final String message;

  @override
  final int statusCode;

  @override
  final Object? error;

  @override
  final Object? data;
}

/// Network exception.
final class ApiClientException$Network extends ApiClientException {
  const ApiClientException$Network({
    required this.code,
    required this.message,
    required this.statusCode,
    this.error,
    this.data,
  });

  @override
  final String code;

  @override
  final String message;

  @override
  final int statusCode;

  @override
  final Object? error;

  @override
  final Object? data;
}

/// Authorization exception.
final class ApiClientException$Authentication extends ApiClientException {
  const ApiClientException$Authentication({
    required this.code,
    required this.message,
    required this.statusCode,
    this.error,
    this.data,
  });

  @override
  final String code;

  @override
  final String message;

  @override
  final int statusCode;

  @override
  final Object? error;

  @override
  final Object? data;
}

final class ApiClientException$Timeout extends ApiClientException
    implements TimeoutException {
  const ApiClientException$Timeout({
    required this.code,
    required this.message,
    required this.statusCode,
    this.duration,
    this.error,
    this.data,
  });

  @override
  final String code;

  @override
  final String message;

  @override
  final int statusCode;

  @override
  final Object? error;

  @override
  final Object? data;

  @override
  final Duration? duration;
}
