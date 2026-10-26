import 'package:calculator/core/currency/currency_amount.dart';
import 'package:calculator/core/engine/formatter.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('value and display', () {
    test('an empty amount is zero and shows nothing', () {
      const CurrencyAmount amount = CurrencyAmount();
      expect(amount.isEmpty, isTrue);
      expect(amount.value, Decimal.zero);
      expect(amount.display(), '');
    });

    test('parses the source exactly and groups the integer part', () {
      const CurrencyAmount amount = CurrencyAmount('10000.50');
      expect(amount.value, Decimal.parse('10000.50'));
      expect(amount.display(), '10,000.50');
    });

    test('follows the locale separators', () {
      const CurrencyAmount amount = CurrencyAmount('1234.5');
      const NumberFormatOptions options = NumberFormatOptions(
        decimalSeparator: ',',
        groupSeparator: '.',
      );
      expect(amount.display(options: options), '1.234,5');
    });
  });

  group('fromInput', () {
    test('drops grouping and keeps one decimal mark', () {
      expect(CurrencyAmount.fromInput('10,000').source, '10000');
      expect(CurrencyAmount.fromInput('10,000.5').source, '10000.5');
      expect(CurrencyAmount.fromInput('1.2.3').source, '1.23');
    });

    test('reads the locale decimal mark', () {
      const NumberFormatOptions options = NumberFormatOptions(
        decimalSeparator: ',',
        groupSeparator: '.',
      );
      expect(
        CurrencyAmount.fromInput('1.234,56', options: options).source,
        '1234.56',
      );
    });

    test('ignores letters and a leading decimal mark gets a zero', () {
      expect(CurrencyAmount.fromInput('12a3').source, '123');
      expect(CurrencyAmount.fromInput('.5').source, '0.5');
      expect(CurrencyAmount.fromInput('abc').source, '');
    });

    test('normalises leading zeros but keeps 0.x', () {
      expect(CurrencyAmount.fromInput('0005').source, '5');
      expect(CurrencyAmount.fromInput('00.50').source, '0.50');
      expect(CurrencyAmount.fromInput('0').source, '0');
    });

    test('caps the number of digits at maxDigits', () {
      final String fifteen = List<String>.filled(
        CurrencyAmount.maxDigits,
        '1',
      ).join();
      expect(CurrencyAmount.fromInput('${fifteen}99').source, fifteen);
      expect(fifteen.length, CurrencyAmount.maxDigits);
    });

    test('a trailing decimal mark survives so typing can continue', () {
      expect(CurrencyAmount.fromInput('12.').source, '12.');
      expect(CurrencyAmount.fromInput('12.').display(), '12.');
    });
  });
}
