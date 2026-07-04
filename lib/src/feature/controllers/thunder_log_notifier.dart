import 'package:flutter/foundation.dart';

import '../../common/utils/safe_change_notifier.dart';

/// Rebuild trigger for the HTTP tab of the logs screen.
///
/// Holds no data — log state lives in the static log list of
/// `ThunderLogsController`.
final class ThunderLogNotifier extends ChangeNotifier with SafeChangeNotifier {
  /// Notifies listeners that the network log list changed.
  void notify() => notifyListenersSafely();
}
