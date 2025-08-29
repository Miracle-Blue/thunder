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
  static List<ThunderNetworkLog> networkLogs = <ThunderNetworkLog>[];

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
      _middlewareInstance ??= ThunderMiddleware(
          onNetworkActivity: (log) => _instance?.setState(() {
                final index = networkLogs.indexWhere(
                  (existingLog) => existingLog.id == log.id,
                );

                if (index >= 0) {
                  networkLogs[index] = log;
                } else {
                  networkLogs.add(log);
                }
              }));

  /// Show the sort by alert dialog and update the sort type.
  static Future<void> onSortLogsTap() async {
    if (ThunderLogsController.inLogDetailScreen) {
      return;
    }

    final context = _instance?.context;
    if (context == null) {
      return;
    }

    // Check if dialog is already open, if so, return early
    if (_isDialogOpen) {
      return Navigator.of(context, rootNavigator: true).pop<void>();
    }

    _isDialogOpen = true;

    try {
      final result = await showSortByAlertDialog(context, sortType: sortType);

      if (result != null) {
        sortType = result;
      }

      _instance?.setState(
        () => switch (result) {
          SortType.createTime => networkLogs.sort(
              (a, b) =>
                  a.sendTime?.compareTo(b.sendTime ?? DateTime.now()) ?? 0,
            ),
          SortType.responseTime => networkLogs.sort(
              (a, b) => a.duration?.compareTo(b.duration ?? Duration.zero) ?? 0,
            ),
          SortType.endpoint => networkLogs.sort(
              (a, b) => a.request.url.path.compareTo(b.request.url.path),
            ),
          SortType.responseSize => networkLogs.sort(
              (a, b) => a.receiveBytes?.compareTo(b.receiveBytes ?? 0) ?? 0,
            ),
          _ => null,
        },
      );
    } finally {
      _isDialogOpen = false;
    }
  }

  /// Method to delete all network logs.
  static void onDeleteAllLogsTap() {
    if (ThunderLogsController.inLogDetailScreen) {
      return;
    }

    if (_isDialogOpen && _instance != null) {
      Navigator.of(_instance!.context).pop<void>();
    }

    _instance?.setState(networkLogs.clear);
  }

  /// Static method to toggle the search.
  static void toggleSearch() {
    if (ThunderLogsController.inLogDetailScreen) {
      return;
    }

    if (_isDialogOpen && _instance != null) {
      Navigator.of(_instance!.context).pop<void>();
    }

    _instance?.setState(() => searchEnabled = !searchEnabled);
  }

  // void _onNetworkActivity(ThunderNetworkLog log) => setState(() {
  //       final index = networkLogs.indexWhere(
  //         (existingLog) => existingLog.id == log.id,
  //       );

  //       if (index >= 0) {
  //         networkLogs[index] = log;
  //       } else {
  //         networkLogs.add(log);
  //       }
  //     });

  // bool _listEquals<T>(List<T> a, List<T> b) {
  //   if (a.length != b.length) return false;

  //   for (var i = 0; i < a.length; i++) {
  //     if (a[i] != b[i]) return false;
  //   }

  //   return true;
  // }

  /// Method to search logs by their endpoint or base url
  void onSearchChanged(String query) => setState(() {
        if (query.isEmpty) {
          if (_tempNetworkLogs != null) {
            networkLogs = List<ThunderNetworkLog>.from(_tempNetworkLogs!);
            _tempNetworkLogs = null;
          }
        } else {
          _tempNetworkLogs ??= List<ThunderNetworkLog>.from(networkLogs);

          networkLogs = _tempNetworkLogs
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

  // @override
  // void didUpdateWidget(covariant ThunderLogsScreen oldWidget) {
  //   // Check for changes in the Dio instances
  //   if (!_listEquals<Dio>(widget.dios, oldWidget.dios)) {
  //     _setupInterceptors();
  //   }
  //   super.didUpdateWidget(oldWidget);
  // }

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

// void _log(String message) => log(name: 'Thunder', message);
