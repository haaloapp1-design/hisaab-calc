import '../../core/currency/currency_config.dart';
import '../../core/currency/currency_repository.dart';
import '../../core/currency/rates.dart';

/// Everything the currency screen knows (ARCHITECTURE "State").
///
/// [config] is the user's base, list and amount; [rates] is the newest usable
/// table and [status] says how fresh it is. [refreshFailed] keeps the cached
/// values on screen with an offline note instead of an error page.
final class CurrencyState {
  const CurrencyState({
    required this.config,
    required this.status,
    this.rates,
    this.refreshFailed = false,
    this.refreshing = false,
  });

  /// The state before anything has been loaded or downloaded.
  factory CurrencyState.initial() => CurrencyState(
    config: CurrencyConfig.defaults,
    status: CurrencyStatus.none,
  );

  final CurrencyConfig config;
  final Rates? rates;
  final CurrencyStatus status;
  final bool refreshFailed;
  final bool refreshing;

  bool get hasRates => rates != null && !rates!.isEmpty;

  /// A copy after a repository load or refresh.
  CurrencyState withSnapshot(CurrencySnapshot snapshot) => CurrencyState(
    config: config,
    rates: snapshot.rates,
    status: snapshot.status,
    refreshFailed: snapshot.refreshFailed,
  );

  /// A copy with new user choices.
  CurrencyState withConfig(CurrencyConfig config) => CurrencyState(
    config: config,
    rates: rates,
    status: status,
    refreshFailed: refreshFailed,
    refreshing: refreshing,
  );

  /// A copy while a refresh is running (or when it ends).
  CurrencyState withRefreshing(bool refreshing) => CurrencyState(
    config: config,
    rates: rates,
    status: status,
    refreshFailed: refreshFailed,
    refreshing: refreshing,
  );

  @override
  bool operator ==(Object other) =>
      other is CurrencyState &&
      other.config == config &&
      other.rates == rates &&
      other.status == status &&
      other.refreshFailed == refreshFailed &&
      other.refreshing == refreshing;

  @override
  int get hashCode =>
      Object.hash(config, rates, status, refreshFailed, refreshing);

  @override
  String toString() =>
      'CurrencyState(${config.base}, $status, failed: $refreshFailed, '
      'refreshing: $refreshing)';
}
