import 'package:flutter/material.dart';

import '../../common/utils/copy_log_data.dart';
import '../../common/utils/helpers.dart';
import '../screens/thunder_log_detail_screen.dart';

/// Abstract class that extends [State] and [TickerProviderStateMixin] and helps to control the [ThunderLogDetailScreen]
abstract class ThunderLogDetailController extends State<ThunderLogDetailScreen>
    with TickerProviderStateMixin {
  /// The tab controller for the [ThunderLogDetailScreen]
  late final TabController tabController;

  /// Method that handles the copy log tap
  void onCopyLogTap() => Helpers.copyAndShowSnackBar(
    context,
    contentToCopy: CopyLogData(log: widget.log).toCopyableLogData,
  );

  /* region lifecycle */
  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  /* endregion lifecycle */
}
