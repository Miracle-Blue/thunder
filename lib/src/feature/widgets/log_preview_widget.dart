import 'dart:convert';

import 'package:flutter/material.dart';

import '../../common/models/thunder_network_log.dart';
import '../../common/utils/app_colors.dart';
import 'awaiting_response_widget.dart';
import 'json_viewer.dart';
import 'list_row_item.dart';

/// A widget that displays a preview of a network log.
class LogPreviewWidget extends StatefulWidget {
  /// Constructor for the [LogPreviewWidget] class.
  const LogPreviewWidget({required this.log, super.key});

  /// The network log to display
  final ThunderNetworkLog log;

  @override
  State<LogPreviewWidget> createState() => _LogPreviewWidgetState();
}

class _LogPreviewWidgetState extends State<LogPreviewWidget> {
  // Constants for content type checks and large response threshold.
  static const _imageContentType = 'image';
  static const _jsonContentType = 'json';
  static const _xmlContentType = 'xml';
  static const _textContentType = 'text';
  static const _kLargeOutputSize = 100000;

  // State flags for user interactions.
  bool _showLargeBody = false;
  bool _showUnsupportedBody = false;

  @override
  // Use a switch-like expression for clarity.
  Widget build(BuildContext context) => switch (widget.log.isLoading) {
        /// Builds a view for awaiting response.
        true => const AwaitingResponseWidget(),

        /// Builds the main response view including both horizontal and vertical scrolling.
        false => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 2,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildResponsePreview(),
                    ),
                  ),
                ),
              ),
            ),
          ),
      };

  /// Returns a list of widgets representing the preview content.
  List<Widget> _buildResponsePreview() {
    final rows = <Widget>[];

    // Prioritize showing response, then error details.
    if (widget.log.response != null) {
      rows.addAll(_buildBodyRows());
    } else if (widget.log.error != null) {
      rows.addAll([
        const Row(
          children: [
            Text(
              'Error Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListRowItem(
          name: 'Error',
          value: widget.log.error?.toString() ?? 'Unknown error',
        ),
      ]);
    }

    return rows;
  }

  /// Returns body rows based on response type.
  List<Widget> _buildBodyRows() {
    if (widget.log.response == null) return [];

    // Determine which builder to use based on content type.
    if (_isImageResponse()) {
      return _buildImageBodyRows();
    } else if (_isTextResponse()) {
      return _isLargeResponseBody()
          ? _buildLargeBodyTextRows()
          : _buildTextBodyRows();
    } else {
      return _buildUnknownBodyRows();
    }
  }

  /// Builds a view for image responses.
  List<Widget> _buildImageBodyRows() => [
        Column(
          children: [
            const Row(
              children: [
                Text('Body: Image',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Image.network(
              widget.log.request.url.toString(),
              fit: BoxFit.fill,
              headers: _buildRequestHeaders(),
              loadingBuilder: (context, child, loadingProgress) {
                // Show a progress indicator until image is loaded.
                if (loadingProgress == null) return child;
                final expected = loadingProgress.expectedTotalBytes ?? 0;
                final progress = expected > 0
                    ? loadingProgress.cumulativeBytesLoaded / expected
                    : null;
                return Center(
                    child: CircularProgressIndicator(value: progress));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ];

  /// Builds a view for very large text responses.
  List<Widget> _buildLargeBodyTextRows() {
    final bodySize = widget.log.response?.body.toString().length ?? 0;
    if (_showLargeBody) return _buildTextBodyRows();

    return [
      ListRowItem(name: 'Body', value: 'Too large to show ($bodySize Bytes)'),
      const SizedBox(height: 8),
      ElevatedButton(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll<Color>(Colors.red.shade300),
          foregroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
        ),
        onPressed: () => setState(() => _showLargeBody = true),
        child: const Text('Show body'),
      ),
      const SizedBox(height: 8),
      const Text('Warning! It will take some time to render output.'),
    ];
  }

  /// Builds a view for text responses.
  List<Widget> _buildTextBodyRows() {
    final rows = <Widget>[];
    final bodyContent = _formatBody(widget.log.response?.body);

    // Check for JSON-like content and try to parse it.
    if (bodyContent.contains('{') && bodyContent.contains('}')) {
      try {
        rows.add(JsonViewer(jsonDecode(bodyContent)));
      } on Object {
        // Fallback: show the raw text if JSON parsing fails.
        rows.add(ListRowItem(value: bodyContent, showDivider: false));
      }
    } else {
      rows.add(ListRowItem(value: bodyContent, showDivider: false));
    }

    return rows;
  }

  /// Builds a view for responses with unsupported content types.
  List<Widget> _buildUnknownBodyRows() {
    final rows = <Widget>[];
    // Retrieve headers and content type from the response.
    final headers = widget.log.response?.headers;
    final contentType = _getContentType(headers ?? {}) ?? '<unknown>';

    if (_showUnsupportedBody) {
      final bodyContent = _formatBody(widget.log.response?.body);
      rows.add(ListRowItem(name: 'Body', value: bodyContent));
    } else {
      rows.addAll([
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            children: [
              ListRowItem(
                name: 'Body',
                value:
                    'Unsupported body. This widget can render image/text body. '
                    "Response has Content-Type: $contentType which can't be handled. "
                    "If you're feeling lucky, try the button below to render body as text, but it may fail or could potentially crash the app.",
              ),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll<Color>(
                    AppColors.mainColor,
                  ),
                  foregroundColor: const WidgetStatePropertyAll<Color>(
                    AppColors.white,
                  ),
                ),
                onPressed: () => setState(() => _showUnsupportedBody = true),
                child: const Text('Show unsupported body'),
              ),
            ],
          ),
        ),
      ]);
    }
    return rows;
  }

  /// Extracts request headers from the log as a simple Map.
  Map<String, String> _buildRequestHeaders() => widget.log.request.headers.map(
        (key, value) => MapEntry(key, value.toString()),
      );

  /// Checks if the response content type is an image.
  bool _isImageResponse() {
    final contentType = _getContentTypeOfResponse();
    return contentType != null &&
        contentType.toLowerCase().contains(_imageContentType);
  }

  /// Checks if the response content type is a text-based type.
  bool _isTextResponse() {
    final contentType = _getContentTypeOfResponse();
    if (contentType == null) return true;
    final lower = contentType.toLowerCase();
    return lower.contains(_jsonContentType) ||
        lower.contains(_xmlContentType) ||
        lower.contains(_textContentType);
  }

  /// Returns the content type from the response headers.
  String? _getContentTypeOfResponse() {
    if (widget.log.response == null) return null;
    return _getContentType(widget.log.response!.headers);
  }

  /// Retrieves the content type header from a headers map.
  String? _getContentType(Map<String, Object?> headers) {
    final contentTypeHeader =
        headers['content-type'] ?? headers['Content-Type'];
    if (contentTypeHeader is List) {
      return contentTypeHeader.isNotEmpty
          ? contentTypeHeader.first.toString()
          : null;
    }
    return contentTypeHeader?.toString();
  }

  /// Checks if the response body is considered large.
  bool _isLargeResponseBody() {
    final data = widget.log.response?.body;
    return data != null && data.toString().length > _kLargeOutputSize;
  }

  /// Formats the body as a pretty JSON string (if possible) or uses its string representation.
  String _formatBody(Object? body) {
    if (body == null) return '';
    if (body is Map || body is List) {
      try {
        // Pretty-print JSON with indentation.
        const encoder = JsonEncoder.withIndent('  ');

        return encoder.convert(body);
      } on Object catch (_) {
        return body.toString();
      }
    }
    return body.toString();
  }
}
