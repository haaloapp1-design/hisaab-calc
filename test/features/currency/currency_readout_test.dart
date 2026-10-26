import 'package:calculator/core/currency/currency_config.dart';
import 'package:calculator/core/currency/rates.dart';
import 'package:calculator/core/engine/formatter.dart';
import 'package:calculator/features/currency/currency_readout.dart';
import 'package:calculator/features/currency/currency_state.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime fetchedAt = DateTime.utc(2026, 10, 26, 12);
  final Rates rates = Rates(
    base: 'USD',
    rates: <String, Decimal>{
      'USD': Decimal.one,
      'PKR': Decimal.parse('278.5'),
      'EUR': Decimal.parse('0.92'),
    },
    fetchedAt: fetchedAt,
  );

  CurrencyState state({
    Rates? table,
    CurrencyStatus status = CurrencyStatus.live,
    bool refreshFailed = false,
    CurrencyConfig? config,
  }) => CurrencyState(
    config: config ?? CurrencyConfig.defaults,
    rates: table,
    status: status,
    refreshFailed: refreshFailed,
  );

  CurrencyReadout readout(CurrencyState value) =>
      CurrencyReadout(state: value, options: const NumberFormatOptions());

  group('top area', () {
    test('shows the base, its name and the grouped amount', () {
      final CurrencyReadout r = readout(
        state(table: rates, config: CurrencyConfig.defaults),
      );
      expect(r.base, 'PKR');
      expect(r.baseName, 'Pakistani rupee');
      expect(r.amountText, '10,000');
    });

    test('a swapped base keeps its name and amount', () {
      final CurrencyReadout r = readout(
        state(table: rates, config: CurrencyConfig.defaults.withBase('USD')),
      );
      expect(r.base, 'USD');
      expect(r.baseName, 'US dollar');
      expect(r.amountText, '10,000');
    });
  });

  group('status line', () {
    test('live rates', () {
      final CurrencyReadout r = readout(state(table: rates));
      expect(r.statusText, 'Live rates');
      expect(r.isLive, isTrue);
    });

    test('cached rates show the fetch date', () {
      final CurrencyReadout r = readout(
        state(table: rates, status: CurrencyStatus.cached),
      );
      expect(r.statusText, 'Rates from 26 Oct 2026');
      expect(r.isLive, isFalse);
    });

    test('no rates yet', () {
      final CurrencyReadout r = readout(state(status: CurrencyStatus.none));
      expect(r.statusText, 'No rates yet');
      expect(r.isLive, isFalse);
    });

    test('a failed refresh keeps the date and says offline', () {
      final CurrencyReadout r = readout(
        state(table: rates, status: CurrencyStatus.cached, refreshFailed: true),
      );
      expect(r.statusText, 'Offline · Rates from 26 Oct 2026');
      expect(r.isLive, isFalse);
    });

    test('a failed first download says offline with no rates', () {
      final CurrencyReadout r = readout(
        state(status: CurrencyStatus.none, refreshFailed: true),
      );
      expect(r.statusText, 'Offline · No rates yet');
    });
  });

  group('rows', () {
    test('converts every target and shows the rate line', () {
      final CurrencyReadout r = readout(state(table: rates));
      expect(
        r.rows.map((CurrencyRowReadout row) => row.currency.code),
        <String>['USD', 'EUR', 'GBP', 'AED', 'SAR'],
      );

      final CurrencyRowReadout usd = r.rows.first;
      expect(usd.value, '35.91');
      expect(usd.rate, '1 USD = 278.5 PKR');

      final CurrencyRowReadout eur = r.rows[1];
      expect(eur.value, '33.03');
      expect(eur.rate, '1 EUR = 302.7 PKR');
    });

    test('a target the API omitted reads as missing', () {
      final CurrencyReadout r = readout(state(table: rates));
      final CurrencyRowReadout gbp = r.rows[2];
      expect(gbp.value, '—');
      expect(gbp.rate, 'No rate yet');
    });

    test('without rates every row is a dash', () {
      final CurrencyReadout r = readout(state(status: CurrencyStatus.none));
      for (final CurrencyRowReadout row in r.rows) {
        expect(row.value, '—');
        expect(row.rate, 'No rate yet');
      }
    });

    test('uses the user order from the config', () {
      final CurrencyConfig config = CurrencyConfig.defaults
          .removeCurrency('USD')
          .addCurrency('JPY')
          .moveCurrency(3, -3);
      final CurrencyReadout r = readout(state(table: rates, config: config));
      expect(r.rows.first.currency.code, 'SAR');
      expect(r.rows.last.currency.code, 'JPY');
    });
  });
}
