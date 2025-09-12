import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../common/extension/curl_extension.dart';
import '../../common/extension/duration_extension.dart';
import '../../common/models/thunder_network_log.dart';
import '../../common/utils/app_colors.dart';
import '../../common/utils/helpers.dart';

/// A widget that displays a button for a network log.
class LogButton extends StatelessWidget {
  /// Constructor for the [LogButton] class.
  const LogButton({required this.log, required this.onLogTap, super.key});

  /// The network log to display
  final ThunderNetworkLog log;

  /// The function to call when the log button is pressed.
  final void Function(ThunderNetworkLog log) onLogTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        onPressed: () => onLogTap(log),
        onLongPress: () => Helpers.copyAndShowSnackBar(
          context,
          contentToCopy: log.request.toCurlString(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.hardEdge,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: log.methodBackgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: log.methodColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (log.request.url.host.isNotEmpty)
                  Row(
                    children: [
                      /// For secure request
                      if (log.request.url.host.contains('https')) ...[
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 10,
                          color: AppColors.red,
                        ),
                        const SizedBox(width: 4),
                      ],

                      /// Request Base URL
                      Expanded(
                        child: Text(
                          log.request.url.host,
                          style: const TextStyle(
                            color: AppColors.grayRussian,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),

                /// Request Path
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        log.request.url.pathSegments.join('/'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.lavaStone,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    /// Request Size
                    if (!log.isLoading)
                      Text(
                        '${Helpers.formatBytes(log.sendBytes)} / ${Helpers.formatBytes(log.receiveBytes)}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    /// Request Method (GET, POST, PUT, DELETE)
                    Container(
                      width: 60,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: log.methodColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        log.request.method,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    /// Request Time | Request duration
                    Text(
                      "${DateFormat('HH:mm:ss:SSS').format(log.sendTime ?? DateTime.now())}${log.isLoading ? '' : '  │  ${log.duration.formatCompactDuration}'}",
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),

                    switch (log.isLoading) {
                      true => SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            color: log.methodColor,
                            strokeCap: StrokeCap.round,
                            strokeWidth: 3,
                          ),
                        ),
                      false => Text(
                          Helpers.getStatusCode(log),
                          style: TextStyle(
                            color: switch (
                                int.tryParse(Helpers.getStatusCode(log))) {
                              int i when i >= 200 && i < 300 =>
                                const Color(0xFF2ccc84),
                              _ => AppColors.red,
                            },
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    },
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
