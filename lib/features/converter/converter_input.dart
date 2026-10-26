import 'package:decimal/decimal.dart';

import '../../core/engine/formatter.dart';

/// The typed amount on the unit converter's From card (screen 07).
///
/// The keypad only edits this string; the page converts [value] on every
/// change, so the conversion is live. It is pure Dart, which keeps the editing
/// rules testable without pumping a widget.
final class ConverterInput {
  const ConverterInput([this.source = '']);

  /// At most this many digits, so the 38 px value still fits the card.
  static const int maxDigits = 15;

  /// What the user has typed: digits, at most one `.`, an optional leading `-`.
  final String source;

  bool get isEmpty => source.isEmpty;

  /// The amount to convert; an empty or lone `-` input reads as zero.
  Decimal get value {
    if (source.isEmpty || source == '-') {
      return Decimal.zero;
    }
    return Decimal.parse(source);
  }

  /// The From card value: grouping/locale from [options], typographic `−`.
  String display({NumberFormatOptions options = const NumberFormatOptions()}) {
    if (source.isEmpty) {
      return '0';
    }
    final bool negative = source.startsWith('-');
    final String body = negative ? source.substring(1) : source;
    final String formatted = formatTypedNumber(body, options: options);
    return negative ? '−$formatted' : formatted;
  }

  ConverterInput digit(String digit) {
    if (_digits >= maxDigits) {
      return this;
    }
    if (source == '0') {
      return ConverterInput(digit == '0' ? '0' : digit);
    }
    if (source == '-0') {
      return ConverterInput(digit == '0' ? '-0' : '-$digit');
    }
    return ConverterInput('$source$digit');
  }

  /// The `00` key: two zeroes in one tap (one while the input is still `0`).
  ConverterInput doubleZero() => digit('0').digit('0');

  ConverterInput dot() {
    if (source.contains('.')) {
      return this;
    }
    if (source.isEmpty) {
      return const ConverterInput('0.');
    }
    if (source == '-') {
      return const ConverterInput('-0.');
    }
    return ConverterInput('$source.');
  }

  ConverterInput toggleSign() {
    if (source.isEmpty || source == '0' || source == '-0') {
      return this;
    }
    if (source.startsWith('-')) {
      return ConverterInput(source.substring(1));
    }
    return ConverterInput('-$source');
  }

  ConverterInput backspace() {
    if (source.isEmpty) {
      return this;
    }
    return ConverterInput(source.substring(0, source.length - 1));
  }

  ConverterInput clear() => const ConverterInput();

  int get _digits => source.replaceAll(RegExp('[^0-9]'), '').length;

  @override
  bool operator ==(Object other) =>
      other is ConverterInput && other.source == source;

  @override
  int get hashCode => source.hashCode;

  @override
  String toString() => 'ConverterInput($source)';
}
