import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:thunder/src/common/utils/safe_change_notifier.dart';
import 'package:thunder/src/feature/screens/thunder_logs_screen.dart';
import 'package:thunder/thunder.dart';

void main() {
  testWidgets(
    'starting a request during a widget build does not crash Thunder',
    (tester) async {
      // ThunderLogsScreen (child 0) mounts first: it sets the controller's
      // singleton and its ListenableBuilder starts listening to logNotifier.
      // _RequestOnInit (child 1) then fires a request through Thunder's
      // middleware from initState — synchronously, during this same build.
      // Before the fix that drove logNotifier.notifyListeners() mid-build and
      // threw "setState()/markNeedsBuild() called during build".
      await tester.pumpWidget(
        const MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Expanded(child: ThunderLogsScreen()),
                _RequestOnInit(),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      // Flush the deferred post-frame notification and the async completion.
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('notifyListenersSafely notifies synchronously outside a frame', (
    tester,
  ) async {
    final notifier = _TestNotifier();
    addTearDown(notifier.dispose);

    var count = 0;

    // The test body runs while the scheduler phase is idle (no frame in
    // flight), so the notification must fire synchronously as before.
    notifier
      ..addListener(() => count++)
      ..ping();

    expect(count, 1);
  });
}

/// Widget that fires an HTTP request through [Thunder.middleware] from
/// [State.initState] — i.e. during the build phase.
final class _RequestOnInit extends StatefulWidget {
  const _RequestOnInit();

  @override
  State<_RequestOnInit> createState() => _RequestOnInitState();
}

final class _RequestOnInitState extends State<_RequestOnInit> {
  @override
  void initState() {
    super.initState();

    final handler = Thunder.middleware(
      (request, context) async => ApiClientResponse.json(
        '',
        statusCode: 200,
        headers: const <String, String>{},
        contentLength: 0,
        persistentConnection: false,
        request: request,
      ),
    );

    final request = ApiClientRequest(
      http.Request('GET', Uri.parse('https://example.com')),
    );

    // The middleware emits the request-start log synchronously, before its
    // first await; intentionally not awaited.
    unawaited(handler(request, <String, Object?>{}));
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Minimal notifier exercising [SafeChangeNotifier] in isolation.
final class _TestNotifier extends ChangeNotifier with SafeChangeNotifier {
  void ping() => notifyListenersSafely();
}
