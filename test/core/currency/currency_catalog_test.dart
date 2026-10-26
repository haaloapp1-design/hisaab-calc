import 'package:calculator/core/currency/currency_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('defaults', () {
    test('opens on PKR with the five target currencies of SPEC §5', () {
      expect(CurrencyCatalog.defaultBase, 'PKR');
      expect(CurrencyCatalog.defaultTargets, <String>[
        'USD',
        'EUR',
        'GBP',
        'AED',
        'SAR',
      ]);
    });

    test('every catalog code is unique, uppercase and has a name', () {
      final Set<String> codes = <String>{};
      for (final Currency currency in CurrencyCatalog.all) {
        expect(currency.code, currency.code.toUpperCase());
        expect(currency.name, isNotEmpty);
        expect(codes.add(currency.code), isTrue, reason: currency.code);
      }
    });
  });

  group('lookup', () {
    test('byCode is case-insensitive and null for unknown codes', () {
      expect(CurrencyCatalog.byCode('pkr')?.name, 'Pakistani rupee');
      expect(CurrencyCatalog.byCode('USD')?.name, 'US dollar');
      expect(CurrencyCatalog.byCode('XYZ'), isNull);
    });

    test('nameOf falls back to the code and contains validates', () {
      expect(CurrencyCatalog.nameOf('eur'), 'Euro');
      expect(CurrencyCatalog.nameOf('XYZ'), 'XYZ');
      expect(CurrencyCatalog.contains('gbp'), isTrue);
      expect(CurrencyCatalog.contains('XYZ'), isFalse);
    });
  });

  group('search', () {
    test('an empty query lists the whole catalog', () {
      expect(CurrencyCatalog.search(''), CurrencyCatalog.all);
      expect(CurrencyCatalog.search('   '), CurrencyCatalog.all);
    });

    test('matches codes and names, ignoring case', () {
      expect(CurrencyCatalog.search('jpy').single.name, 'Japanese yen');
      expect(CurrencyCatalog.search('PAKISTANI').single.code, 'PKR');
      expect(
        CurrencyCatalog.search('dollar').map((Currency c) => c.code),
        containsAll(<String>['AUD', 'CAD', 'HKD', 'NZD', 'SGD', 'TWD', 'USD']),
      );
    });

    test('returns no matches for an unknown query', () {
      expect(CurrencyCatalog.search('zzz'), isEmpty);
    });
  });
}
