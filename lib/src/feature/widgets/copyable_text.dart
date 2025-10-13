import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../common/utils/app_colors.dart';

/// A custom selectable text widget that displays a string with a copy button.
class CopyableText extends StatefulWidget {
  /// Constructor for the [CopyableText] class.
  const CopyableText({required this.value, this.style, super.key});

  /// The value of the text.
  final String? value;

  /// The style of the text.
  final TextStyle? style;

  @override
  State<CopyableText> createState() => _CopyableTextState();
}

class _CopyableTextState extends State<CopyableText> {
  @override
  Widget build(BuildContext context) => SelectableText(
    widget.value ?? 'null',
    style:
        widget.style ??
        const TextStyle(
          fontSize: 12.5,
          color: AppColors.gunmetal,
          fontWeight: FontWeight.w500,
        ),
    contextMenuBuilder: (context, editableTextState) =>
        AdaptiveTextSelectionToolbar.buttonItems(
          buttonItems: [
            ContextMenuButtonItem(
              onPressed: () {
                final selectedText = editableTextState
                    .textEditingValue
                    .selection
                    .textInside(editableTextState.textEditingValue.text);

                Clipboard.setData(ClipboardData(text: selectedText));
                ContextMenuController.removeAny();
              },
              type: ContextMenuButtonType.copy,
            ),
          ],
          anchors: editableTextState.contextMenuAnchors,
        ),
  );
}
