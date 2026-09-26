import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:thunder/src/common/models/thunder_network_log.dart';
import 'package:thunder/src/feature/widgets/log_response_widget.dart';
import 'package:thunder/thunder.dart';

void main() {
  testWidgets('a large response body is lazy and scrolls on iOS', (
    tester,
  ) async {
    final request = ApiClientRequest(
      http.Request('GET', Uri.parse('https://example.com/big')),
    );
    final log = ThunderNetworkLog(
      request: request,
      isLoading: false,
      response: ApiClientResponse.json(
        <String, Object?>{for (var i = 0; i < 2000; i++) 'key_$i': i},
        statusCode: 200,
        headers: const <String, String>{'content-type': 'application/json'},
        contentLength: 0,
        persistentConnection: false,
        request: request,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(child: LogResponseWidget(log: log)),
      ),
    );
    // The body is pretty-printed in an isolate via `compute`.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('"key_10"'), findsOneWidget);
    // Off-screen lines are not built: the body is lazy.
    expect(find.textContaining('"key_1999"'), findsNothing);

    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    // Start the drag on a visible point of the body text.
    await tester.dragFrom(
      tester.getTopLeft(find.textContaining('"key_10"')) + const Offset(8, 8),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();

    expect(position.pixels, greaterThan(0));
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
