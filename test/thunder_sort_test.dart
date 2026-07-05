import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:thunder/src/common/models/thunder_network_log.dart';
import 'package:thunder/src/feature/controllers/thunder_logs_controller.dart';
import 'package:thunder/src/feature/overlays/sort_by_alert_dialog.dart';
import 'package:thunder/thunder.dart';

ThunderNetworkLog _log({required String id, Duration? duration}) =>
    ThunderNetworkLog(
      request: ApiClientRequest(
        http.Request('GET', Uri.parse('https://example.com/$id')),
      ),
      isLoading: false,
      duration: duration,
      id: id,
    );

void main() {
  test('comparatorFor(null) means do not sort', () {
    expect(ThunderLogsController.comparatorFor(null), isNull);
  });

  test('responseTime sorts deterministically with nulls last', () {
    final fast = _log(id: 'fast', duration: const Duration(milliseconds: 50));
    final slow = _log(id: 'slow', duration: const Duration(milliseconds: 100));
    final pending = _log(id: 'pending');

    final comparator = ThunderLogsController.comparatorFor(
      SortType.responseTime,
    )!;

    final first = [slow, pending, fast]..sort(comparator);
    final second = [pending, fast, slow]..sort(comparator);

    expect(first.map((log) => log.id), ['fast', 'slow', 'pending']);
    expect(second.map((log) => log.id), ['fast', 'slow', 'pending']);
  });

  test('endpoint sorts by request path', () {
    final logs = [_log(id: 'b'), _log(id: 'a'), _log(id: 'c')]
      ..sort(ThunderLogsController.comparatorFor(SortType.endpoint)!);

    expect(logs.map((log) => log.id), ['a', 'b', 'c']);
  });
}
