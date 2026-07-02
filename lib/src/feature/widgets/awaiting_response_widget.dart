import 'package:flutter/material.dart';

import '../../common/utils/colors.dart';

/// A widget that displays a circular progress indicator and a message.
class AwaitingResponseWidget extends StatelessWidget {
  /// Constructor for the [AwaitingResponseWidget] class.
  const AwaitingResponseWidget({
    super.key,
    this.message = 'Awaiting response...',
  });

  /// The message to display
  final String message;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            backgroundColor: ThunderColors.of(context).surface,
            color: ThunderColors.of(context).brilliantAzure,
            strokeCap: StrokeCap.round,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: ThunderColors.of(context).cBlack,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}
