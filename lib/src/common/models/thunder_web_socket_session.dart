import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../utils/safe_change_notifier.dart';
import 'socket_state.dart';
import 'thunder_web_socket_log.dart';

/// Mutable aggregate of one WebSocket connection's timeline, rendered as a
/// single row in the Socket tab.
///
/// The session detail screen listens to the session itself (it is a
/// [ChangeNotifier]) rather than to the logs-screen-owned notifiers, so a
/// pushed detail route can never outlive its listenable. Sessions are held
/// in a static list and are never disposed — clearing the list simply drops
/// them for garbage collection.
///
/// Deliberately has no `==`/`hashCode`: the aggregate is mutable.
final class ThunderWebSocketSession extends ChangeNotifier
    with SafeChangeNotifier {
  /// Constructor for the [ThunderWebSocketSession] class.
  ThunderWebSocketSession({required this.id, required this.uri, this.label})
    : createdAt = DateTime.now();

  /// Identifier of the connection this session aggregates.
  final String id;

  /// The remote endpoint of the connection.
  final Uri uri;

  /// Optional human-readable name shown instead of the host.
  final String? label;

  /// When the session was first seen.
  final DateTime createdAt;

  /// Maximum retained timeline events; oldest are dropped. Counters keep
  /// accumulating across the whole connection lifetime.
  static const int _maxEvents = 1000;

  final List<ThunderWebSocketLog> _events = <ThunderWebSocketLog>[];

  /// Live, read-only view of the session's chronological events.
  late final List<ThunderWebSocketLog> events =
      UnmodifiableListView<ThunderWebSocketLog>(_events);

  SocketState _state = const SocketDisconnected();

  /// The most recent connection state.
  SocketState get state => _state;

  DateTime? _lastEventAt;

  /// When the last event was recorded; [createdAt] until the first event.
  DateTime get lastEventAt => _lastEventAt ?? createdAt;

  int _sentCount = 0;

  /// Number of sent frames.
  int get sentCount => _sentCount;

  int _receivedCount = 0;

  /// Number of received frames.
  int get receivedCount => _receivedCount;

  int _totalBytes = 0;

  /// Total payload bytes across sent and received frames.
  int get totalBytes => _totalBytes;

  /// Number of events on the timeline (frames, states, errors, system).
  int get eventCount => _events.length;

  /// Appends [log] to the timeline, updates the aggregates and notifies
  /// listeners.
  void addEvent(ThunderWebSocketLog log) {
    _events.add(log);
    if (_events.length > _maxEvents) _events.removeAt(0);

    switch (log.direction) {
      case ThunderWebSocketDirection.sent:
        _sentCount++;
        _totalBytes += log.byteSize;
      case ThunderWebSocketDirection.received:
        _receivedCount++;
        _totalBytes += log.byteSize;
      case ThunderWebSocketDirection.state:
        if (log.state case final SocketState newState) _state = newState;
      case ThunderWebSocketDirection.error:
      case ThunderWebSocketDirection.system:
        break;
    }

    _lastEventAt = log.timestamp;

    notifyListenersSafely();
  }
}
