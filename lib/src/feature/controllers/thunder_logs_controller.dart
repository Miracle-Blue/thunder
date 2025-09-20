import 'package:flutter/cupertino.dart';

import '../../common/models/thunder_network_log.dart';
import '../../common/utils/thunder_interceptor.dart';
import '../overlays/sort_by_alert_dialog.dart';
import '../screens/thunder_log_detail_screen.dart';
import '../screens/thunder_logs_screen.dart';

/// Abstract class for the ThunderLogsController controller that manages the network logs.
abstract class ThunderLogsController extends State<ThunderLogsScreen> {
  /// The singleton instance of the controller.
  static ThunderLogsController? _instance;

  /// Singleton instance of the ThunderInterceptor for use before a Thunder widget is created
  static ThunderMiddleware? _middlewareInstance;

  /// The list of network logs.
  static ValueNotifier<List<ThunderNetworkLog>> networkLogs =
      ValueNotifier(<ThunderNetworkLog>[]);

  /// Whether the search is enabled.
  static bool searchEnabled = false;

  /// Whether the log detail screen is currently open.
  static bool inLogDetailScreen = false;

  List<ThunderNetworkLog>? _tempNetworkLogs;

  /// The current sort type for the network logs.
  static SortType sortType = SortType.createTime;

  /// Whether the sort by alert dialog is currently open.
  static bool _isDialogOpen = false;

  /// Adds a Dio instance to be tracked by Thunder
  static ThunderMiddleware getMiddleware() =>
      _middlewareInstance ??= ThunderMiddleware(onNetworkActivity: (log) {
        final index = networkLogs.value.indexWhere(
          (existingLog) => existingLog.id == log.id,
        );

        if (index >= 0) {
          final newNetworkLogs = networkLogs.value;
          newNetworkLogs[index] = log;
          networkLogs.value = newNetworkLogs.toList();
        } else {
          networkLogs.value = [...networkLogs.value, log];
        }
      });

  /// Show the sort by alert dialog and update the sort type.
  static Future<void> onSortLogsTap() async {
    if (ThunderLogsController.inLogDetailScreen) return;

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

      final sortFunction = switch (result) {
        SortType.createTime => (ThunderNetworkLog a, ThunderNetworkLog b) =>
            a.sendTime?.compareTo(b.sendTime ?? DateTime.now()) ?? 0,
        SortType.responseTime => (ThunderNetworkLog a, ThunderNetworkLog b) =>
            a.duration?.compareTo(b.duration ?? Duration.zero) ?? 0,
        SortType.endpoint => (ThunderNetworkLog a, ThunderNetworkLog b) =>
            a.request.url.path.compareTo(b.request.url.path),
        SortType.responseSize => (ThunderNetworkLog a, ThunderNetworkLog b) =>
            a.receiveBytes?.compareTo(b.receiveBytes ?? 0) ?? 0,
        _ => null,
      };

      if (sortFunction != null) networkLogs.value.sort(sortFunction);

      _instance?.setState(() {});
    } finally {
      _isDialogOpen = false;
    }
  }

  /// Method to delete all network logs.
  static void onDeleteAllLogsTap() {
    if (ThunderLogsController.inLogDetailScreen) return;

    if (_isDialogOpen && _instance != null) {
      Navigator.of(_instance!.context).pop<void>();
    }

    _instance?.setState(networkLogs.value.clear);
  }

  /// Static method to toggle the search.
  static void toggleSearch() {
    if (ThunderLogsController.inLogDetailScreen) return;

    if (_isDialogOpen && _instance != null) {
      Navigator.of(_instance!.context).pop<void>();
    }

    _instance?.setState(() {
      searchEnabled = !searchEnabled;

      if (!searchEnabled && _instance?._tempNetworkLogs != null) {
        networkLogs.value =
            List<ThunderNetworkLog>.from(_instance!._tempNetworkLogs!);
        _instance?._tempNetworkLogs = null;
      }
    });
  }

  /// Method to search logs by their endpoint or base url
  void onSearchChanged(String query) => setState(() {
        if (query.isEmpty) {
          if (_tempNetworkLogs != null) {
            networkLogs.value = List<ThunderNetworkLog>.from(_tempNetworkLogs!);
            _tempNetworkLogs = null;
          }
        } else {
          _tempNetworkLogs ??= List<ThunderNetworkLog>.from(networkLogs.value);

          networkLogs.value = _tempNetworkLogs
                  ?.where(
                    (log) =>
                        log.request.url.path.toLowerCase().contains(
                              query.toLowerCase(),
                            ) ||
                        log.request.url.host.toLowerCase().contains(
                              query.toLowerCase(),
                            ),
                  )
                  .toList() ??
              [];
        }
      });

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

  /* region lifecycle */
  @override
  void initState() {
    super.initState();
    _instance = this;
  }

  @override
  void dispose() {
    // Remove all interceptors
    _middlewareInstance = null;

    // Only remove instance reference if this is the current instance
    if (_instance == this) {
      _instance = null;
    }

    super.dispose();
  }

  /* endregion lifecycle */
}
