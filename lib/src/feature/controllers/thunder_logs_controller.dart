import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../common/models/thunder_network_log.dart';
import '../../common/models/thunder_web_socket_log.dart';
import '../../common/models/thunder_web_socket_session.dart';
import '../../common/utils/thunder_interceptor.dart';
import '../../common/utils/thunder_ws_interceptor.dart';
import '../overlays/sort_by_alert_dialog.dart';
import '../screens/thunder_log_detail_screen.dart';
import '../screens/thunder_logs_screen.dart';
import '../screens/thunder_ws_log_detail_screen.dart';
import 'thunder_log_notifier.dart';
import 'thunder_ws_log_notifier.dart';

/// The section (tab) of the Thunder logs screen.
enum ThunderSection {
  /// HTTP request/response logs.
  http('HTTP'),

  /// WebSocket session logs.
  socket('Socket');

  /// Constructor for the [ThunderSection] enum.
  const ThunderSection(this.title);

  /// The title shown on the section's tab.
  final String title;

  /// Whether this is the HTTP section.
  bool get isHttp => this == ThunderSection.http;

  /// Whether this is the Socket section.
  bool get isSocket => this == ThunderSection.socket;
}

/// Abstract class for the ThunderLogsController controller
/// that manages the network logs.
abstract class ThunderLogsController extends State<ThunderLogsScreen>
    with SingleTickerProviderStateMixin {
  /// The singleton instance of the controller.
  static ThunderLogsController? _instance;

  /// Singleton instance of the ThunderInterceptor
  /// for use before a Thunder widget is created
  static ThunderMiddleware? _middlewareInstance;

  /// The list of network logs.
  static List<ThunderNetworkLog> networkLogs = <ThunderNetworkLog>[];

  /// The currently visible section (tab) of the logs screen.
  ///
  /// The screen updates it on tab changes; the overlay toolbar and the
  /// static section-aware actions react to it. App-lifetime static —
  /// never disposed.
  static final ValueNotifier<ThunderSection> activeSection =
      ValueNotifier<ThunderSection>(ThunderSection.http);

  /// Canonical list of WebSocket sessions, in creation order.
  static final List<ThunderWebSocketSession> _allSocketSessions =
      <ThunderWebSocketSession>[];

  /// The active search query of the visible section.
  static String _searchQuery = '';

  /// Whether the search is enabled.
  static bool searchEnabled = false;

  /// Whether the log detail screen is currently open.
  static bool inLogDetailScreen = false;

  /// The current sort type for the network logs.
  static SortType sortType = SortType.createTime;

  /// Whether the sort by alert dialog is currently open.
  static bool _isDialogOpen = false;

  /// The WebSocket sessions to render: the canonical list, or a filtered
  /// copy while a Socket-tab search query is active.
  static List<ThunderWebSocketSession> get socketSessions {
    final query = _searchQuery.trim().toLowerCase();
    if (!searchEnabled || query.isEmpty) return _allSocketSessions;

    return _allSocketSessions
        .where(
          (session) =>
              session.uri.toString().toLowerCase().contains(query) ||
              (session.label?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }

  /// The network logs to render: the canonical list, or a filtered copy
  /// while an HTTP-tab search query is active.
  static List<ThunderNetworkLog> get visibleNetworkLogs {
    final query = _searchQuery.trim().toLowerCase();
    if (!searchEnabled || query.isEmpty) return networkLogs;

    return networkLogs
        .where(
          (log) =>
              log.request.url.path.toLowerCase().contains(query) ||
              log.request.url.host.toLowerCase().contains(query),
        )
        .toList();
  }

  /// Lazily creates the middleware feeding Thunder's HTTP tab.
  static ThunderMiddleware get getMiddleware =>
      _middlewareInstance ??= ThunderMiddleware(
        onNetworkActivity: (log) {
          // Upsert by id: each request emits twice (loading → completed)
          // and must occupy a single row.
          final index = networkLogs.indexWhere(
            (existingLog) => existingLog.id == log.id,
          );

          if (index >= 0) {
            networkLogs[index] = log;
          } else {
            networkLogs.add(log);
          }

          _instance?.logNotifier.notify();
        },
      );

  /// Creates a logging interceptor wired into Thunder's Socket tab.
  ///
  /// One interceptor represents one WebSocket connection (one session row).
  static ThunderWebSocketInterceptor socketLogger({
    required Uri uri,
    String? label,
  }) => ThunderWebSocketInterceptor(
    uri: uri,
    label: label,
    onLog: (log) => _onWebSocketLog(log, label: label),
  );

  static void _onWebSocketLog(ThunderWebSocketLog log, {String? label}) {
    final index = _allSocketSessions.indexWhere(
      (session) => session.id == log.connectionId,
    );

    final ThunderWebSocketSession session;
    if (index >= 0) {
      session = _allSocketSessions[index];
    } else {
      session = ThunderWebSocketSession(
        id: log.connectionId,
        uri: log.uri,
        label: label,
      );
      _allSocketSessions.add(session);
    }

    session.addEvent(log);
    _instance?.webSocketLogNotifier.notify();
  }

  /// Show the sort by alert dialog and update the sort type.
  static Future<void> onSortLogsTap() async {
    if (ThunderLogsController.inLogDetailScreen) return;

    // Sorting applies to HTTP logs only.
    if (activeSection.value.isSocket) return;

    final context = _instance?.context;
    if (context == null) return;

    // Check if dialog is already open, if so, return early
    if (_isDialogOpen) {
      return Navigator.of(context, rootNavigator: true).pop<void>();
    }

    _isDialogOpen = true;

    try {
      final result = await showSortByAlertDialog(context, sortType: sortType);

      if (result != null) sortType = result;

      final sortFunction = comparatorFor(result);

      if (sortFunction != null) networkLogs.sort(sortFunction);

      _instance?.setState(() {});
    } finally {
      _isDialogOpen = false;
    }
  }

  /// Comparator for the given [sortType]; `null` fields sort last.
  /// A `null` [sortType] (dialog dismissed) means "don't sort".
  @visibleForTesting
  static Comparator<ThunderNetworkLog>? comparatorFor(SortType? sortType) =>
      switch (sortType) {
        SortType.createTime =>
          (ThunderNetworkLog a, ThunderNetworkLog b) =>
              _compareNullable(a.sendTime, b.sendTime),
        SortType.responseTime =>
          (ThunderNetworkLog a, ThunderNetworkLog b) =>
              _compareNullable(a.duration, b.duration),
        SortType.endpoint =>
          (ThunderNetworkLog a, ThunderNetworkLog b) =>
              a.request.url.path.compareTo(b.request.url.path),
        SortType.responseSize =>
          (ThunderNetworkLog a, ThunderNetworkLog b) =>
              _compareNullable(a.receiveBytes, b.receiveBytes),
        null => null,
      };

  static int _compareNullable(Comparable<Object?>? a, Comparable<Object?>? b) =>
      switch ((a, b)) {
        (null, null) => 0,
        (null, _) => 1,
        (_, null) => -1,
        _ => a!.compareTo(b),
      };

  /// Method to delete all logs of the currently visible section.
  static void onDeleteAllLogsTap() {
    if (ThunderLogsController.inLogDetailScreen) return;

    if (_isDialogOpen && _instance != null) {
      Navigator.of(_instance!.context).pop<void>();
    }

    _instance?.setState(() {
      switch (activeSection.value) {
        case ThunderSection.http:
          networkLogs.clear();
        case ThunderSection.socket:
          // Sessions are dropped, not disposed: an open detail screen may
          // still listen to one; a live connection lazily re-creates its
          // session on the next event.
          _allSocketSessions.clear();
      }
    });
  }

  /// Static method to toggle the search.
  static void toggleSearch() {
    if (ThunderLogsController.inLogDetailScreen) return;

    if (_isDialogOpen && _instance != null) {
      Navigator.of(_instance!.context).pop<void>();
    }

    _instance?.setState(() {
      searchEnabled = !searchEnabled;

      if (!searchEnabled) _searchQuery = '';
    });
  }

  /// Method to search logs of the visible section by their endpoint,
  /// base url or session URI.
  void onSearchChanged(String query) =>
      setState(() => ThunderLogsController._searchQuery = query);

  /// Method to navigate to the log detail screen.
  Future<void> onLogTap(ThunderNetworkLog log) async {
    ThunderLogsController.inLogDetailScreen = true;

    await Navigator.push<void>(
      context,
      CupertinoPageRoute<void>(
        builder: (context) => ThunderLogDetailScreen(log: log),
      ),
    );

    ThunderLogsController.inLogDetailScreen = false;
  }

  /// Method to navigate to the WebSocket session detail screen.
  Future<void> onSessionTap(ThunderWebSocketSession session) async {
    ThunderLogsController.inLogDetailScreen = true;

    await Navigator.push<void>(
      context,
      CupertinoPageRoute<void>(
        builder: (context) => ThunderWsLogDetailScreen(session: session),
      ),
    );

    ThunderLogsController.inLogDetailScreen = false;
  }

  /// The notifier for the network logs.
  late final ThunderLogNotifier logNotifier;

  /// The notifier for the WebSocket logs.
  late final ThunderWebSocketLogNotifier webSocketLogNotifier;

  /// The tab controller switching between the HTTP and Socket sections.
  late final TabController tabController;

  void _onTabChanged() {
    final section = ThunderSection.values[tabController.index];
    if (activeSection.value == section) return;

    activeSection.value = section;

    // A half-applied query must not keep filtering the previous section.
    if (searchEnabled) toggleSearch();
  }

  /* region lifecycle */
  @override
  void initState() {
    super.initState();
    _instance = this;
    logNotifier = ThunderLogNotifier();
    webSocketLogNotifier = ThunderWebSocketLogNotifier();
    tabController = TabController(
      initialIndex: activeSection.value.index,
      length: ThunderSection.values.length,
      vsync: this,
    )..addListener(_onTabChanged);
  }

  @override
  void dispose() {
    // Remove all interceptors
    _middlewareInstance = null;

    tabController
      ..removeListener(_onTabChanged)
      ..dispose();

    logNotifier.dispose();
    webSocketLogNotifier.dispose();

    // Only remove instance reference if this is the current instance
    if (_instance == this) {
      _instance = null;
    }

    super.dispose();
  }

  /* endregion lifecycle */
}
