import 'package:decimal/decimal.dart';

import '../engine/formatter.dart';

/// Formats a tool result with the Settings grouping and locale marks.
///
/// Tools show two decimals, like the loan money rows; [decimalPlaces] is there
/// for a future tool that needs another precision.
String formatToolNumber(
  Decimal value, {
  NumberFormatOptions options = const NumberFormatOptions(),
  int decimalPlaces = 2,
}) => formatNumber(
  value,
  options: NumberFormatOptions(
    decimalPlaces: decimalPlaces,
    useGrouping: options.useGrouping,
    decimalSeparator: options.decimalSeparator,
    groupSeparator: options.groupSeparator,
  ),
);

/// Formats a whole count (days, weeks) with the Settings grouping.
String formatToolCount(
  int value, {
  NumberFormatOptions options = const NumberFormatOptions(),
}) => formatToolNumber(
  Decimal.fromInt(value),
  options: options,
  decimalPlaces: 0,
);
