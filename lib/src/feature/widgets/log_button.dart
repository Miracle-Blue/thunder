import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../common/extension/curl_extension.dart';
import '../../common/extension/duration_extension.dart';
import '../../common/models/thunder_network_log.dart';
import '../../common/utils/app_colors.dart';
import '../../common/utils/date_time_extension.dart';
import '../../common/utils/helpers.dart';

/// A widget that displays a button for a network log.
class LogButton extends StatefulWidget {
  /// Constructor for the [LogButton] class.
  const LogButton({required this.log, required this.onLogTap, super.key});

  /// The network log to display
  final ThunderNetworkLog log;

  /// The function to call when the log button is pressed.
  final void Function(ThunderNetworkLog log) onLogTap;

  @override
  State<LogButton> createState() => _LogButtonState();
}

/// State for the [LogButton] widget.
class _LogButtonState extends State<LogButton> {
  /// Method that handles the long press on the log button.
  void _onLongPress(LongPressStartDetails details) {
    final localDx = details.localPosition.dx;

    final renderObject = context.findRenderObject();

    if (renderObject case final RenderBox renderBox) {
      final threshold = renderBox.size.width * 0.5;

      Helpers.copyAndShowSnackBar(
        context,
        contentToCopy: widget.log.request.toCurlString(localDx <= threshold),
      );
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onLongPressStart: _onLongPress,
    child: CupertinoButton(
      onPressed: () => widget.onLogTap(widget.log),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          clipBehavior: Clip.hardEdge,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.log.methodBackgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: widget.log.methodColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.log.request.url.host.isNotEmpty)
                Row(
                  children: [
                    /// For secure request
                    if (widget.log.request.url.host.contains('https')) ...[
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
                        widget.log.request.url.host,
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
                      widget.log.request.url.path,
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
                  if (!widget.log.isLoading)
                    Text(
                      '${Helpers.formatBytes(widget.log.sendBytes)} / ${Helpers.formatBytes(widget.log.receiveBytes)}',
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
                      color: widget.log.methodColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.log.request.method,
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
                    "${(widget.log.sendTime ?? DateTime.now()).formatHHmmssSSS}${widget.log.isLoading ? '' : '  │  ${widget.log.duration.formatCompactDuration}'}",
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),

                  switch (widget.log.isLoading) {
                    true => SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: widget.log.methodColor,
                        strokeCap: StrokeCap.round,
                        strokeWidth: 3,
                      ),
                    ),
                    false => Text(
                      Helpers.getStatusCode(widget.log),
                      style: TextStyle(
                        color: switch (int.tryParse(
                          Helpers.getStatusCode(widget.log),
                        )) {
                          int i when i >= 200 && i < 300 => const Color(
                            0xFF2ccc84,
                          ),
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
    ),
  );
}
