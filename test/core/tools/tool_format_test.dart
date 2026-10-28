import 'package:calculator/core/engine/formatter.dart';
import 'package:calculator/core/tools/tool_format.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Decimal d(String source) => Decimal.parse(source);

  test('formats two decimals with the Settings grouping', () {
    expect(formatToolNumber(d('1234.5')), '1,234.50');
    expect(formatToolNumber(Decimal.zero), '0.00');
  });

  test('follows the locale and grouping switch', () {
    expect(
      formatToolNumber(
        d('1234.5'),
        options: const NumberFormatOptions(
          useGrouping: false,
          decimalSeparator: '.',
          groupSeparator: ',',
        ),
      ),
      '1234.50',
    );
    expect(
      formatToolNumber(
        d('1234.5'),
        options: const NumberFormatOptions(
          decimalSeparator: ',',
          groupSeparator: '.',
        ),
      ),
      '1.234,50',
    );
  });

  test('uses the typographic minus and honours decimalPlaces', () {
    expect(formatToolNumber(d('-1234.5')), '−1,234.50');
    expect(formatToolNumber(d('1234.5'), decimalPlaces: 0), '1,235');
  });
}
