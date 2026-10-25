import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

import 'token.dart';

/// Formatting options for the result display (BUSINESS_LOGIC §8).
class NumberFormatOptions {
  const NumberFormatOptions({
    this.decimalPlaces,
    this.useGrouping = true,
    this.decimalSeparator = '.',
    this.groupSeparator = ',',
  });

  /// Fixed decimal places (0–10) or null for Auto: 12 significant digits.
  final int? decimalPlaces;

  /// Thousands separator switch from Settings.
  final bool useGrouping;

  /// Locale decimal mark, e.g. `.` or `,`.
  final String decimalSeparator;

  /// Locale group mark, e.g. `,` or `.`.
  final String groupSeparator;
}

final Decimal _scientificHigh = Decimal.parse('1e15');
final Decimal _scientificLow = Decimal.parse('1e-9');

/// Formats [value] for the display: typographic `−`, locale separators (§8).
String formatNumber(
  Decimal value, {
  NumberFormatOptions options = const NumberFormatOptions(),
}) => _format(value, options, negativeSign: '−');

/// Formats [value] for the clipboard: ASCII `-` instead of `−` (§8.5).
String formatNumberForCopy(
  Decimal value, {
  NumberFormatOptions options = const NumberFormatOptions(),
}) => _format(value, options, negativeSign: '-');

/// §8.6: the expression line keeps the digits the user typed, only grouping
/// the integer part (no rounding, no trailing-zero strip).
String formatTypedNumber(
  String raw, {
  NumberFormatOptions options = const NumberFormatOptions(),
}) {
  final int dot = raw.indexOf('.');
  final String integerPart = dot == -1 ? raw : raw.substring(0, dot);
  final String fraction = dot == -1 ? '' : raw.substring(dot + 1);
  final String integer = options.useGrouping
      ? _group(integerPart, options.groupSeparator)
      : integerPart;
  return dot == -1 ? integer : '$integer${options.decimalSeparator}$fraction';
}

/// §1.1 line 1: renders the typed tokens as the expression line.
///
/// Typed numbers keep exactly what the user entered (only grouping, §8.6).
/// Binary operators get a space on each side (`5 + 3`), the hidden `×` is
/// invisible (`2π`, `3(4 + 1)`), a unary sign hugs its number (`−5`), a
/// function carries its opening bracket (`sin(`) and postfix keys hug the value
/// they apply to (`5!`, `50%`, `5²`). `Ans` shows as `Ans`.
String formatExpression(
  List<Token> tokens, {
  NumberFormatOptions options = const NumberFormatOptions(),
}) {
  final StringBuffer buffer = StringBuffer();
  Token? previous;

  for (final Token token in tokens) {
    // The tokenizer's implicit `×` is not shown to the user.
    if (token is OperatorToken && token.implicit) {
      previous = token;
      continue;
    }

    if (_needsExpressionSpace(previous, token)) {
      buffer.write(' ');
    }
    buffer.write(_expressionToken(token, options));
    previous = token;
  }

  return buffer.toString();
}

bool _needsExpressionSpace(Token? previous, Token token) {
  if (previous == null) {
    return false;
  }
  if (previous is OperatorToken && previous.implicit) {
    return false;
  }
  // Brackets and postfixes belong to the value on their left.
  if (token is RightParenToken || token is PostfixToken) {
    return false;
  }
  // A sign belongs to the number on its right.
  if (previous is LeftParenToken ||
      previous is FunctionToken ||
      previous is UnaryToken) {
    return false;
  }
  return true;
}

String _expressionToken(Token token, NumberFormatOptions options) =>
    switch (token) {
      NumberToken(:final String value) => formatTypedNumber(
        value,
        options: options,
      ),
      OperatorToken(operator: final OperatorType type) => _operatorSymbol(type),
      UnaryToken(:final bool negative) => negative ? '−' : '+',
      LeftParenToken() => '(',
      RightParenToken() => ')',
      FunctionToken(:final String name) => '$name(',
      ConstantToken(:final MathConstant constant) => switch (constant) {
        MathConstant.pi => 'π',
        MathConstant.e => 'e',
      },
      PostfixToken(:final PostfixType postfix) => switch (postfix) {
        PostfixType.factorial => '!',
        PostfixType.percent => '%',
        PostfixType.square => '²',
        PostfixType.cube => '³',
      },
      AnsToken() => 'Ans',
    };

