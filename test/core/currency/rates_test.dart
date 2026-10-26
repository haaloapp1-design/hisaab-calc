import 'package:calculator/core/currency/rates.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime fetched = DateTime.utc(2026, 10, 26, 8, 30);

  Rates rates({
    Map<String, Decimal>? values,
    DateTime? fetchedAt,
    String base = 'USD',
  }) => Rates(
    base: base,
    rates:
        values ??
        <String, Decimal>{
          'USD': Decimal.one,
          'PKR': Decimal.fromInt(250),
          'EUR': Decimal.parse('0.5'),
        },
    fetchedAt: fetchedAt ?? fetched,
  );

  group('cross rates', () {
    test('converts through the API base', () {
      final Rates table = rates();

      expect(table.crossRate('USD', 'PKR'), Decimal.fromInt(250));
      expect(table.crossRate('PKR', 'EUR'), Decimal.parse('0.002'));
      expect(table.crossRate('EUR', 'PKR'), Decimal.fromInt(500));
      expect(table.crossRate('USD', 'USD'), Decimal.one);
      expect(table.crossRate('pkr', 'usd'), Decimal.parse('0.004'));
    });

    test('multiplies an amount by the cross rate', () {
      final Rates table = rates();

      expect(
        table.convert(Decimal.fromInt(10), from: 'PKR', to: 'EUR'),
        Decimal.parse('0.02'),
      );
      expect(
        table.convert(Decimal.parse('12.5'), from: 'USD', to: 'PKR'),
        Decimal.fromInt(3125),
      );
    });

    test('the same code is one even when the API omitted it', () {
      expect(rates().crossRate('GBP', 'GBP'), Decimal.one);
    });

    test('the base is implicitly one when the table omits it', () {
      final Rates table = rates(
        values: <String, Decimal>{'PKR': Decimal.fromInt(250)},
      );

      expect(table.rateFor('USD'), Decimal.one);
      expect(table.crossRate('USD', 'PKR'), Decimal.fromInt(250));
      expect(table.crossRate('PKR', 'USD'), Decimal.parse('0.004'));
    });

    test('returns null for a missing code or a zero source rate', () {
      final Rates table = rates(
        values: <String, Decimal>{'USD': Decimal.one, 'ZERO': Decimal.zero},
      );

      expect(table.crossRate('USD', 'PKR'), isNull);
      expect(table.crossRate('PKR', 'USD'), isNull);
      expect(table.crossRate('ZERO', 'USD'), isNull);
      expect(table.convert(Decimal.one, from: 'USD', to: 'PKR'), isNull);
    });

    test('keeps 32 decimal places for an endless division', () {
      final Decimal third = rates(
        values: <String, Decimal>{'USD': Decimal.one, 'X': Decimal.fromInt(3)},
      ).crossRate('X', 'USD')!;

      expect(third.toString(), '0.33333333333333333333333333333333');
    });

    test('rateFor is case-insensitive', () {
      expect(rates().rateFor('pkr'), Decimal.fromInt(250));
      expect(rates().rateFor('gbp'), isNull);
    });
  });

  group('cache', () {
    test('round-trips the base, rates and UTC fetch time', () {
      final Rates table = rates();
      final Rates decoded = Rates.decode(table.encode())!;

      expect(decoded, table);
      expect(decoded.base, 'USD');
      expect(decoded.fetchedAt, fetched);
      expect(decoded.rateFor('PKR'), Decimal.fromInt(250));
      expect(decoded.rateFor('EUR'), Decimal.parse('0.5'));
    });

    test('stores rates as text so the decimals stay exact', () {
      final Rates table = rates(
        values: <String, Decimal>{
          'USD': Decimal.one,
          'PKR': Decimal.parse('278.5123456789'),
        },
      );

      final String stored = table.encode();

      expect(stored, contains('"PKR":"278.5123456789"'));
      expect(
        Rates.decode(stored)!.rateFor('PKR'),
        Decimal.parse('278.5123456789'),
      );
    });

    test('the rate map cannot be changed through the model', () {
      final Rates table = rates();

      expect(() => table.rates['GBP'] = Decimal.one, throwsUnsupportedError);
    });

    test('a non-UTC fetch time is stored as UTC', () {
      final DateTime local = DateTime(2026, 10, 26, 8, 30);
      final Rates table = rates(fetchedAt: local);

      expect(table.fetchedAt.isUtc, isTrue);
      expect(table.fetchedAt, local.toUtc());
      expect(Rates.decode(table.encode())!.fetchedAt, local.toUtc());
    });

    test('decode reads missing or corrupt data as null', () {
      for (final String? source in <String?>[
        null,
        '',
        'not json',
        '[]',
        '42',
        '{"base":"USD","fetchedAt":"2026-10-26T08:30:00Z"}',
        '{"base":"","fetchedAt":"2026-10-26T08:30:00Z","rates":{"USD":1}}',
        '{"base":"USD","fetchedAt":"nope","rates":{"USD":1}}',
        '{"base":"USD","fetchedAt":"2026-10-26T08:30:00Z","rates":{}}',
        '{"base":"USD","fetchedAt":"2026-10-26T08:30:00Z","rates":{"USD":0}}',
      ]) {
        expect(Rates.decode(source), isNull, reason: source);
      }
    });

    test('decode skips unusable rate values but keeps the good ones', () {
      final Rates? table = Rates.decode(
        '{"base":"USD","fetchedAt":"2026-10-26T08:30:00Z","rates":'
        '{"usd":1,"pkr":"278.5","bad":"nope","zero":0,"neg":-2,"nil":null}}',
      );

      expect(table, isNotNull);
      expect(table!.rateFor('USD'), Decimal.one);
      expect(table.rateFor('PKR'), Decimal.parse('278.5'));
      expect(table.rateFor('BAD'), isNull);
      expect(table.rateFor('ZERO'), isNull);
      expect(table.rateFor('NEG'), isNull);
      expect(table.rateFor('NIL'), isNull);
    });
  });

  group('API response', () {
    test('reads a successful response', () {
      final Rates? table = Rates.fromApiJson(<String, Object?>{
        'result': 'success',
        'base_code': 'USD',
        'rates': <String, Object?>{'USD': 1, 'PKR': 278.5, 'EUR': '0.92'},
      }, fetchedAt: fetched);

      expect(table, isNotNull);
      expect(table!.base, 'USD');
      expect(table.fetchedAt, fetched);
      expect(table.rateFor('USD'), Decimal.one);
      expect(table.rateFor('PKR'), Decimal.parse('278.5'));
      expect(table.rateFor('EUR'), Decimal.parse('0.92'));
    });

    test('rejects a failed result or a missing base', () {
      expect(
        Rates.fromApiJson(<String, Object?>{
          'result': 'error',
          'base_code': 'USD',
          'rates': <String, Object?>{'USD': 1},
        }, fetchedAt: fetched),
        isNull,
      );
      expect(
        Rates.fromApiJson(<String, Object?>{
          'result': 'success',
          'rates': <String, Object?>{'USD': 1},
        }, fetchedAt: fetched),
        isNull,
      );
      expect(
        Rates.fromApiJson(<String, Object?>{
          'result': 'success',
          'base_code': '',
          'rates': <String, Object?>{'USD': 1},
        }, fetchedAt: fetched),
        isNull,
      );
    });

    test('rejects a response with no usable rate', () {
      expect(
        Rates.fromApiJson(<String, Object?>{
          'result': 'success',
          'base_code': 'USD',
          'rates': <String, Object?>{},
        }, fetchedAt: fetched),
        isNull,
      );
      expect(
        Rates.fromApiJson(<String, Object?>{
          'result': 'success',
          'base_code': 'USD',
          'rates': <String, Object?>{'USD': 0, 'PKR': -1},
        }, fetchedAt: fetched),
        isNull,
      );
      expect(Rates.fromApiJson(null, fetchedAt: fetched), isNull);
      expect(Rates.fromApiJson(<Object?>[], fetchedAt: fetched), isNull);
    });

    test('uppercases codes and skips unknown values', () {
      final Rates table = Rates.fromApiJson(<String, Object?>{
        'result': 'success',
        'base_code': 'USD',
        'rates': <String, Object?>{
          'usd': 1,
          'pkr': '278.5',
          'bad': 'nope',
          'nil': null,
          'flag': true,
        },
      }, fetchedAt: fetched)!;

      expect(table.rates.keys, <String>['USD', 'PKR']);
      expect(table.rateFor('pkr'), Decimal.parse('278.5'));
    });
  });

  group('status policy', () {
    const Duration maxAge = Duration(hours: 6);

    test('no table is none', () {
      expect(
        currencyStatus(null, now: fetched, maxAge: maxAge),
        CurrencyStatus.none,
      );
      expect(
        currencyStatus(
          rates(values: <String, Decimal>{}),
          now: fetched,
          maxAge: maxAge,
        ),
        CurrencyStatus.none,
      );
    });

    test('younger than six hours is live', () {
      expect(
        currencyStatus(
          rates(fetchedAt: fetched),
          now: fetched.add(const Duration(hours: 5, minutes: 59)),
          maxAge: maxAge,
        ),
        CurrencyStatus.live,
      );
    });

    test('six hours old or older is cached', () {
      expect(
        currencyStatus(
          rates(fetchedAt: fetched),
          now: fetched.add(const Duration(hours: 6)),
          maxAge: maxAge,
        ),
        CurrencyStatus.cached,
      );
      expect(
        currencyStatus(
          rates(fetchedAt: fetched),
          now: fetched.add(const Duration(days: 1)),
          maxAge: maxAge,
        ),
        CurrencyStatus.cached,
      );
    });

    test('compares in UTC', () {
      expect(
        currencyStatus(
          rates(fetchedAt: fetched),
          now: fetched.toLocal().add(const Duration(hours: 7)),
          maxAge: maxAge,
        ),
        CurrencyStatus.cached,
      );
    });
  });

  test('equality compares base, time and every rate', () {
    final Rates table = rates();
    final Rates same = rates();
    final Rates otherTime = rates(
      fetchedAt: fetched.add(const Duration(hours: 1)),
    );
    final Rates otherRate = rates(
      values: <String, Decimal>{
        'USD': Decimal.one,
        'PKR': Decimal.fromInt(251),
      },
    );

    expect(table, same);
    expect(table.hashCode, same.hashCode);
    expect(table, isNot(otherTime));
    expect(table, isNot(otherRate));
    expect(table, isNot(rates(base: 'EUR')));
    expect(table.toString(), 'Rates(USD, 3 rates, 2026-10-26T08:30:00.000Z)');
  });
}
