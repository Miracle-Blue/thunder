import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../common/utils/app_colors.dart';
import '../controllers/thunder_logs_controller.dart';
import '../widgets/log_button.dart';

/// Screen that shows the logs of the network requests
class ThunderLogsScreen extends StatefulWidget {
  /// Constructor for the [ThunderLogsScreen] class.
  const ThunderLogsScreen({super.key});

  @override
  State<ThunderLogsScreen> createState() => _ThunderLogsScreenState();
}

class _ThunderLogsScreenState extends ThunderLogsController {
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: CupertinoPageScaffold(
          backgroundColor: AppColors.white,
          navigationBar: CupertinoNavigationBar(
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            middle: switch (ThunderLogsController.searchEnabled) {
              true => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: TextField(
                    onChanged: onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: 'Type here...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              false => null,
            },
            leading: switch (ThunderLogsController.searchEnabled) {
              true => null,
              false => const Text(
                  'Thunder Network Monitor',
                  style: TextStyle(
                    color: AppColors.lavaStone,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
            },
          ),
          child: Stack(
            children: [
              switch (ThunderLogsController.networkLogs.isEmpty) {
                true => const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off,
                            size: 48, color: AppColors.grayRussian),
                        Text(
                          'No logs here yet',
                          style: TextStyle(
                            color: AppColors.grayRussian,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                false => ListView.builder(
                    itemCount: ThunderLogsController.networkLogs.length,
                    itemBuilder: (context, index) => LogButton(
                      log: ThunderLogsController.networkLogs[
                          ThunderLogsController.networkLogs.length - 1 - index],
                      onLogTap: onLogTap,
                    ),
                  ),
              },
            ],
          ),
        ),
      );
}
