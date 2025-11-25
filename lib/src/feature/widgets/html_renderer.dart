import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;

import '../../common/utils/app_colors.dart';
import '../../common/utils/helpers.dart';

/// A widget that parses HTML content and renders it as Flutter widgets.
class HtmlRenderer extends StatefulWidget {
  /// Constructor for the [HtmlRenderer] class.
  const HtmlRenderer({required this.htmlContent, super.key});

  /// The HTML content to render
  final String htmlContent;

  @override
  State<HtmlRenderer> createState() => _HtmlRendererState();
}

class _HtmlRendererState extends State<HtmlRenderer> {
  late dom.Document _document;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _parseHtml();
  }

  @override
  void didUpdateWidget(HtmlRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.htmlContent != widget.htmlContent) _parseHtml();
  }

  void _parseHtml() {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      _document = html.parse(widget.htmlContent);

      setState(() => _isLoading = false);
    } on Object catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to parse HTML: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) => switch (_isLoading) {
        true => const Center(child: CircularProgressIndicator()),
        _ when _errorMessage != null => Center(
            child: Text(
              _errorMessage ?? '',
              style: TextStyle(color: Colors.red[800]),
            ),
          ),
        _ when _document.body == null => const Center(
            child: Text('No content available.'),
          ),
        _ => () {
            final children = _parseNodes(_document.body?.nodes ?? <dom.Node>[]);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            );
          }(),
      };

  /// Recursively parses a list of DOM nodes into Flutter widgets.
  List<Widget> _parseNodes(List<dom.Node> nodes) {
    var widgets = <Widget>[];

    for (final node in nodes) {
      Widget? childWidget;

      if (node is dom.Element) {
        childWidget = _parseElement(node);
      } else if (node is dom.Text) {
        final text = node.text.trim();

        if (text.isNotEmpty) {
          childWidget = Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }
      }

      if (childWidget != null) widgets.add(childWidget);
    }

    return widgets;
  }

  /// Converts a DOM element into a Flutter widget based on its tag.
  Widget _parseElement(dom.Element element) {
    final theme = Theme.of(context);

    switch (element.localName?.toLowerCase()) {
      case 'h1':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            element.text,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        );

      case 'h2':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            element.text,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        );

      case 'h3':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            element.text,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        );

      case 'h4':
      case 'h5':
      case 'h6':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            element.text,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        );

      case 'p':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: _handleInlineElements(element),
        );

      case 'a':
        final href = element.attributes['href'] ?? '#';
        return InkWell(
          onTap: () =>
              Helpers.copyAndShowSnackBar(context, contentToCopy: href),
          child: Text(
            element.text,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.mainColor,
              decoration: TextDecoration.underline,
            ),
          ),
        );

      case 'strong':
      case 'b':
        return Text(
          element.text,
          style: const TextStyle(fontWeight: FontWeight.bold),
        );

      case 'em':
      case 'i':
        return Text(
          element.text,
          style: const TextStyle(fontStyle: FontStyle.italic),
        );

      case 'u':
        return Text(
          element.text,
          style: const TextStyle(decoration: TextDecoration.underline),
        );

      case 'img':
        return _buildImageWidget(element);

      case 'ul':
        return Padding(
          padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: element.children.map<SingleChildRenderObjectWidget>((
              child,
            ) {
              if (child.localName?.toLowerCase() == 'li') {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 16)),
                      Expanded(child: _handleInlineElements(child)),
                    ],
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            }).toList(),
          ),
        );

      case 'ol':
        return Padding(
          padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: element.children.asMap().entries.map((entry) {
              var index = entry.key;
              var child = entry.value;

              if (child.localName?.toLowerCase() == 'li') {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}. ',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Expanded(child: _handleInlineElements(child)),
                    ],
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            }).toList(),
          ),
        );

      case 'blockquote':
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: theme.dividerColor, width: 4),
            ),
            color: theme.cardColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _parseNodes(element.nodes),
          ),
        );

      case 'code':
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            element.text,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[300]
                  : Colors.grey[900],
            ),
          ),
        );

      case 'pre':
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            element.text,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[300]
                  : Colors.grey[900],
            ),
          ),
        );

      case 'hr':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Divider(color: theme.dividerColor, thickness: 1),
        );

      // For container-like elements, we simply render their children.
      case 'header':
      case 'footer':
      case 'nav':
      case 'main':
      case 'article':
      case 'section':
      case 'div':
      case 'span':
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _parseNodes(element.nodes),
          ),
        );

      default:
        // Default is to process children if the tag isn't specifically handled.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _parseNodes(element.nodes),
        );
    }
  }

  /// Handles inline formatting elements
  /// like <strong>, <em>, etc. within a paragraph
  Widget _handleInlineElements(dom.Element element) {
    // If the element contains only text, return a simple text widget
    if (element.nodes.length == 1 && element.nodes.first is dom.Text) {
      return Text(element.text, style: Theme.of(context).textTheme.bodyMedium);
    }

    // Otherwise, create a more complex widget with inline spans
    var spans = <InlineSpan>[];

    for (final node in element.nodes) {
      if (node is dom.Text) {
        final text = node.text.trim();
        if (text.isNotEmpty) {
          spans.add(
            TextSpan(text: text, style: Theme.of(context).textTheme.bodyMedium),
          );
        }
      } else if (node is dom.Element) {
        switch (node.localName?.toLowerCase()) {
          case 'strong':
          case 'b':
            spans.add(
              TextSpan(
                text: node.text,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
            break;
          case 'em':
          case 'i':
            spans.add(
              TextSpan(
                text: node.text,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            );
            break;
          case 'u':
            spans.add(
              TextSpan(
                text: node.text,
                style: const TextStyle(decoration: TextDecoration.underline),
              ),
            );
            break;
          case 'a':
            final href = node.attributes['href'] ?? '#';
            spans.add(
              TextSpan(
                text: node.text,
                style: TextStyle(
                  color: AppColors.mainColor,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () =>
                      Helpers.copyAndShowSnackBar(context, contentToCopy: href),
              ),
            );
            break;
          case 'code':
            spans.add(
              TextSpan(
                text: node.text,
                style: TextStyle(
                  fontFamily: 'monospace',
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[200],
                ),
              ),
            );
            break;
          default:
            spans.add(TextSpan(text: node.text));
        }
      }
    }

    return RichText(text: TextSpan(children: spans));
  }

  /// Builds an image widget with proper loading and error handling
  Widget _buildImageWidget(dom.Element element) {
    final src = element.attributes['src'] ?? '';
    final alt = element.attributes['alt'] ?? 'Image';
    final width = double.tryParse(element.attributes['width'] ?? '');
    final height = double.tryParse(element.attributes['height'] ?? '');

    return Container(
      constraints: BoxConstraints(
        maxWidth: width ?? double.infinity,
        maxHeight: height ?? double.infinity,
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: switch (src.isNotEmpty) {
        true => Image.network(
            src,
            fit: BoxFit.contain,
            width: width,
            height: height,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;

              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          (loadingProgress.expectedTotalBytes ?? 1)
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              width: width ?? 100,
              height: height ?? 100,
              color: Colors.grey[300],
              alignment: Alignment.center,
              child: Text(
                alt,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          ),
        false => const SizedBox.shrink(),
      },
    );
  }
}
