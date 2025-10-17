import 'package:flutter/material.dart';

import '../../common/utils/app_colors.dart';
import '../../common/utils/helpers.dart';
import 'copyable_text.dart';

/// A widget that displays a row of text with an optional copy button.
class ListRowItem extends StatefulWidget {
  /// Constructor for the [ListRowItem] class.
  const ListRowItem({
    required this.value,
    this.name,
    this.showCopyButton = false,
    this.showDivider = true,
    this.isJson = false,
    super.key,
  });

  /// The name of the item
  final String? name;

  /// The value of the item
  final String? value;

  /// Whether to show the copy button
  final bool showCopyButton;

  /// Whether to show the divider
  final bool showDivider;

  /// Whether the value is JSON
  final bool isJson;

  @override
  State<ListRowItem> createState() => _ListRowItemState();
}

class _ListRowItemState extends State<ListRowItem> {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: EdgeInsets.symmetric(
          vertical: widget.showCopyButton ? 0 : 8,
          horizontal: 6,
        ),
        child: Row(
          crossAxisAlignment: widget.isJson
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            /// If the value is JSON, display it in a column.
            switch (widget.isJson) {
              true => Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.name != null &&
                        (widget.name?.isNotEmpty ?? false)) ...[
                      CopyableText(
                        value: '${widget.name}:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                    ],
                    CopyableText(
                      value: widget.value ?? 'null',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.gunmetal,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              false => Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.name != null &&
                        (widget.name?.isNotEmpty ?? false)) ...[
                      CopyableText(
                        value: '${widget.name}:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: CopyableText(
                        value: widget.value ?? 'null',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.gunmetal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            },
            if (widget.showCopyButton || widget.isJson)
              IconButton(
                onPressed: () => Helpers.copyAndShowSnackBar(
                  context,
                  contentToCopy: widget.value ?? 'null',
                ),
                onLongPress: switch (widget.isJson) {
                  true => () => Helpers.copyAndShowSnackBar(
                    context,
                    contentToCopy: () {
                      var isJson =
                          (widget.value?.startsWith('{') ?? false) &&
                              (widget.value?.endsWith('}') ?? false) ||
                          (widget.value?.startsWith('[') ?? false) &&
                              (widget.value?.endsWith(']') ?? false);

                      return isJson
                          ? '```json\n${widget.value}\n```'
                          : "```json\n${widget.value ?? ''}\n```";
                    }(),
                  ),
                  false => null,
                },
                icon: const Icon(Icons.copy, size: 18),
              ),
          ],
        ),
      ),
      if (widget.showDivider) const Divider(height: 5),
    ],
  );
}
