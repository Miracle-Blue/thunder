import 'package:flutter/foundation.dart';

/// Rebuild trigger for the Socket tab of the logs screen.
///
/// Holds no data — session state lives in the static session list of
/// `ThunderLogsController`; individual sessions notify their own listeners.
final class ThunderWebSocketLogNotifier extends ChangeNotifier {
  /// Notifies listeners that the WebSocket session list changed.
  void notify() => notifyListeners();
}
