import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../extension/middleware_extensions.dart';
import '../models/thunder_network_log.dart';

/// Class that helps with various helper methods
abstract class Helpers {
  const Helpers._();

  static const int _kilobyteAsByte = 1_000;
  static const int _megabyteAsByte = 1_000_000;

  /// Method that formats the bytes to a human readable format
  static String formatBytes(int? bytes) => switch (bytes) {
    null || < 0 => '0B',
    <= _kilobyteAsByte => '${bytes}B',
    <= _megabyteAsByte => '${_formatDouble(bytes / _kilobyteAsByte)}kB',
    _ => '${_formatDouble(bytes / _megabyteAsByte)}MB',
  };

  /// Method that shows a snack bar in iOS style
  static void showSnackBar(
    BuildContext context, {
    String content = 'Copied to your clipboard!',
  }) {
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 50,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(48),
            ),
            child: Text(
              content,
              style: const TextStyle(color: CupertinoColors.white),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    Future<void>.delayed(const Duration(seconds: 3), overlayEntry.remove);
  }

  /// Method that copies the content to the clipboard and shows a snack bar
  static Future<void> copyAndShowSnackBar(
    BuildContext context, {
    required String contentToCopy,
  }) async {
    await Clipboard.setData(ClipboardData(text: contentToCopy));

    if (context.mounted) {
      showSnackBar(context);
    }
  }

  /// get StatusCode from the log
  static String getStatusCode(ThunderNetworkLog log) =>
      switch (log.response?.statusCode) {
        int statusCode => statusCode.toString(),
        _ when log.error != null && log.error is ApiClientException =>
          (log.error as ApiClientException).statusCode.toString(),
        _ => 'null',
      };
}

String _formatDouble(double value) => value.toStringAsFixed(2);
