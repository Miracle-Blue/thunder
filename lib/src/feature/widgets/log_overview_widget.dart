import 'package:flutter/material.dart';

import '../../common/extension/duration_extension.dart';
import '../../common/models/thunder_network_log.dart';
import '../../common/utils/helpers.dart';
import 'list_row_item.dart';

/// A widget that displays an overview of a network log.
class LogOverviewWidget extends StatelessWidget {
  /// Constructor for the [LogOverviewWidget] class.
  const LogOverviewWidget({required this.log, super.key});

  /// The network log to display
  final ThunderNetworkLog log;

  @override
  Widget build(BuildContext context) => ListView(
        children: [
          ListRowItem(name: 'Method', value: log.request.method),
          ListRowItem(
            name: 'URL',
            value: log.request.url.host.isEmpty
                ? 'Base URL is empty'
                : log.request.url.host,
            showCopyButton: true,
          ),
          ListRowItem(
            name: 'Endpoint',
            value: log.request.url.path.isEmpty
                ? 'Endpoint is empty'
                : log.request.url.path,
            showCopyButton: true,
          ),
          ListRowItem(
            name: 'Status',
            value: Helpers.getStatusCode(log),
          ),
          ListRowItem(
            name: 'Time',
            value: log.duration?.formatCompactDuration ?? 'null',
          ),
          ListRowItem(
            name: 'Bytes Sent',
            value: Helpers.formatBytes(log.sendBytes),
          ),
          ListRowItem(
            name: 'Bytes Received',
            value: Helpers.formatBytes(log.receiveBytes),
            showDivider: false,
          ),
        ],
      );
}
