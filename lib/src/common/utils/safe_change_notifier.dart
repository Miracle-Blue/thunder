import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Adds frame-safe notification to a [ChangeNotifier].
///
/// [notifyListenersSafely] behaves like [notifyListeners] but, when called
/// during a frame's build/layout/paint phase, defers the notification to the
/// end of that frame. This avoids the "setState() or markNeedsBuild() called
/// during build" crash when a notification is emitted synchronously from a
/// widget's build (e.g. an HTTP request fired from `initState`).
///
/// Only the notification is deferred: any state mutated before the call is
/// already applied, so listeners never see stale data — at most the rebuild
/// is delayed by one frame.
mixin SafeChangeNotifier on ChangeNotifier {
  bool _disposed = false;

  /// Notifies listeners, deferring to the end of the current frame when
  /// invoked during that frame's persistent (build/layout/paint) phase.
  void notifyListenersSafely() {
    if (_disposed) return;

    final binding = SchedulerBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      binding.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
