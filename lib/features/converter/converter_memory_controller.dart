import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/kv_store.dart';
import '../../core/storage/kv_store_provider.dart';
import '../../core/units/converter_memory.dart';

/// Owns the converter's remembered pair and favourites and persists them
/// through [KvStore] (SPEC §4, ARCHITECTURE "State").
///
/// The first frame shows no memory while [restoreDone] loads the stored
/// object. A change made during that load wins over the stored values, the
/// same rule Settings and Memory use; `clear` removes the key after any queued
/// write so a start-up restore cannot bring cleared data back.
class ConverterMemoryController extends Notifier<ConverterMemory> {
  /// The KvStore key holding the last pair and favourites.
  static const String key = 'converter_v1';

  Future<void>? _restore;
  Future<void> _lastPersist = Future<void>.value();
  bool _restored = false;
  bool _changed = false;
  bool _cleared = false;

  @override
  ConverterMemory build() {
    _restore ??= _restoreMemory();
    return const ConverterMemory();
  }

  /// Completes when the stored memory has been loaded. Test hook.
  Future<void> get restoreDone => _restore ?? Future<void>.value();

  /// Completes when the last persisted write has finished. Test hook.
  Future<void> get persistDone => _lastPersist;

  /// Remembers [pair] as the pair the converter opens with next time.
  void remember(ConverterPair pair) {
    if (state.last != null && state.last!.samePair(pair)) {
      return;
    }
    _commit(state.withLast(pair));
  }

  /// Stars [pair] or removes the star. Returns true when it is now starred.
  bool toggleFavourite(ConverterPair pair) {
    final bool nowFavourite = !state.isFavourite(pair);
    _commit(state.toggleFavourite(pair));
    return nowFavourite;
  }

  /// SPEC §3 "Clear all saved data": forget everything and delete the key.
  Future<void> clear() async {
    _cleared = true;
    _changed = true;
    await _lastPersist;
    await ref.read(kvStoreProvider).remove(key);
    if (!ref.mounted) {
      return;
    }
    state = const ConverterMemory();
  }

  void _commit(ConverterMemory next) {
    if (next == state) {
      return;
    }
    _changed = true;
    state = next;
    if (!_restored) {
      return;
    }
    _lastPersist = _lastPersist.then(
      (_) => ref.read(kvStoreProvider).setString(key, next.encode()),
    );
  }

  Future<void> _restoreMemory() async {
    final KvStore store = ref.read(kvStoreProvider);
    final ConverterMemory stored = ConverterMemory.decode(
      await store.getString(key),
    );
    if (!ref.mounted) {
      return;
    }
    if (_cleared) {
      _restored = true;
      return;
    }
    _restored = true;
    if (_changed) {
      // A save during start-up wins over the stored values.
      _lastPersist = _lastPersist.then(
        (_) => store.setString(key, state.encode()),
      );
      return;
    }
    state = stored;
  }
}

/// ARCHITECTURE "State": the last converter pair and the starred pairs.
final NotifierProvider<ConverterMemoryController, ConverterMemory>
converterMemoryProvider =
    NotifierProvider<ConverterMemoryController, ConverterMemory>(
      ConverterMemoryController.new,
      name: 'converterMemory',
    );
