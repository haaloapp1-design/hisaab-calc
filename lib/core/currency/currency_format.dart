import 'package:decimal/decimal.dart';

import '../engine/formatter.dart';

/// Formats money values, rate lines and the fetch date of screen 08.
///
/// It is pure Dart and follows the same [NumberFormatOptions] as the rest of
/// the app, so the currency screen groups digits and uses the locale decimal
/// mark like the calculator and the unit converter.

/// A converted amount: always two decimals (`35.91`, `1,234.00`).
String formatCurrencyValue(
  Decimal value, {
  NumberFormatOptions options = const NumberFormatOptions(),
}) => formatNumber(
  value,
  options: NumberFormatOptions(
    decimalPlaces: 2,
    useGrouping: options.useGrouping,
    decimalSeparator: options.decimalSeparator,
    groupSeparator: options.groupSeparator,
  ),
);

/// A rate with four significant digits and no trailing zeros (`278.5`,
/// `0.003577`).
///
/// Four digits keep both a large PKR rate and a small USD rate readable in the
/// 12 px line under a currency name.
String formatCurrencyRate(
  Decimal rate, {
  NumberFormatOptions options = const NumberFormatOptions(),
}) {
  final Decimal rounded = Decimal.parse(rate.toStringAsPrecision(4));
  final Decimal magnitude = rounded.abs();
  final String raw = magnitude.toString();
  final int dot = raw.indexOf('.');
  final String integerPart = dot == -1 ? raw : raw.substring(0, dot);
  final String fraction = dot == -1 ? '' : raw.substring(dot + 1);
  final String integer = options.useGrouping
      ? groupDigits(integerPart, separator: options.groupSeparator)
      : integerPart;
  final String body = dot == -1
      ? integer
      : '$integer${options.decimalSeparator}$fraction';
  return rounded < Decimal.zero ? '−$body' : body;
}

/// `1 USD = 278.5 PKR`, the line under a target currency.
String formatCurrencyRateLine({
  required String from,
  required String to,
  required Decimal rate,
  NumberFormatOptions options = const NumberFormatOptions(),
}) => '1 $from = ${formatCurrencyRate(rate, options: options)} $to';

/// The fetch date shown by the status line, e.g. `26 Oct 2026`.
///
/// The stored moment is UTC and the app shows that calendar day, so the text
/// is deterministic in tests and does not depend on the device timezone. The
/// month names are fixed because the app itself is English.
String formatRateDate(DateTime fetchedAt) {
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final DateTime utc = fetchedAt.toUtc();
  return '${utc.day} ${months[utc.month - 1]} ${utc.year}';
}
