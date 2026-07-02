import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thunder/src/feature/screens/thunder_logs_screen.dart';
import 'package:thunder/src/feature/screens/thunder_ws_log_detail_screen.dart';
import 'package:thunder/src/feature/widgets/socket_session_button.dart';
import 'package:thunder/thunder.dart';

void main() {
  testWidgets('Socket tab lists sessions and opens a live detail timeline', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Material(child: ThunderLogsScreen())),
    );

    // Both tabs exist; the HTTP tab starts with its own empty state.
    expect(find.text('HTTP'), findsOneWidget);
    expect(find.text('Socket'), findsOneWidget);
    expect(find.text('No logs here yet'), findsOneWidget);

    // The Socket tab is reachable even though there are zero HTTP logs,
    // and shows its own empty state.
    await tester.tap(find.text('Socket'));
    await tester.pumpAndSettle();
    expect(find.text('No socket sessions yet'), findsOneWidget);

    // A WebSocket event creates a session row without any HTTP traffic.
    final interceptor = Thunder.webSocketInterceptor(
      uri: Uri.parse('wss://example.com/feed'),
      label: 'Test session',
    )..logState(const SocketConnecting());
    await tester.pump();

    expect(find.byType(SocketSessionButton), findsOneWidget);
    expect(find.text('Test session'), findsOneWidget);
    expect(find.text('CONNECTING'), findsOneWidget);

    // Frames update the row's counters live.
    interceptor
      ..logState(const SocketConnected())
      ..logSent('ping')
      ..logReceived('pong');
    await tester.pump();

    expect(find.text('LIVE'), findsOneWidget);
    expect(find.textContaining('↑1 ↓1'), findsOneWidget);

    // Tapping the session opens the timeline detail screen.
    await tester.tap(find.byType(SocketSessionButton));
    await tester.pumpAndSettle();

    expect(find.byType(ThunderWsLogDetailScreen), findsOneWidget);
    expect(find.text('THUNDER - Socket session'), findsOneWidget);
    expect(find.text('ping'), findsOneWidget);
    expect(find.text('pong'), findsOneWidget);
    expect(find.textContaining('Connected'), findsWidgets);

    // The open timeline live-appends new events.
    interceptor.logReceived('live-update');
    await tester.pump();
    await tester.pump();
    expect(find.text('live-update'), findsOneWidget);

    // Back to the list; the row survived and still renders.
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(SocketSessionButton), findsOneWidget);
  });
}