String _operatorSymbol(OperatorType type) => switch (type) {
  OperatorType.add => '+',
  OperatorType.subtract => '−',
  OperatorType.multiply => '×',
  OperatorType.divide => '÷',
  OperatorType.power => '^',
  OperatorType.mod => 'mod',
};

/// Builds options from the locale's [NumberFormat] symbols (§8.4).
NumberFormatOptions numberFormatOptionsFor(
  String locale, {
  int? decimalPlaces,
  bool useGrouping = true,
}) {
  final NumberFormat format = NumberFormat.decimalPattern(locale);
  return NumberFormatOptions(
    decimalPlaces: decimalPlaces,
    useGrouping: useGrouping,
    decimalSeparator: format.symbols.DECIMAL_SEP,
    groupSeparator: format.symbols.GROUP_SEP,
  );
}

String _format(
  Decimal value,
  NumberFormatOptions options, {
  required String negativeSign,
}) {
  final int? places = options.decimalPlaces;
  assert(places == null || (places >= 0 && places <= 10));

  final Decimal rounded = places == null
      ? Decimal.parse(value.toStringAsPrecision(12))
      : value.round(scale: places);
  final Decimal magnitude = rounded.abs();
  final String body = _isScientific(magnitude)
      ? _scientific(magnitude, options)
      : _plain(magnitude, options);
  return rounded < Decimal.zero ? '$negativeSign$body' : body;
}

bool _isScientific(Decimal magnitude) =>
    magnitude >= _scientificHigh ||
    (magnitude > Decimal.zero && magnitude < _scientificLow);

String _plain(Decimal value, NumberFormatOptions options) {
  final int? places = options.decimalPlaces;
  final String raw = places == null
      ? value.toString()
      : value.toStringAsFixed(places);
  final int dot = raw.indexOf('.');
  final String integerPart = dot == -1 ? raw : raw.substring(0, dot);
  final String fraction = dot == -1 ? '' : raw.substring(dot + 1);
  final String integer = options.useGrouping
      ? _group(integerPart, options.groupSeparator)
      : integerPart;
  return dot == -1 ? integer : '$integer${options.decimalSeparator}$fraction';
}

/// §8.2: at most 10 mantissa digits. Auto strips trailing zeros; a fixed
/// setting keeps them (`1.00E+18`).
String _scientific(Decimal value, NumberFormatOptions options) {
  final int? places = options.decimalPlaces;
  final int fractionDigits = places == null ? 9 : (places > 9 ? 9 : places);
  final String raw = value.toStringAsExponential(fractionDigits);
  final int e = raw.indexOf('e');
  String mantissa = raw.substring(0, e);
  final String exponent = raw.substring(e + 1).toUpperCase();

  if (places == null && mantissa.contains('.')) {
    mantissa = mantissa.replaceFirst(RegExp(r'0+$'), '');
    if (mantissa.endsWith('.')) {
      mantissa = mantissa.substring(0, mantissa.length - 1);
    }
  }

  return '${mantissa.replaceFirst('.', options.decimalSeparator)}E$exponent';
}

String _group(String digits, String separator) {
  if (digits.length <= 3) {
    return digits;
  }
  final StringBuffer buffer = StringBuffer();
  final int lead = digits.length % 3;
  if (lead > 0) {
    buffer.write(digits.substring(0, lead));
  }
  for (int i = lead; i < digits.length; i += 3) {
    if (buffer.isNotEmpty) {
      buffer.write(separator);
    }
    buffer.write(digits.substring(i, i + 3));
  }
  return buffer.toString();
}
