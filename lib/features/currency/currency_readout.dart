import 'package:decimal/decimal.dart';

import '../../core/currency/currency_catalog.dart';
import '../../core/currency/currency_format.dart';
import '../../core/currency/rates.dart';
import '../../core/engine/formatter.dart';
import 'currency_state.dart';

/// One target currency row on screen 08.
final class CurrencyRowReadout {
  const CurrencyRowReadout({
    required this.currency,
    required this.value,
    required this.rate,
  });

  final Currency currency;

  /// The amount converted into [currency], or `—` without a rate.
  final String value;

  /// `1 USD = 278.5 PKR`, or `No rate yet`.
  final String rate;
}

/// Everything screen 08 renders for the current [CurrencyState].
///
/// The page builds one readout per frame, so the rows, the amount and the
/// status line all come from the same rate table and the same formatting
/// options instead of the widgets doing maths.
final class CurrencyReadout {
  const CurrencyReadout({required this.state, required this.options});

  final CurrencyState state;
  final NumberFormatOptions options;

  String get base => state.config.base;

  String get baseName => CurrencyCatalog.nameOf(base);

  /// The typed amount, grouped with the Settings separators.
  String get amountText => state.config.amount.display(options: options);

  /// True when the dot should be the live colour rather than the warning one.
  bool get isLive =>
      state.status == CurrencyStatus.live && !state.refreshFailed;

  /// The line under the amount (SPEC §5).
  String get statusText {
    final DateTime? fetchedAt = state.rates?.fetchedAt;
    if (state.refreshFailed) {
      return fetchedAt == null
          ? 'Offline · No rates yet'
          : 'Offline · Rates from ${formatRateDate(fetchedAt)}';
    }
    return switch (state.status) {
      CurrencyStatus.live => 'Live rates',
      CurrencyStatus.cached =>
        fetchedAt == null
            ? 'No rates yet'
            : 'Rates from ${formatRateDate(fetchedAt)}',
      CurrencyStatus.none => 'No rates yet',
    };
  }

  /// One row per target currency, in the user's order.
  List<CurrencyRowReadout> get rows => <CurrencyRowReadout>[
    for (final String code in state.config.targets)
      _row(CurrencyCatalog.byCode(code) ?? Currency(code, code)),
  ];

  CurrencyRowReadout _row(Currency currency) {
    final Rates? rates = state.rates;
    if (rates == null) {
      return CurrencyRowReadout(
        currency: currency,
        value: '—',
        rate: 'No rate yet',
      );
    }
    final Decimal? value = rates.convert(
      state.config.amount.value,
      from: base,
      to: currency.code,
    );
    final Decimal? rate = rates.crossRate(currency.code, base);
    return CurrencyRowReadout(
      currency: currency,
      value: value == null ? '—' : formatCurrencyValue(value, options: options),
      rate: rate == null
          ? 'No rate yet'
          : formatCurrencyRateLine(
              from: currency.code,
              to: base,
              rate: rate,
              options: options,
            ),
    );
  }
}
