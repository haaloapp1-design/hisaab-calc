import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/kv_store.dart';
import 'rates.dart';

/// What the currency screen shows after a [CurrencyRepository] call (§13).
///
/// [rates] is the newest usable table (fresh download or old cache), [status]
/// says how fresh it is and [refreshFailed] tells the UI to keep showing the
/// cached values with an offline note instead of an error screen.
final class CurrencySnapshot {
  const CurrencySnapshot({
    required this.rates,
    required this.status,
    this.refreshFailed = false,
  });

  /// The rate table, or null when nothing has ever been downloaded.
  final Rates? rates;

  /// `live`, `cached` or `none` under the 6 h policy.
  final CurrencyStatus status;

  /// True when the last refresh failed but [rates] may still be usable.
  final bool refreshFailed;

  /// True when there is no table to convert with.
  bool get isEmpty => rates == null || rates!.isEmpty;

  @override
  String toString() =>
      'CurrencySnapshot($status, failed: $refreshFailed, ${rates ?? 'no rates'})';
}

/// Fetches currency rates and keeps the last good response in [KvStore]
/// (BUSINESS_LOGIC §13, ARCHITECTURE `currency_repository.dart`).
///
/// The HTTP client and clock are injected so tests never touch the network or
/// the real time. A failed download never throws: it returns the cached table
/// with [CurrencySnapshot.refreshFailed] set, so the screen can stay usable
/// offline.
final class CurrencyRepository {
  CurrencyRepository({
    required this.store,
    required this.client,
    DateTime Function()? clock,
    this.apiUrl = defaultApiUrl,
    this.maxAge = defaultMaxAge,
    this.timeout = defaultTimeout,
  }) : _clock = clock ?? DateTime.now;

  /// The KvStore key holding the last response and its fetch time.
  static const String cacheKey = 'currency_cache_v1';

  /// BUSINESS_LOGIC §13: the URL lives in one constant so it can be swapped.
  static const String defaultApiUrl = 'https://open.er-api.com/v6/latest/USD';

  /// §13: auto-refresh at most once every six hours.
  static const Duration defaultMaxAge = Duration(hours: 6);

  /// A slow network should not leave the screen loading forever.
  static const Duration defaultTimeout = Duration(seconds: 10);

  final KvStore store;
  final http.Client client;
  final DateTime Function() _clock;

  /// The rates endpoint; override to point at another provider.
  final String apiUrl;

  /// How long a download counts as live.
  final Duration maxAge;

  /// How long a request may take before it is treated as a network error.
  final Duration timeout;

  /// Reads the cache without touching the network.
  Future<CurrencySnapshot> load() async => _snapshot(await _readCache());

  /// Downloads fresh rates and replaces the cache on success.
  ///
  /// Any network, HTTP or JSON problem keeps the old cache and returns it with
  /// [CurrencySnapshot.refreshFailed] set; this method never throws.
  Future<CurrencySnapshot> refresh() async {
    final Rates? cached = await _readCache();
    final DateTime now = _clock().toUtc();
    try {
      final http.Response response = await client
          .get(Uri.parse(apiUrl))
          .timeout(timeout);
      if (response.statusCode != 200) {
        return _snapshot(cached, now: now, refreshFailed: true);
      }
      final Rates? fetched = Rates.fromApiJson(
        jsonDecode(response.body),
        fetchedAt: now,
      );
      if (fetched == null) {
        return _snapshot(cached, now: now, refreshFailed: true);
      }
      await store.setString(cacheKey, fetched.encode());
      return _snapshot(fetched, now: now);
    } on Exception {
      return _snapshot(cached, now: now, refreshFailed: true);
    }
  }

  /// True when the screen should try a refresh on open (§13).
  bool needsRefresh(Rates? rates) =>
      currencyStatus(rates, now: _clock(), maxAge: maxAge) !=
      CurrencyStatus.live;

  /// SPEC §3 "Clear all saved data": forget the cached rates.
  Future<void> clear() => store.remove(cacheKey);

  /// Releases the HTTP client; the provider calls this on dispose.
  void close() => client.close();

  Future<Rates?> _readCache() async =>
      Rates.decode(await store.getString(cacheKey));

  CurrencySnapshot _snapshot(
    Rates? rates, {
    DateTime? now,
    bool refreshFailed = false,
  }) => CurrencySnapshot(
    rates: rates,
    status: currencyStatus(rates, now: now ?? _clock(), maxAge: maxAge),
    refreshFailed: refreshFailed,
  );
}
