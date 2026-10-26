import 'package:calculator/core/currency/currency_format.dart';
import 'package:calculator/core/engine/formatter.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('values', () {
    test('money always shows two decimals and groups', () {
      expect(formatCurrencyValue(Decimal.parse('3590.666')), '3,590.67');
      expect(formatCurrencyValue(Decimal.parse('1234.5')), '1,234.50');
      expect(formatCurrencyValue(Decimal.zero), '0.00');
    });

    test('money follows the locale separators and the typographic minus', () {
      const NumberFormatOptions options = NumberFormatOptions(
        decimalSeparator: ',',
        groupSeparator: '.',
      );
      expect(
        formatCurrencyValue(Decimal.parse('-1234.5'), options: options),
        '−1.234,50',
      );
    });
  });

  group('rates', () {
    test('keeps four significant digits and strips trailing zeros', () {
      expect(formatCurrencyRate(Decimal.parse('278.500')), '278.5');
      expect(formatCurrencyRate(Decimal.parse('278.54321')), '278.5');
      expect(formatCurrencyRate(Decimal.parse('0.00357712')), '0.003577');
      expect(formatCurrencyRate(Decimal.one), '1');
      expect(formatCurrencyRate(Decimal.parse('12345.6')), '12,350');
    });

    test('the rate line names both currencies', () {
      expect(
        formatCurrencyRateLine(
          from: 'USD',
          to: 'PKR',
          rate: Decimal.parse('278.5'),
        ),
        '1 USD = 278.5 PKR',
      );
    });
  });

  test('the fetch date is a deterministic UTC day', () {
    expect(formatRateDate(DateTime.utc(2026, 10, 26, 23, 59)), '26 Oct 2026');
    expect(formatRateDate(DateTime.utc(2026, 1, 2)), '2 Jan 2026');
    expect(formatRateDate(DateTime.utc(2026, 12, 31)), '31 Dec 2026');
  });
}
