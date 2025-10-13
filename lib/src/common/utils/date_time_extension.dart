/// Extension on [DateTime] to format it as a string.
extension DateTimeExtension on DateTime {
  /// Format the date time as a HH:mm:ss:SSS string.
  ///
  /// Example:
  /// ```dart
  /// final dateTime = DateTime.now();
  /// final formattedDateTime = dateTime.formatHHmmssSSS; // '12:34:56:789'
  /// ```
  String get formatHHmmssSSS =>
      '${hour.toString().padLeft(2, '0')}'
      ':${minute.toString().padLeft(2, '0')}'
      ':${second.toString().padLeft(2, '0')}'
      ':${millisecond.toString().padLeft(3, '0')}';

  /// Format the date time as a dd-MM-yyyy HH:mm:ss:SSS string.
  ///
  /// Example:
  /// ```dart
  /// final dateTime = DateTime.now();
  /// final formattedDateTime = dateTime.formatDDMMYYYYHHmmssSSS; // '12-01-2021 12:34:56:789'
  /// ```
  String get formatDDMMYYYYHHmmssSSS =>
      '${day.toString().padLeft(2, '0')}'
      '-${month.toString().padLeft(2, '0')}'
      '-${year.toString()}'
      ' ${hour.toString().padLeft(2, '0')}'
      ':${minute.toString().padLeft(2, '0')}'
      ':${second.toString().padLeft(2, '0')}'
      ':${millisecond.toString().padLeft(3, '0')}';
}
