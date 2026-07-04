import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../common/models/thunder_network_log.dart';
import '../../common/utils/colors.dart';
import '../controllers/thunder_log_detail_controller.dart';
import '../widgets/log_overview_widget.dart';
import '../widgets/log_preview_widget.dart';
import '../widgets/log_request_widget.dart';
import '../widgets/log_response_widget.dart';

/// Screen that shows the details of a network request
class ThunderLogDetailScreen extends StatefulWidget {
  /// Constructor for the [ThunderLogDetailScreen] class.
  const ThunderLogDetailScreen({required this.log, super.key});

  /// The network log to display
  final ThunderNetworkLog log;

  @override
  State<ThunderLogDetailScreen> createState() => _ThunderLogDetailScreenState();
}

class _ThunderLogDetailScreenState extends ThunderLogDetailController {
  @override
  // GestureDetector, not InkWell: a pushed route has no Material ancestor.
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => FocusScope.of(context).unfocus(),
    child: CupertinoPageScaffold(
      backgroundColor: Color.lerp(
        ThunderColors.of(context).gray,
        ThunderColors.of(context).thunderBackground,
        0.9,
      ),
      navigationBar: CupertinoNavigationBar(
        automaticBackgroundVisibility: false,
        backgroundColor: Colors.black.withValues(alpha: 0.3),
        leading: InkWell(
          onTap: () => Navigator.of(context).pop<void>(),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 24,
            color: ThunderColors.of(context).cBlack,
          ),
        ),
        middle: Text(
          'THUNDER - HTTP Request detail',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: ThunderColors.of(context).cWhite,
          ),
        ),
        bottom: TabBar(
          controller: tabController,
          labelColor: ThunderColors.of(context).cWhite,
          unselectedLabelColor: ThunderColors.of(context).gray,
          dividerHeight: 0.8,
          dividerColor: Colors.transparent,
          indicatorColor: ThunderColors.of(context).cWhite,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline)),
            Tab(icon: Icon(Icons.arrow_upward_rounded)),
            Tab(icon: Icon(Icons.arrow_downward_rounded)),
            Tab(icon: Icon(Icons.preview_outlined)),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: TabBarView(
              controller: tabController,
              children: [
                LogOverviewWidget(log: widget.log),
                LogRequestWidget(log: widget.log),
                LogResponseWidget(log: widget.log),
                LogPreviewWidget(log: widget.log),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 24, bottom: 32),
              child: FloatingActionButton(
                onPressed: onCopyLogTap,
                tooltip: 'Copy full log',
                backgroundColor: ThunderColors.of(context).surface,
                child: Icon(
                  Icons.copy_all_rounded,
                  color: ThunderColors.of(context).cBlack,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
