import 'dart:convert';

import 'package:decimal/decimal.dart';

/// How fresh the rate cache is (BUSINESS_LOGIC §13).
enum CurrencyStatus {
  /// Fetched less than the 6 h policy window ago.
  live,

  /// Older than the policy window; the UI shows the fetch date.
  cached,

  /// No rates have ever been downloaded.
  none,
}

/// The rates of one API response, relative to [base] (BUSINESS_LOGIC §13).
///
/// The API returns every rate against one base (USD), so a conversion between
/// two other currencies goes through that base: `amount × rate[to] / rate[from]`.
final class Rates {
  Rates({
    required this.base,
    required Map<String, Decimal> rates,
    required DateTime fetchedAt,
  }) : rates = Map<String, Decimal>.unmodifiable(rates),
       fetchedAt = fetchedAt.toUtc();

  /// The currency the API quoted every rate against, e.g. `USD`.
  final String base;

  /// One rate per currency code, relative to [base].
  final Map<String, Decimal> rates;

  /// When the response was downloaded, in UTC.
  final DateTime fetchedAt;

  /// True when no usable rate was parsed.
  bool get isEmpty => rates.isEmpty;

  /// The rate of [code] against [base], or null when the API omitted it.
  ///
  /// The base itself is always 1, even when the response leaves it out.
  Decimal? rateFor(String code) {
    final String upper = code.toUpperCase();
    return rates[upper] ?? (upper == base.toUpperCase() ? Decimal.one : null);
  }

  /// How many [to] one [from] buys, or null when either code is missing.
  ///
  /// The same code is 1 even when the API omitted it.
  Decimal? crossRate(String from, String to) {
    final String source = from.toUpperCase();
    final String target = to.toUpperCase();
    if (source == target) {
      return Decimal.one;
    }
    final Decimal? sourceRate = rateFor(source);
    final Decimal? targetRate = rateFor(target);
    if (sourceRate == null ||
        targetRate == null ||
        sourceRate == Decimal.zero) {
      return null;
    }
    return (targetRate / sourceRate).toDecimal(scaleOnInfinitePrecision: 32);
  }

  /// [amount] in [from] converted to [to], or null when a code is missing.
  Decimal? convert(Decimal amount, {required String from, required String to}) {
    final Decimal? rate = crossRate(from, to);
    return rate == null ? null : amount * rate;
  }

  /// The persisted form: ids as text so the decimals stay exact.
  String encode() => jsonEncode(<String, Object?>{
    'base': base,
    'fetchedAt': fetchedAt.toIso8601String(),
    'rates': <String, String>{
      for (final MapEntry<String, Decimal> entry in rates.entries)
        entry.key: entry.value.toString(),
    },
  });

  /// Reads a stored cache; missing, empty or corrupt data reads as null.
  static Rates? decode(String? source) {
    if (source == null || source.isEmpty) {
      return null;
    }
    try {
      final Object? json = jsonDecode(source);
      if (json is! Map<String, Object?>) {
        return null;
      }
      final Object? base = json['base'];
      final Object? fetchedAt = json['fetchedAt'];
      final Object? rows = json['rates'];
      if (base is! String || base.isEmpty || rows is! Map<String, Object?>) {
        return null;
      }
      final DateTime? moment = fetchedAt is String
          ? DateTime.tryParse(fetchedAt)
          : null;
      if (moment == null) {
        return null;
      }
      final Map<String, Decimal> rates = _readRates(rows);
      if (rates.isEmpty) {
        return null;
      }
      return Rates(base: base, rates: rates, fetchedAt: moment);
    } on FormatException {
      return null;
    }
  }

  /// Reads the useful part of the API response (BUSINESS_LOGIC §13).
  ///
  /// A `result` other than `success`, a missing base or an empty rate table
  /// makes the response unusable; unknown rate values are skipped.
  static Rates? fromApiJson(Object? json, {required DateTime fetchedAt}) {
    if (json is! Map<String, Object?>) {
      return null;
    }
    final Object? result = json['result'];
    if (result is String && result != 'success') {
      return null;
    }
    final Object? base = json['base_code'];
    final Object? rows = json['rates'];
    if (base is! String || base.isEmpty || rows is! Map<String, Object?>) {
      return null;
    }
    final Map<String, Decimal> rates = _readRates(rows);
    if (rates.isEmpty) {
      return null;
    }
    return Rates(base: base, rates: rates, fetchedAt: fetchedAt);
  }

  static Map<String, Decimal> _readRates(Map<String, Object?> rows) {
    final Map<String, Decimal> rates = <String, Decimal>{};
    for (final MapEntry<String, Object?> entry in rows.entries) {
      final String code = entry.key.toUpperCase();
      if (code.isEmpty) {
        continue;
      }
      final Decimal? value = _decimal(entry.value);
      if (value == null || value <= Decimal.zero) {
        continue;
      }
      rates[code] = value;
    }
    return rates;
  }

  static Decimal? _decimal(Object? value) {
    if (value is! num && value is! String) {
      return null;
    }
    try {
      return Decimal.parse(value.toString());
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is! Rates ||
        other.base != base ||
        other.fetchedAt != fetchedAt ||
        other.rates.length != rates.length) {
      return false;
    }
    for (final MapEntry<String, Decimal> entry in rates.entries) {
      if (other.rates[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    base,
    fetchedAt,
    Object.hashAllUnordered(<String>[
      for (final MapEntry<String, Decimal> entry in rates.entries)
        '${entry.key}:${entry.value}',
    ]),
  );

  @override
  String toString() =>
      'Rates($base, ${rates.length} rates, '
      '${fetchedAt.toIso8601String()})';
}

/// The status of [rates] at [now] under the [maxAge] policy (§13).
///
/// A null/empty rate set is [CurrencyStatus.none]; anything younger than
/// [maxAge] is [CurrencyStatus.live], otherwise [CurrencyStatus.cached].
CurrencyStatus currencyStatus(
  Rates? rates, {
  required DateTime now,
  required Duration maxAge,
}) {
  if (rates == null || rates.isEmpty) {
    return CurrencyStatus.none;
  }
  return now.toUtc().difference(rates.fetchedAt) < maxAge
      ? CurrencyStatus.live
      : CurrencyStatus.cached;
}
