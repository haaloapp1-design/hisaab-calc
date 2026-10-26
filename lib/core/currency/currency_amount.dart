import 'package:decimal/decimal.dart';

import '../engine/formatter.dart';

/// The amount typed on the currency screen (SPEC §5).
///
/// It is pure Dart so the editing rules (one decimal mark, at most
/// [maxDigits] digits, locale separators) are testable without a widget. The
/// page keeps a [TextField] in sync with [display]; the controller stores
/// [source] in [CurrencyConfig].
final class CurrencyAmount {
  const CurrencyAmount([this.source = '']);

  /// At most this many digits, so the 52 px amount still fits the header.
  static const int maxDigits = 15;

  /// The sanitised input: digits with at most one `.`, no grouping.
  final String source;

  bool get isEmpty => source.isEmpty;

  /// The amount to convert; an empty input reads as zero.
  Decimal get value {
    if (source.isEmpty || source == '.') {
      return Decimal.zero;
    }
    try {
      return Decimal.parse(source);
    } on FormatException {
      return Decimal.zero;
    }
  }

  /// The amount as the user sees it: grouped with the Settings separators.
  String display({NumberFormatOptions options = const NumberFormatOptions()}) =>
      isEmpty ? '' : formatTypedNumber(source, options: options);

  /// Reads what a field or storage row contains and keeps only a valid amount.
  ///
  /// Grouping marks are dropped, the locale decimal mark becomes `.`, other
  /// characters are ignored and a leading mark gets its `0`. Digits beyond
  /// [maxDigits] are dropped instead of rejecting the whole input.
  static CurrencyAmount fromInput(
    String text, {
    NumberFormatOptions options = const NumberFormatOptions(),
  }) {
    String value = text;
    if (options.useGrouping && options.groupSeparator.isNotEmpty) {
      value = value.replaceAll(options.groupSeparator, '');
    }
    if (options.decimalSeparator.isNotEmpty &&
        options.decimalSeparator != '.') {
      value = value.replaceAll(options.decimalSeparator, '.');
    }

    final StringBuffer digits = StringBuffer();
    int count = 0;
    bool hasDot = false;
    for (final int rune in value.runes) {
      final String character = String.fromCharCode(rune);
      if (character == '.') {
        if (!hasDot) {
          if (count == 0) {
            digits.write('0');
            count++;
          }
          digits.write('.');
          hasDot = true;
        }
        continue;
      }
      if (character.compareTo('0') < 0 || character.compareTo('9') > 0) {
        continue;
      }
      if (count == maxDigits) {
        continue;
      }
      digits.write(character);
      count++;
    }

    String source = digits.toString();
    int first = 0;
    while (first < source.length - 1 &&
        source.codeUnitAt(first) == 0x30 &&
        source.codeUnitAt(first + 1) != 0x2E) {
      first++;
    }
    source = source.substring(first);
    return CurrencyAmount(source);
  }

  @override
  bool operator ==(Object other) =>
      other is CurrencyAmount && other.source == source;

  @override
  int get hashCode => source.hashCode;

  @override
  String toString() => 'CurrencyAmount($source)';
}
