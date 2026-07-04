import 'package:flutter/material.dart';

import '../../common/models/socket_state.dart';
import '../../common/models/thunder_web_socket_log.dart';
import '../../common/models/thunder_web_socket_session.dart';
import '../../common/utils/colors.dart';
import '../../common/utils/date_time_extension.dart';
import '../../common/utils/helpers.dart';
import '../controllers/thunder_ws_log_detail_controller.dart';

/// Screen that shows the live timeline of a WebSocket session.
class ThunderWsLogDetailScreen extends StatefulWidget {
  /// Constructor for the [ThunderWsLogDetailScreen] class.
  const ThunderWsLogDetailScreen({required this.session, super.key});

  /// The WebSocket session to display.
  final ThunderWebSocketSession session;

  @override
  State<ThunderWsLogDetailScreen> createState() =>
      _ThunderWsLogDetailScreenState();
}

class _ThunderWsLogDetailScreenState extends ThunderWsLogDetailController {
  @override
  // GestureDetector, not InkWell: a pushed route has no Material ancestor.
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => FocusScope.of(context).unfocus(),
    child: Scaffold(
      backgroundColor: Color.lerp(
        ThunderColors.of(context).gray,
        ThunderColors.of(context).thunderBackground,
        0.9,
      ),
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.3),
        leading: InkWell(
          onTap: () => Navigator.of(context).pop<void>(),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 24,
            color: ThunderColors.of(context).cBlack,
          ),
        ),
        title: Text(
          'Socket session',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: ThunderColors.of(context).cWhite,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _SessionSummary(session: widget.session),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.only(top: 4, bottom: 96),
                      itemCount: widget.session.events.length,
                      itemBuilder: (context, index) => _SocketEventTile(
                        log: widget.session.events[index],
                        onCopy: onCopyEventTap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 24, bottom: 32),
              child: FloatingActionButton(
                onPressed: onCopyTranscriptTap,
                tooltip: 'Copy session transcript',
                backgroundColor: ThunderColors.of(context).surface,
                child: Icon(
                  Icons.copy_all_rounded,
                  color: ThunderColors.of(context).cBlack,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Compact header with the session's endpoint, state and counters.
class _SessionSummary extends StatelessWidget {
  const _SessionSummary({required this.session});

  final ThunderWebSocketSession session;

  String get _stateText => switch (session.state) {
    SocketConnecting() => 'Connecting…',
    SocketConnected() => 'Connected',
    SocketReconnecting(:final attempt) => 'Reconnecting (attempt $attempt)',
    SocketDisconnected() => 'Disconnected',
  };

  @override
  Widget build(BuildContext context) {
    final stateColor = _stateColor(context, session.state);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
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
              DecoratedBox(
                decoration: BoxDecoration(
                  color: stateColor,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(width: 10, height: 10),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  session.label ?? session.uri.toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ThunderColors.of(context).brilliantAzure,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$_stateText'
            ' · ↑${session.sentCount} ↓${session.receivedCount}'
            ' · ${Helpers.formatBytes(session.totalBytes)}'
            ' · started ${session.createdAt.formatHHmmssSSS}',
            style: TextStyle(
              color: ThunderColors.of(context).gray,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// One row of the session timeline.
///
/// Sent/received frames render as side-aligned cards; state, error and
/// system events render as centered pills so they stand out from traffic.
class _SocketEventTile extends StatelessWidget {
  const _SocketEventTile({required this.log, required this.onCopy});

  final ThunderWebSocketLog log;
  final void Function(ThunderWebSocketLog log) onCopy;

  @override
  Widget build(BuildContext context) {
    final colors = ThunderColors.of(context);

    return InkWell(
      onLongPress: () => onCopy(log),
      child: switch (log.direction) {
        ThunderWebSocketDirection.sent => _FrameCard(
          log: log,
          alignment: Alignment.centerRight,
          accent: colors.cGreen,
          icon: Icons.arrow_upward_rounded,
          title: 'SENT',
        ),
        ThunderWebSocketDirection.received => _FrameCard(
          log: log,
          alignment: Alignment.centerLeft,
          accent: colors.brilliantAzure,
          icon: Icons.arrow_downward_rounded,
          title: 'RECEIVED',
        ),
        ThunderWebSocketDirection.state => _EventPill(
          log: log,
          color: colors.gray,
          icon: Icons.bolt_rounded,
        ),
        ThunderWebSocketDirection.error => _EventPill(
          log: log,
          color: colors.cRed,
          icon: Icons.error_outline_rounded,
        ),
        ThunderWebSocketDirection.system => _EventPill(
          log: log,
          color: colors.gray,
          icon: Icons.info_outline_rounded,
        ),
      },
    );
  }
}

/// A side-aligned card for a sent or received frame.
class _FrameCard extends StatelessWidget {
  const _FrameCard({
    required this.log,
    required this.alignment,
    required this.accent,
    required this.icon,
    required this.title,
  });

  final ThunderWebSocketLog log;
  final Alignment alignment;
  final Color accent;
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Align(
    alignment: alignment,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: accent),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            log.messageText,
            maxLines: 12,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ThunderColors.of(context).cBlack,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${log.timestamp.formatHHmmssSSS}'
            ' · ${Helpers.formatBytes(log.byteSize)}',
            style: TextStyle(
              color: ThunderColors.of(context).gray,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

/// A centered pill for state transitions, errors and annotations.
class _EventPill extends StatelessWidget {
  const _EventPill({
    required this.log,
    required this.color,
    required this.icon,
  });

  final ThunderWebSocketLog log;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${log.messageText} · ${log.timestamp.formatHHmmssSSS}',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Color _stateColor(BuildContext context, SocketState state) => switch (state) {
  SocketConnected() => ThunderColors.of(context).cGreen,
  SocketConnecting() ||
  SocketReconnecting() => ThunderColors.of(context).cYellow,
  SocketDisconnected() => ThunderColors.of(context).cRed,
};
