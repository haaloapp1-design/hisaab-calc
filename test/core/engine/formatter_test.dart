import 'package:calculator/core/engine/formatter.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

Decimal d(String source) => Decimal.parse(source);

String auto(Decimal value) => formatNumber(value);

void main() {
  group('Auto: 12 significant digits', () {
    test('keeps exact decimals and strips trailing zeros', () {
      expect(auto(d('0.3')), '0.3');
      expect(auto(d('1.2300')), '1.23');
      expect(auto(d('2.000')), '2');
      expect(auto(Decimal.zero), '0');
    });

    test('rounds to 12 significant digits', () {
      expect(auto(d('1.234567890123456')), '1.23456789012');
      expect(auto(d('0.0001234567890123456')), '0.000123456789012');
      expect(auto(d('0.99999999999999999999999999999999')), '1');
    });

    test('groups the integer part', () {
      expect(auto(d('1234567.891')), '1,234,567.891');
      expect(auto(d('1000')), '1,000');
      expect(auto(d('999')), '999');
    });
  });

  group('fixed decimal places', () {
    test('rounds half-up and keeps trailing zeros', () {
      const NumberFormatOptions two = NumberFormatOptions(decimalPlaces: 2);
      expect(formatNumber(d('1.005'), options: two), '1.01');
      expect(formatNumber(d('1.5'), options: two), '1.50');
      expect(formatNumber(d('2'), options: two), '2.00');
      expect(formatNumber(d('0.999'), options: two), '1.00');
      expect(formatNumber(d('1'), options: two), '1.00');
    });

    test('zero and ten places', () {
      expect(
        formatNumber(
          d('2.5'),
          options: const NumberFormatOptions(decimalPlaces: 0),
        ),
        '3',
      );
      expect(
        formatNumber(
          d('2.4'),
          options: const NumberFormatOptions(decimalPlaces: 0),
        ),
        '2',
      );
      expect(
        formatNumber(
          d('1'),
          options: const NumberFormatOptions(decimalPlaces: 10),
        ),
        '1.0000000000',
      );
    });

    test('groups with fixed places', () {
      const NumberFormatOptions two = NumberFormatOptions(decimalPlaces: 2);
      expect(formatNumber(d('1234.5'), options: two), '1,234.50');
      expect(formatNumber(d('-1234.5'), options: two), '−1,234.50');
      expect(formatNumberForCopy(d('-1234.5'), options: two), '-1,234.50');
    });
  });

  group('separators', () {
    test('grouping can be switched off', () {
      const NumberFormatOptions off = NumberFormatOptions(useGrouping: false);
      expect(formatNumber(d('1234567.891'), options: off), '1234567.891');
    });

    test('locale decimal and group marks are used', () {
      const NumberFormatOptions de = NumberFormatOptions(
        decimalSeparator: ',',
        groupSeparator: '.',
      );
      expect(formatNumber(d('1234567.891'), options: de), '1.234.567,891');
    });

    test('options can be read from intl for a locale', () {
      final NumberFormatOptions us = numberFormatOptionsFor('en_US');
      expect(us.decimalSeparator, '.');
      expect(us.groupSeparator, ',');
      expect(formatNumber(d('1234567.891'), options: us), '1,234,567.891');

      final NumberFormatOptions de = numberFormatOptionsFor('de_DE');
      expect(de.decimalSeparator, ',');
      expect(de.groupSeparator, '.');
      expect(formatNumber(d('1234567.891'), options: de), '1.234.567,891');
    });
  });

  group('scientific notation', () {
    test('thresholds are 1e15 and 1e-9', () {
      expect(auto(d('1e14')), '100,000,000,000,000');
      expect(auto(d('1e15')), '1E+15');
      expect(auto(d('1e-9')), '0.000000001');
      expect(auto(d('1e-10')), '1E-10');
      expect(auto(Decimal.zero), '0');
    });

    test('mantissa has at most 10 digits and no trailing zeros', () {
      expect(auto(d('1.234567890123e18')), '1.23456789E+18');
      expect(auto(d('1.234567890123e-12')), '1.23456789E-12');
      expect(auto(d('2.5e-11')), '2.5E-11');
    });

    test('fixed places keep their trailing zeros in the mantissa', () {
      const NumberFormatOptions two = NumberFormatOptions(decimalPlaces: 2);
      expect(formatNumber(d('1e18'), options: two), '1.00E+18');
    });

    test('negative sign follows the display/copy rule', () {
      expect(auto(d('-1.5e18')), '−1.5E+18');
      expect(formatNumberForCopy(d('-1.5e18')), '-1.5E+18');
      expect(formatNumberForCopy(d('-0.5')), '-0.5');
    });
  });

  group('typed numbers in the expression line', () {
    test('keeps every typed digit and only groups', () {
      expect(formatTypedNumber('1234567.891'), '1,234,567.891');
      expect(formatTypedNumber('12.50'), '12.50');
      expect(formatTypedNumber('0.5'), '0.5');
      expect(formatTypedNumber('12.'), '12.');
      expect(formatTypedNumber('1234'), '1,234');
    });

    test('honours grouping and locale marks', () {
      expect(
        formatTypedNumber(
          '1234567.891',
          options: const NumberFormatOptions(useGrouping: false),
        ),
        '1234567.891',
      );
      expect(
        formatTypedNumber(
          '1234567.891',
          options: const NumberFormatOptions(
            decimalSeparator: ',',
            groupSeparator: '.',
          ),
        ),
        '1.234.567,891',
      );
    });
  });
}
