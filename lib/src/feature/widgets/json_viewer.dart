library;

import 'package:flutter/material.dart';

import '../../common/utils/helpers.dart';
import 'copyable_text.dart';

/// Utility class with helper functions for JSON viewing.
class JsonViewerUtils {
  const JsonViewerUtils._();

  /// Returns true if [content] is expandable (i.e. a Map or List).
  static bool isExpandable(Object? content) =>
      content is Map || content is List;

  /// Returns true if the widget should have InkWell (interactive) behavior.
  // For primitives (int, String, bool, double), we don't need InkWell.
  static bool isInkWell(Object? content) => isExpandable(content);

  /// Returns a string representing the type of [content].
  static String getTypeName(Object? content) {
    if (content is int) return 'int';
    if (content is String) return 'String';
    if (content is bool) return 'bool';
    if (content is double) return 'double';
    if (content is List<Object?>) return 'List';
    if (content is Map<String, Object?>) return 'Object';

    return 'Unknown';
  }
}

/// Main widget that displays a
/// JSON structure in a hierarchical and interactive way.
class JsonViewer extends StatelessWidget {
  /// Constructor for the [JsonViewer] class.
  const JsonViewer(this.jsonObj, {super.key});

  /// The JSON object to display
  final Object? jsonObj;

  @override
  Widget build(BuildContext context) => _buildContent(jsonObj);

  /// Determines the type of
  /// JSON content and delegates to the appropriate viewer.
  Widget _buildContent(Object? content) {
    if (content == null) return const CopyableText(value: '{}');

    if (content is List) {
      return JsonArrayViewer(jsonArray: content, notRoot: false);
    } else if (content is Map<String, Object?>) {
      return JsonObjectViewer(jsonObj: content, notRoot: false);
    }
    return CopyableText(value: content.toString());
  }
}

/// Widget for viewing JSON objects (Maps).
class JsonObjectViewer extends StatefulWidget {
  /// Constructor for the [JsonObjectViewer] class.
  const JsonObjectViewer({
    required this.jsonObj,
    super.key,
    this.notRoot = false,
  });

  /// The JSON object to display
  final Map<String, Object?> jsonObj;

  /// Whether the JSON object is not the root object
  final bool notRoot;

  @override
  JsonObjectViewerState createState() => JsonObjectViewerState();
}

