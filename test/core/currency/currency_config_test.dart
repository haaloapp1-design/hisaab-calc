import 'dart:convert';

import 'package:calculator/core/currency/currency_amount.dart';
import 'package:calculator/core/currency/currency_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('defaults', () {
    test('base PKR, the five targets and 10,000', () {
      final CurrencyConfig config = CurrencyConfig.defaults;
      expect(config.base, 'PKR');
      expect(config.targets, <String>['USD', 'EUR', 'GBP', 'AED', 'SAR']);
      expect(config.amount, const CurrencyAmount('10000'));
      expect(config.isEmpty, isFalse);
    });

    test('filters invalid, duplicate and base codes', () {
      final CurrencyConfig config = CurrencyConfig(
        base: 'usd',
        targets: <String>['USD', 'eur', 'EUR', 'XYZ', 'gbp'],
      );
      expect(config.base, 'USD');
      expect(config.targets, <String>['EUR', 'GBP']);
    });
  });

  group('changes', () {
    test('withBase swaps the old base into the target list', () {
      final CurrencyConfig config = CurrencyConfig.defaults.withBase('USD');
      expect(config.base, 'USD');
      expect(config.targets, <String>['PKR', 'EUR', 'GBP', 'AED', 'SAR']);
    });

    test('withBase keeps the amount and ignores an invalid code', () {
      final CurrencyConfig start = CurrencyConfig.defaults.withAmount(
        const CurrencyAmount('42'),
      );
      expect(start.withBase('XYZ'), start);
      expect(start.withBase('PKR'), start);
      expect(start.withBase('EUR').amount, const CurrencyAmount('42'));
    });

    test('add, remove and replace keep the order', () {
      CurrencyConfig config = CurrencyConfig.defaults.addCurrency('JPY');
      expect(config.targets.last, 'JPY');
      expect(config.addCurrency('JPY'), config);
      expect(config.addCurrency('PKR'), config);
      expect(config.addCurrency('XYZ'), config);

      config = config.removeCurrency('EUR');
      expect(config.targets, <String>['USD', 'GBP', 'AED', 'SAR', 'JPY']);
      expect(config.removeCurrency('EUR'), config);

      config = config.replaceCurrency('GBP', 'CAD');
      expect(config.targets, <String>['USD', 'CAD', 'AED', 'SAR', 'JPY']);
      expect(config.replaceCurrency('GBP', 'CAD'), config);
      expect(config.replaceCurrency('CAD', 'USD'), config);
      expect(config.replaceCurrency('CAD', 'PKR'), config);
    });

    test('moveCurrency moves one row and clamps at the ends', () {
      final CurrencyConfig config = CurrencyConfig.defaults;
      expect(config.moveCurrency(1, -1).targets, <String>[
        'EUR',
        'USD',
        'GBP',
        'AED',
        'SAR',
      ]);
      expect(config.moveCurrency(1, 1).targets, <String>[
        'USD',
        'GBP',
        'EUR',
        'AED',
        'SAR',
      ]);
      expect(config.moveCurrency(0, -1), config);
      expect(config.moveCurrency(4, 1), config);
      expect(config.moveCurrency(9, 1), config);
    });
  });

  group('storage', () {
    test('encode/decode round-trips the whole config', () {
      final CurrencyConfig config = CurrencyConfig.defaults
          .withBase('USD')
          .addCurrency('JPY')
          .withAmount(const CurrencyAmount('1234.50'));
      expect(CurrencyConfig.decode(config.encode()), config);
    });

    test('missing or corrupt data reads as defaults', () {
      expect(CurrencyConfig.decode(null), CurrencyConfig.defaults);
      expect(CurrencyConfig.decode(''), CurrencyConfig.defaults);
      expect(CurrencyConfig.decode('not json'), CurrencyConfig.defaults);
      expect(CurrencyConfig.decode('[]'), CurrencyConfig.defaults);
    });

    test('an invalid base falls back while keeping valid targets', () {
      final CurrencyConfig config = CurrencyConfig.decode(
        jsonEncode(<String, Object?>{
          'base': 'XYZ',
          'targets': <String>['usd', 'XYZ', 'USD', 'eur'],
          'amount': '99',
        }),
      );
      expect(config.base, 'PKR');
      expect(config.targets, <String>['USD', 'EUR']);
      expect(config.amount, const CurrencyAmount('99'));
    });

    test('a stored empty list stays empty', () {
      final CurrencyConfig config = CurrencyConfig.decode(
        jsonEncode(<String, Object?>{
          'base': 'PKR',
          'targets': <String>[],
          'amount': '5',
        }),
      );
      expect(config.targets, isEmpty);
      expect(config.isEmpty, isTrue);
    });

    test('a missing target list falls back to the defaults', () {
      final CurrencyConfig config = CurrencyConfig.decode(
        jsonEncode(<String, Object?>{'base': 'USD', 'amount': '5'}),
      );
      expect(config.targets, <String>['EUR', 'GBP', 'AED', 'SAR']);
    });

    test('a missing amount falls back to 10,000', () {
      final CurrencyConfig config = CurrencyConfig.decode(
        jsonEncode(<String, Object?>{
          'base': 'PKR',
          'targets': <String>['USD'],
        }),
      );
      expect(config.amount, CurrencyConfig.defaultAmount);
    });
  });
}
