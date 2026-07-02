import 'package:flutter/foundation.dart';

import '../../common/models/thunder_network_log.dart';

/// Notifier for the network logs.
final class ThunderLogNotifier extends ChangeNotifier {
  /// The list of network logs.
  List<ThunderNetworkLog> networkLogs = <ThunderNetworkLog>[];

  /// Method to add a network log.
  void addLog(ThunderNetworkLog log) {
    final index = networkLogs.indexWhere(
      (existingLog) => existingLog.id == log.id,
    );

    if (index >= 0) {
      networkLogs[index] = log;
    } else {
      networkLogs.add(log);
    }

    notifyListeners();
  }
}
