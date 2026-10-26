import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/currency/currency_amount.dart';
import '../../core/currency/currency_config.dart';
import '../../core/currency/currency_repository.dart';
import '../../core/storage/kv_store.dart';
import '../../core/storage/kv_store_provider.dart';
import 'currency_repository_provider.dart';
import 'currency_state.dart';

/// Owns the currency screen's config and rate cache (ARCHITECTURE "State").
///
/// It restores `currency_v1`, reads the cached rates and downloads a fresh
/// table when the 6 h policy says the cache is stale. Every user change is
/// persisted through [KvStore]; the rate cache itself belongs to
/// [CurrencyRepository].
class CurrencyController extends AsyncNotifier<CurrencyState> {
  /// The KvStore key holding the base, the target list and the amount.
  static const String key = 'currency_v1';

  Future<void> _lastPersist = Future<void>.value();

  @override
  Future<CurrencyState> build() async {
    final KvStore store = ref.read(kvStoreProvider);
    final CurrencyRepository repository = ref.read(currencyRepositoryProvider);
    final CurrencyConfig config = CurrencyConfig.decode(
      await store.getString(key),
    );
    final CurrencySnapshot snapshot = await repository.load();
    CurrencyState state = CurrencyState(
      config: config,
      rates: snapshot.rates,
      status: snapshot.status,
      refreshFailed: snapshot.refreshFailed,
    );
    if (repository.needsRefresh(snapshot.rates)) {
      state = state.withSnapshot(await repository.refresh());
    }
    return state;
  }

  /// Completes when the last saved config write has finished. Test hook.
  Future<void> get persistDone => _lastPersist;

  /// Makes [code] the base and puts the old base first in the target list.
  void setBase(String code) {
    final CurrencyState? current = state.value;
    if (current == null) {
      return;
    }
    _commit(current.config.withBase(code));
  }

  /// Stores what the user typed in the amount field.
  void setAmount(CurrencyAmount amount) {
    final CurrencyState? current = state.value;
    if (current == null) {
      return;
    }
    _commit(current.config.withAmount(amount));
  }

  /// Adds [code] at the end of the list. Returns true when it was added.
  bool addCurrency(String code) {
    final CurrencyState? current = state.value;
    if (current == null) {
      return false;
    }
    final CurrencyConfig next = current.config.addCurrency(code);
    _commit(next);
    return next != current.config;
  }

  /// Removes [code] from the list. Returns true when it was removed.
  bool removeCurrency(String code) {
    final CurrencyState? current = state.value;
    if (current == null) {
      return false;
    }
    final CurrencyConfig next = current.config.removeCurrency(code);
    _commit(next);
    return next != current.config;
  }

  /// Replaces one target in place. Returns true when it changed.
  bool replaceCurrency(String oldCode, String newCode) {
    final CurrencyState? current = state.value;
    if (current == null) {
      return false;
    }
    final CurrencyConfig next = current.config.replaceCurrency(
      oldCode,
      newCode,
    );
    _commit(next);
    return next != current.config;
  }

  /// Moves a target by [delta] rows. Returns true when it moved.
  bool moveCurrency(int index, int delta) {
    final CurrencyState? current = state.value;
    if (current == null) {
      return false;
    }
    final CurrencyConfig next = current.config.moveCurrency(index, delta);
    _commit(next);
    return next != current.config;
  }

  /// Downloads fresh rates. Returns false when the refresh failed.
  ///
  /// A failure never throws: the previous table stays on screen with
  /// [CurrencyState.refreshFailed] set (BUSINESS_LOGIC §13).
  Future<bool> refresh() async {
    final CurrencyState? current = state.value;
    if (current == null || current.refreshing) {
      return false;
    }
    state = AsyncData(current.withRefreshing(true));
    final CurrencySnapshot snapshot = await ref
        .read(currencyRepositoryProvider)
        .refresh();
    if (!ref.mounted) {
      return false;
    }
    final CurrencyState latest = state.value ?? current;
    state = AsyncData(latest.withSnapshot(snapshot));
    return !snapshot.refreshFailed;
  }

  /// Refreshes only when the cache is stale or missing (SPEC §5: at most once
  /// every 6 hours). Returns true when a refresh ran.
  Future<bool> refreshIfStale() async {
    final CurrencyState? current = state.value;
    if (current == null || current.refreshing) {
      return false;
    }
    if (!ref.read(currencyRepositoryProvider).needsRefresh(current.rates)) {
      return false;
    }
    await refresh();
    return true;
  }

  void _commit(CurrencyConfig config) {
    final CurrencyState? current = state.value;
    if (current == null || current.config == config) {
      return;
    }
    state = AsyncData(current.withConfig(config));
    _lastPersist = _lastPersist.then(
      (_) => ref.read(kvStoreProvider).setString(key, config.encode()),
    );
  }
}

/// ARCHITECTURE "State": rates, status, base, target list and amount.
final AsyncNotifierProvider<CurrencyController, CurrencyState>
currencyProvider = AsyncNotifierProvider<CurrencyController, CurrencyState>(
  CurrencyController.new,
  name: 'currency',
);
