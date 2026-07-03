import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../common/utils/colors.dart';
import '../controllers/thunder_logs_controller.dart';
import '../widgets/log_button.dart';
import '../widgets/socket_session_button.dart';

/// Screen that shows the logs of the network requests
class ThunderLogsScreen extends StatefulWidget {
  /// Constructor for the [ThunderLogsScreen] class.
  const ThunderLogsScreen({super.key});

  @override
  State<ThunderLogsScreen> createState() => _ThunderLogsScreenState();
}

class _ThunderLogsScreenState extends ThunderLogsController {
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([logNotifier, webSocketLogNotifier]),
    builder: (context, child) => InkWell(
      onTap: () => FocusScope.of(context).unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor: Color.lerp(
          ThunderColors.of(context).gray,
          ThunderColors.of(context).thunderBackground,
          0.9,
        ),
        navigationBar: CupertinoNavigationBar(
          backgroundColor: Colors.black.withValues(alpha: 0.3),
          middle: switch (ThunderLogsController.searchEnabled) {
            true => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: TextField(
                onChanged: onSearchChanged,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: switch (ThunderLogsController.activeSection.value) {
                    ThunderSection.http => 'Search host or path...',
                    ThunderSection.socket => 'Search session URI...',
                  },
                  border: InputBorder.none,
                ),
              ),
            ),
            false => null,
          },
          leading: switch (ThunderLogsController.searchEnabled) {
            true => null,
            false => Text(
              'Thunder Network Monitor',
              style: TextStyle(
                color: ThunderColors.of(context).cWhite,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          },
          bottom: TabBar(
            controller: tabController,
            labelColor: ThunderColors.of(context).cWhite,
            unselectedLabelColor: ThunderColors.of(context).gray,
            dividerHeight: 0.8,
            dividerColor: Colors.transparent,
            indicatorColor: ThunderColors.of(context).cWhite,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              for (final section in ThunderSection.values)
                Tab(text: section.title),
            ],
          ),
        ),
        child: TabBarView(
          controller: tabController,
          children: [
            // HTTP Logs
            if (ThunderLogsController.networkLogs.isEmpty)
              const _EmptyState(
                icon: Icons.cloud_off,
                message: 'No logs here yet',
              )
            else
              ListView.builder(
                itemCount: ThunderLogsController.networkLogs.length,
                itemBuilder: (context, index) => LogButton(
                  log: ThunderLogsController.networkLogs.elementAt(
                    ThunderLogsController.networkLogs.length - index - 1,
                  ),
                  onLogTap: onLogTap,
                ),
              ),

            // Socket Logs
            if (ThunderLogsController.socketSessions.isEmpty)
              const _EmptyState(
                icon: Icons.power_off_rounded,
                message: 'No socket sessions yet',
              )
            else
              ListView.builder(
                itemCount: ThunderLogsController.socketSessions.length,
                itemBuilder: (context, index) => SocketSessionButton(
                  session: ThunderLogsController.socketSessions.elementAt(
                    ThunderLogsController.socketSessions.length - index - 1,
                  ),
                  onSessionTap: onSessionTap,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Placeholder shown when a section has no logs yet.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: ThunderColors.of(context).gray),
        Text(
          message,
          style: TextStyle(
            color: ThunderColors.of(context).gray,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