/// State for the [JsonObjectViewer] widget.
class JsonObjectViewerState extends State<JsonObjectViewer> {
  /// Stores open/closed state for each JSON key.
  final Map<String, bool> _openFlags = {};

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildContentList(),
      );

  /// Builds a list of rows representing each key-value pair.
  List<Widget> _buildContentList() =>
      widget.jsonObj.entries.map<Column>((entry) {
        final key = entry.key;
        final value = entry.value;
        final expandable = JsonViewerUtils.isExpandable(value);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row for key and value preview.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // If expandable, show a toggle icon.
                if (expandable)
                  InkWell(
                    onTap: () => setState(
                      () => _openFlags[key] = !(_openFlags[key] ?? false),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Icon(
                      _openFlags[key] ?? false
                          ? Icons.arrow_drop_down
                          : Icons.arrow_right,
                      color: Colors.grey[700],
                    ),
                  )
                else
                  const SizedBox(width: 8),

                // Display key.
                CopyableText(
                  value: key,
                  style: TextStyle(
                    color: value == null ? Colors.grey : Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const Text(':', style: TextStyle(color: Colors.grey)),

                // Value preview.
                Expanded(child: _buildValuePreview(key, value)),
              ],
            ),
            const SizedBox(height: 4),

            // If expanded, render nested content.
            if (expandable && (_openFlags[key] ?? false))
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: _buildContentWidget(value),
              ),
          ],
        );
      }).toList();

  /// Returns a widget showing a preview for the given [value].
  Widget _buildValuePreview(String key, Object? value) {
    if (value == null) {
      return const CopyableText(
        value: 'undefined',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      );
    } else if (value is int || value is double) {
      return CopyableText(
        value: value.toString(),
        style: const TextStyle(color: Color(0xff6491b3), fontSize: 12),
      );
    } else if (value is String) {
      return CopyableText(
        value: '"$value"',
        style: const TextStyle(color: Color(0xff6a8759), fontSize: 12),
      );
    } else if (value is bool) {
      return CopyableText(
        value: value.toString(),
        style: const TextStyle(color: Color(0xffca7832), fontSize: 12),
      );
    } else if (value is List) {
      if (value.isEmpty) {
        return _buildCopyableText(
          context: context,
          text: 'Array[0]',
          onTap: () =>
              setState(() => _openFlags[key] = !(_openFlags[key] ?? false)),
        );
      }
      return _buildCopyableText(
        context: context,
        text: 'Array<'
            '${JsonViewerUtils.getTypeName(value.first)}'
            '>['
            '${value.length}'
            ']',
        onTap: () =>
            setState(() => _openFlags[key] = !(_openFlags[key] ?? false)),
      );
    }

    // For Map or other objects.
    return _buildCopyableText(
      context: context,
      text: 'Object',
      onTap: () =>
          setState(() => _openFlags[key] = !(_openFlags[key] ?? false)),
    );
  }

  /// Wraps text in an InkWell to allow tap and double-tap (copy) functionality.
  Widget _buildCopyableText({
    required BuildContext context,
    required String text,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        onDoubleTap: () =>
            Helpers.copyAndShowSnackBar(context, contentToCopy: text),
        child: Text(text,
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
      );

  /// Returns a widget for nested JSON content.
  Widget _buildContentWidget(Object? content) {
    if (content is List) {
      return JsonArrayViewer(jsonArray: content, notRoot: true);
    } else if (content is Map<String, Object?>) {
      return JsonObjectViewer(jsonObj: content, notRoot: true);
    }
    return CopyableText(value: content.toString());
  }
}

/// Widget for viewing JSON arrays (Lists).
class JsonArrayViewer extends StatefulWidget {
  /// Constructor for the [JsonArrayViewer] class.
  const JsonArrayViewer({
    required this.jsonArray,
    super.key,
    this.notRoot = false,
  });

  /// The JSON array to display
  final List<Object?> jsonArray;

  /// Whether the JSON array is not the root array
  final bool notRoot;

  @override
  State<JsonArrayViewer> createState() => _JsonArrayViewerState();
}

class _JsonArrayViewerState extends State<JsonArrayViewer> {
  late List<bool> _openFlags;

  @override
  void initState() {
    super.initState();
    // Initialize expansion flags for each element.
    _openFlags = List<bool>.filled(widget.jsonArray.length, false);
  }

  @override
  Widget build(BuildContext context) {
    final contentWidgets = _buildContentList();
    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: contentWidgets,
    );

    return widget.notRoot
        ? Padding(padding: const EdgeInsets.only(left: 14), child: child)
        : child;
  }

  /// Builds a list of rows for each array element.
  List<Widget> _buildContentList() =>
      List<Widget>.generate(widget.jsonArray.length, (i) {
        final value = widget.jsonArray[i];
        final expandable = JsonViewerUtils.isExpandable(value);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row for index and value preview.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (expandable)
                  InkWell(
                    onTap: () => setState(() => _openFlags[i] = !_openFlags[i]),
                    borderRadius: BorderRadius.circular(16),
                    child: Icon(
                      _openFlags[i] ? Icons.arrow_drop_down : Icons.arrow_right,
                      color: Colors.grey[700],
                    ),
                  )
                else
                  const SizedBox(width: 24),
                CopyableText(
                  value: '[$i]',
                  style: TextStyle(
                    color: value == null ? Colors.grey : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Text(': ', style: TextStyle(color: Colors.grey)),
                Expanded(child: _buildValuePreview(i, value)),
              ],
            ),
            // Render nested content if expanded.
            if (expandable && _openFlags[i])
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: _buildContentWidget(value),
              ),
          ],
        );
      });

  /// Returns a preview widget for the array element at [index].
  Widget _buildValuePreview(int index, Object? value) {
    if (value == null) {
      return const CopyableText(
        value: 'undefined',
        style: TextStyle(color: Colors.grey),
      );
    } else if (value is int || value is double) {
      return CopyableText(
        value: value.toString(),
        style: const TextStyle(color: Color(0xff6491b3)),
      );
    } else if (value is String) {
      return CopyableText(
        value: '"$value"',
        style: const TextStyle(color: Color(0xff6a8759)),
      );
    } else if (value is bool) {
      return CopyableText(
        value: value.toString(),
        style: const TextStyle(color: Color(0xffca7832)),
      );
    } else if (value is List) {
      if (value.isEmpty) {
        return _buildCopyableText(
          context: context,
          text: 'Array[0]',
          onTap: () => setState(() => _openFlags[index] = !_openFlags[index]),
        );
      }
      return _buildCopyableText(
        context: context,
        text: 'Array<'
            '${JsonViewerUtils.getTypeName(value.first)}'
            '>['
            '${value.length}'
            ']',
        onTap: () => setState(() => _openFlags[index] = !_openFlags[index]),
      );
    }
    // For Map or other objects.
    return _buildCopyableText(
      context: context,
      text: 'Object',
      onTap: () => setState(() => _openFlags[index] = !_openFlags[index]),
    );
  }

  /// Wraps [text] in an InkWell for tap and double-tap (copy) behavior.
  Widget _buildCopyableText({
    required BuildContext context,
    required String text,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        onDoubleTap: () =>
            Helpers.copyAndShowSnackBar(context, contentToCopy: text),
        child: Text(text, style: const TextStyle(color: Colors.grey)),
      );

  /// Returns a widget for nested JSON content.
  Widget _buildContentWidget(Object? content) {
    if (content is List) {
      return JsonArrayViewer(jsonArray: content, notRoot: true);
    } else if (content is Map<String, Object?>) {
      return JsonObjectViewer(jsonObj: content, notRoot: true);
    }
    return CopyableText(value: content.toString());
  }
}
