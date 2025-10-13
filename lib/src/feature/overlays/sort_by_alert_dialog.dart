import 'package:flutter/material.dart';

/// Enum representing different sorting options for network logs.
enum SortType {
  /// Sort by creating time
  createTime('Create time'),

  /// Sort by response time
  responseTime('Response time'),

  /// Sort by response size
  responseSize('Response size'),

  /// Sort by endpoint
  endpoint('Endpoint');

  const SortType(this.name);

  /// The name of the sort type
  final String name;

  /// Getter to check current [SortType] is createTime
  bool get isCreateTime => this == createTime;

  /// Getter to check current [SortType] is responseTime
  bool get isResponseTime => this == responseTime;

  /// Getter to check current [SortType] is responseSize
  bool get isResponseSize => this == responseSize;

  /// Getter to check current [SortType] is endpoint
  bool get isEndpoint => this == endpoint;
}

/// ------------------------------------------------------------------------------------------------
/// --------------- Sort by alert dialog ---------------
/// ------------------------------------------------------------------------------------------------

/// ------------------------------------------------------------------------------------------------
/// --- Sort by alert dialog ---
/// ------------------------------------------------------------------------------------------------
Future<SortType?> showSortByAlertDialog(
  BuildContext context, {
  SortType? sortType,
}) async => showDialog<SortType?>(
  context: context,
  builder: (context) => _SortByAlertDialog(sortType: sortType),
);

class _SortByAlertDialog extends StatefulWidget {
  const _SortByAlertDialog({required this.sortType});

  final SortType? sortType;

  @override
  State<_SortByAlertDialog> createState() => _SortByAlertDialogState();
}

class _SortByAlertDialogState extends State<_SortByAlertDialog> {
  late SortType? _sortType;

  @override
  void initState() {
    super.initState();
    _sortType = widget.sortType;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text(
      'Sort by',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        SortType.values.length,
        (index) => InkWell(
          onTap: () => setState(() => _sortType = SortType.values[index]),
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(SortType.values[index].name),
                Radio<SortType>(
                  value: SortType.values[index],
                  groupValue: _sortType,
                  onChanged: (value) => setState(() => _sortType = value),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop<void>(context),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: () => Navigator.pop<SortType>(context, _sortType),
        child: const Text('Apply'),
      ),
    ],
  );
}
