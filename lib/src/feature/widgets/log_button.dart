import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../common/extension/curl_extension.dart';
import '../../common/extension/duration_extension.dart';
import '../../common/models/thunder_network_log.dart';
import '../../common/utils/colors.dart';
import '../../common/utils/date_time_extension.dart';
import '../../common/utils/helpers.dart';

/// A widget that displays a button for a network log.
class LogButton extends StatelessWidget {
  /// Constructor for the [LogButton] class.
  const LogButton({required this.log, required this.onLogTap, super.key});

  /// The network log to display
  final ThunderNetworkLog log;

  /// The function to call when the log button is pressed.
  final void Function(ThunderNetworkLog log) onLogTap;

  String get _requestTimeDuration {
    final requestTime = (log.sendTime ?? DateTime.now()).formatHHmmssSSS;
    final duration = log.duration?.formatCompactDuration ?? '';
    return requestTime + (log.isLoading ? '' : ' │ $duration');
  }

  /// Method that handles the long press on the log button.
  void _onLongPress(BuildContext context, LongPressStartDetails details) {
    final localDx = details.localPosition.dx;

    final renderObject = context.findRenderObject();

    if (renderObject case final RenderBox renderBox) {
      final threshold = renderBox.size.width * 0.5;

      Helpers.copyAndShowSnackBar(
        context,
        contentToCopy: log.request.toCurlString(
          addBacktick: localDx <= threshold,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThunderColors.of(context);
    final statusCode = Helpers.getStatusCode(log);

    return GestureDetector(
      onLongPressStart: (details) => _onLongPress(context, details),
      child: CupertinoButton(
        onPressed: () => onLogTap(log),
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
                      if (log.request.url.scheme == 'https') ...[
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 10,
                          color: colors.cRed,
                        ),
                        const SizedBox(width: 4),
                      ],

                      /// Request Base URL
                      Expanded(
                        child: Text(
                          log.request.url.host,
                          style: TextStyle(
                            color: colors.gray,
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
                        log.request.url.path,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.brilliantAzure,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    /// Request Size
                    if (!log.isLoading)
                      Text(
                        '${Helpers.formatBytes(log.sendBytes)}'
                        ' / ${Helpers.formatBytes(log.receiveBytes)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.cBlack,
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
                        style: TextStyle(
                          color: colors.cWhite,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    /// Request Time | Request duration
                    Text(
                      _requestTimeDuration,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colors.cBlack,
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
                        statusCode,
                        style: TextStyle(
                          color: switch (int.tryParse(statusCode)) {
                            int i when i >= 200 && i < 300 => colors.cGreen,
                            _ => colors.cRed,
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
      ),
    );
  }
}
