import 'package:flutter/material.dart';

import '../../common/models/thunder_web_socket_log.dart';
import '../../common/utils/date_time_extension.dart';
import '../../common/utils/helpers.dart';
import '../screens/thunder_ws_log_detail_screen.dart';

/// Abstract class that extends [State] and helps to control the
/// [ThunderWsLogDetailScreen].
///
/// The controller listens to the session itself (a `ChangeNotifier`) for
/// live timeline updates — never to the logs-screen-owned notifiers, whose
/// lifecycle this route can outlive. Sessions are never disposed, so the
/// listener is always safe; if the session list is cleared while this
/// screen is open, the screen simply keeps rendering its snapshot.
abstract class ThunderWsLogDetailController
    extends State<ThunderWsLogDetailScreen> {
  /// Scroll controller for the timeline list.
  final ScrollController scrollController = ScrollController();

  bool get _isNearBottom {
    if (!scrollController.hasClients) return true;

    final position = scrollController.position;
    return position.pixels >= position.maxScrollExtent - 100;
  }

  void _onSessionChanged() {
    if (!mounted) return;

    final pinned = _isNearBottom;

    setState(() {});

    // Stick to the bottom while the user hasn't scrolled up.
    if (!pinned) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) return;
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    });
  }

  /// Copies a single timeline event's text to the clipboard.
  void onCopyEventTap(ThunderWebSocketLog log) =>
      Helpers.copyAndShowSnackBar(context, contentToCopy: log.messageText);

  /// Copies the whole session transcript to the clipboard.
  void onCopyTranscriptTap() {
    final session = widget.session;

    final buffer = StringBuffer()
      ..writeln('WebSocket session: ${session.label ?? session.uri}')
      ..writeln('URI: ${session.uri}')
      ..writeln('Created: ${session.createdAt.formatDDMMYYYYHHmmssSSS}')
      ..writeln(
        'Sent: ${session.sentCount} · Received: ${session.receivedCount}'
        ' · ${Helpers.formatBytes(session.totalBytes)}',
      )
      ..writeln();

    for (final event in session.events) {
      buffer.writeln(
        '[${event.timestamp.formatHHmmssSSS}]'
        ' [${event.direction.name.toUpperCase()}]'
        ' ${event.messageText}',
      );
    }

    Helpers.copyAndShowSnackBar(context, contentToCopy: buffer.toString());
  }

  /* region lifecycle */
  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionChanged);
    scrollController.dispose();
    super.dispose();
  }

  /* endregion lifecycle */
}
