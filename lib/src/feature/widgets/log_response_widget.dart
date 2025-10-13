import 'package:flutter/material.dart';

import '../../common/extension/middleware_extensions.dart';
import '../../common/extension/object_extension.dart';
import '../../common/models/thunder_network_log.dart';
import '../../common/utils/app_colors.dart';
import '../../common/utils/date_time_extension.dart';
import '../../common/utils/helpers.dart';
import 'awaiting_response_widget.dart';
import 'list_row_item.dart';

/// A widget that displays the response of a network request.
class LogResponseWidget extends StatefulWidget {
  /// Constructor for the [LogResponseWidget] class.
  const LogResponseWidget({required this.log, super.key});

  /// The network log to display
  final ThunderNetworkLog log;

  @override
  State<LogResponseWidget> createState() => _LogResponseWidgetState();
}

class _LogResponseWidgetState extends State<LogResponseWidget> {
  final ScrollController _controller = ScrollController();

  bool _showJsonResponse = true;
  late Future<String> _jsonResponse;
  String get _contentType =>
      widget.log.response?.headers['content-type'] ?? 'content-type not found';

  @override
  void initState() {
    super.initState();
    _jsonResponse = _loadJson();
    _showJsonResponse = !_isLargeResponseBody;
  }

  /// Checks if the response body is considered large.
  bool get _isLargeResponseBody {
    final data = widget.log.response?.body;

    return data != null && data.toString().length > 100000;
  }

  /// Loads the json response asynchronously.
  Future<String> _loadJson() async {
    try {
      return await widget.log.response?.body.prettyJsonAsync ?? '';
    } on Object catch (e) {
      return 'Error formatting JSON: ${e.toString()}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => switch (widget.log.isLoading) {
    true => const AwaitingResponseWidget(),
    false => Scrollbar(
      controller: _controller,
      child: ListView(
        controller: _controller,
        children: [
          ListRowItem(
            name: 'Received',
            value: (widget.log.receiveTime ?? DateTime.now())
                .formatDDMMYYYYHHmmssSSS,
          ),
          ListRowItem(
            name: 'Bytes received',
            value: Helpers.formatBytes(widget.log.receiveBytes),
          ),
          ListRowItem(name: 'Status', value: Helpers.getStatusCode(widget.log)),
          ListRowItem(name: 'Content-Type', value: _contentType),

          /// Checking whether data is not null, not html, json response is enabled, and error is null.
          if (widget.log.response?.body != null &&
              !_contentType.contains('html') &&
              _showJsonResponse &&
              widget.log.error == null)
            FutureBuilder<String>(
              future: _jsonResponse,
              builder: (context, snapshot) =>
                  switch (snapshot.connectionState) {
                    ConnectionState.done => ListRowItem(
                      name: 'Body',
                      value: snapshot.data,
                      showCopyButton: true,
                      showDivider: false,
                      isJson: true,
                    ),
                    _ => SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: const AwaitingResponseWidget(
                        message: 'Rendering JSON...',
                      ),
                    ),
                  },
            ),

          /// Checking whether json response is not enabled.
          if (!_showJsonResponse)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  const Text(
                    'The response body is too large to display automatically. Showing it may take a long time or could potentially crash the app.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.gunmetal,
                      fontWeight: FontWeight.w500,
                    ),
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
                    onPressed: () => setState(() => _showJsonResponse = true),
                    child: const Text('Show large body'),
                  ),
                ],
              ),
            ),

          /// Checking whether content type is html.
          if (_contentType.contains('html')) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'HTML Response',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],

          if (widget.log.error != null) ...[
            const Padding(
              padding: EdgeInsets.all(6),
              child: Text(
                'ERROR details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.red,
                ),
              ),
            ),

            /// When error data is html, we need to show the error data as html.
            if (switch (widget.log.error) {
              ApiClientException(:final data) => data.toString().contains(
                '!DOCTYPE html',
              ),
              final e => e.toString().contains('!DOCTYPE html'),
            })
              const Padding(
                padding: EdgeInsets.only(bottom: 8, left: 8, right: 8),
                child: Text(
                  'Error (HTML body)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              )
            else
              ListRowItem(
                name: 'Error data',
                value: switch (widget.log.error) {
                  ApiClientException(:final data) => data.prettyJson,
                  _ => widget.log.error.toString(),
                },
                isJson: true,
              ),

            ListRowItem(
              name: 'Error message',
              value: switch (widget.log.error) {
                ApiClientException(:final message) => message.toString(),
                _ => widget.log.error.toString(),
              },
              isJson: true,
            ),
            ListRowItem(
              name: 'Error type',
              value: widget.log.error?.runtimeType.toString(),
            ),
          ],
        ],
      ),
    ),
  };
}
