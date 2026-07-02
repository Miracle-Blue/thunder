import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../common/models/socket_state.dart';
import '../../common/models/thunder_web_socket_session.dart';
import '../../common/utils/colors.dart';
import '../../common/utils/date_time_extension.dart';
import '../../common/utils/helpers.dart';

/// A widget that displays one WebSocket session row in the Socket tab.
class SocketSessionButton extends StatelessWidget {
  /// Constructor for the [SocketSessionButton] class.
  const SocketSessionButton({
    required this.session,
    required this.onSessionTap,
    super.key,
  });

  /// The WebSocket session to display.
  final ThunderWebSocketSession session;

  /// The function to call when the session row is pressed.
  final void Function(ThunderWebSocketSession session) onSessionTap;

  String get _stateChipText => switch (session.state) {
    SocketConnected() => 'LIVE',
    SocketConnecting() => 'CONNECTING',
    SocketReconnecting(:final attempt) => 'RETRY $attempt',
    SocketDisconnected() => 'CLOSED',
  };

  bool get _isBusy => switch (session.state) {
    SocketConnecting() || SocketReconnecting() => true,
    SocketConnected() || SocketDisconnected() => false,
  };

  @override
  Widget build(BuildContext context) {
    final stateColor = _stateColor(context, session.state);

    return InkWell(
      onLongPress: () => Helpers.copyAndShowSnackBar(
        context,
        contentToCopy: session.uri.toString(),
      ),
      child: CupertinoButton(
        onPressed: () => onSessionTap(session),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.hardEdge,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: stateColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: stateColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    /// Live connection state indicator
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: stateColor,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox(width: 10, height: 10),
                    ),
                    const SizedBox(width: 6),

                    /// For secure connections
                    if (session.uri.scheme == 'wss') ...[
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 10,
                        color: ThunderColors.of(context).cRed,
                      ),
                      const SizedBox(width: 4),
                    ],

                    /// Session label or host
                    Expanded(
                      child: Text(
                        session.label ?? session.uri.host,
                        style: TextStyle(
                          color: ThunderColors.of(context).gray,
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

                /// Session URI + frame counters
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.uri.toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ThunderColors.of(context).brilliantAzure,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '↑${session.sentCount} ↓${session.receivedCount}'
                      ' · ${Helpers.formatBytes(session.totalBytes)}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: ThunderColors.of(context).cBlack,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    /// Connection state chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: stateColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _stateChipText,
                        style: TextStyle(
                          color: ThunderColors.of(context).cWhite,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    /// Last activity time
                    Text(
                      session.lastEventAt.formatHHmmssSSS,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: ThunderColors.of(context).cBlack,
                      ),
                    ),

                    switch (_isBusy) {
                      true => SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          color: stateColor,
                          strokeCap: StrokeCap.round,
                          strokeWidth: 3,
                        ),
                      ),
                      false => Text(
                        '${session.eventCount} events',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: ThunderColors.of(context).cBlack,
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

Color _stateColor(BuildContext context, SocketState state) => switch (state) {
  SocketConnected() => ThunderColors.of(context).cGreen,
  SocketConnecting() ||
  SocketReconnecting() => ThunderColors.of(context).cYellow,
  SocketDisconnected() => ThunderColors.of(context).cRed,
};
