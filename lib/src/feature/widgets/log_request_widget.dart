import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../common/extension/object_extension.dart';
import '../../common/models/thunder_network_log.dart';
import '../../common/utils/helpers.dart';
import 'list_row_item.dart';

/// A widget that displays the request of a network log.
class LogRequestWidget extends StatelessWidget {
  /// Constructor for the [LogRequestWidget] class.
  const LogRequestWidget({required this.log, super.key});

  /// The network log to display
  final ThunderNetworkLog log;

  @override
  Widget build(BuildContext context) => ListView(
        children: [
          ListRowItem(
            name: 'Started',
            value: DateFormat(
              'dd-MM-yyyy │ HH:mm:ss:SSS',
            ).format(log.sendTime ?? DateTime.now()),
          ),
          ListRowItem(
            name: 'Bytes sent',
            value: Helpers.formatBytes(log.sendBytes),
          ),
          ListRowItem(
            name: 'Headers',
            value: log.request.headers.prettyJson,
            showCopyButton: true,
            isJson: true,
          ),
          ListRowItem(
            name: 'Body',
            value: log.request.body.prettyJsonEncodedBody,
            showCopyButton: true,
            isJson: true,
          ),
          ListRowItem(
            name: 'Query Parameters',
            value: log.request.url.queryParameters.prettyJson,
            showCopyButton: true,
            showDivider: false,
            isJson: true,
          ),
        ],
      );
}
