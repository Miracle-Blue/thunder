import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:thunder/src/feature/controllers/thunder_logs_controller.dart';
import 'package:thunder/src/feature/screens/thunder_logs_screen.dart';
import 'package:thunder/src/feature/widgets/log_button.dart';
import 'package:thunder/thunder.dart';

ApiClientRequest _request(String path) => ApiClientRequest(
  http.Request('GET', Uri.parse('https://api.example.com$path')),
);

ApiClientResponse _response(ApiClientRequest request) => ApiClientResponse.json(
  const <String, Object?>{'ok': true},
  statusCode: 200,
  headers: const <String, String>{},
  contentLength: 11,
  persistentConnection: false,
  request: request,
);

void main() {
  setUp(() {
    ThunderLogsController.networkLogs.clear();
    ThunderLogsController.searchEnabled = false;
    ThunderLogsController.inLogDetailScreen = false;
    ThunderLogsController.activeSection.value = ThunderSection.http;
  });

  testWidgets('HTTP search filters live and restores on clear', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Material(child: ThunderLogsScreen())),
    );

    // Real pipeline: logs flow through Thunder.middleware.
    final handler = Thunder.middleware(
      (request, context) async => _response(request),
    );

    await handler(_request('/users'), {});
    await handler(_request('/posts'), {});
    await tester.pump();

    expect(find.byType(LogButton), findsNWidgets(2));

    // Enable search and type a query: only matching logs remain.
    ThunderLogsController.toggleSearch();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'users');
    await tester.pump();

    expect(find.byType(LogButton), findsOneWidget);

    // A matching request arriving mid-search appears immediately (the
    // old snapshot-swap implementation silently dropped it).
    await handler(_request('/users/42'), {});
    await tester.pump();

    expect(find.byType(LogButton), findsNWidgets(2));

    // Clearing the search restores every log, including the new one.
    ThunderLogsController.toggleSearch();
    await tester.pumpAndSettle();

    expect(find.byType(LogButton), findsNWidgets(3));

    // Delete-all empties the canonical list.
    ThunderLogsController.onDeleteAllLogsTap();
    await tester.pump();

    expect(find.text('No logs here yet'), findsOneWidget);
  });
}
