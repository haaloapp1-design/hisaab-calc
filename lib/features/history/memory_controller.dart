import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/memory/memory_slots.dart';
import '../../core/storage/kv_store.dart';
import '../../core/storage/kv_store_provider.dart';

/// Owns the ten memory slots and persists them through [KvStore]
/// (BUSINESS_LOGIC 9, ARCHITECTURE "State").
///
/// The first frame shows empty slots while [restoreDone] loads the stored
/// array. A change made during that load wins over the stored values, the same
/// rule Settings uses; `clear` removes the key after any queued write so a
/// start-up restore cannot bring cleared slots back.
class MemoryController extends Notifier<List<Decimal?>> {
  /// The KvStore key holding the slot array.
  static const String key = 'memory_v1';

  Future<void>? _restore;
  Future<void> _lastPersist = Future<void>.value();
  bool _restored = false;
  bool _changed = false;
  bool _cleared = false;

  @override
  List<Decimal?> build() {
    _restore ??= _restoreMemory();
    return MemorySlots.empty;
  }

  /// Completes when the stored slots have been loaded. Test hook.
  Future<void> get restoreDone => _restore ?? Future<void>.value();

  /// Completes when the last persisted write has finished. Test hook.
  Future<void> get persistDone => _lastPersist;

  /// `MS`: store [value] in the next free slot. Returns the slot index used,
  /// so the caller can say which one changed.
  int store(Decimal value) {
    final int index = MemorySlots.nextSlot(state);
    _commit(MemorySlots.store(state, value));
    return index;
  }

  /// `MC`: empty one slot and move later values up.
  void clearSlot(int index) => _commit(MemorySlots.clearSlot(state, index));

  /// `M+` on a slot card.
  void addTo(int index, Decimal value) =>
      _commit(MemorySlots.addTo(state, index, value));

  /// `M-` on a slot card.
  void subtractFrom(int index, Decimal value) =>
      _commit(MemorySlots.subtractFrom(state, index, value));

  /// SPEC 3 "Clear all saved data": empty every slot and delete the key.
  Future<void> clear() async {
    _cleared = true;
    _changed = true;
    await _lastPersist;
    await ref.read(kvStoreProvider).remove(key);
    if (!ref.mounted) {
      return;
    }
    state = MemorySlots.clearAll();
  }

  void _commit(List<Decimal?> next) {
    if (identical(next, state)) {
      return;
    }
    _changed = true;
    state = next;
    if (!_restored) {
      return;
    }
    _lastPersist = _lastPersist.then(
      (_) => ref.read(kvStoreProvider).setString(key, MemorySlots.encode(next)),
    );
  }

  Future<void> _restoreMemory() async {
    final KvStore store = ref.read(kvStoreProvider);
    final List<Decimal?> stored = MemorySlots.decode(
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
      // A store/clear during start-up wins over the stored values.
      _lastPersist = _lastPersist.then(
        (_) => store.setString(key, MemorySlots.encode(state)),
      );
      return;
    }
    state = stored;
  }
}

/// ARCHITECTURE "State": M1..M10, M1 first. `null` means an empty slot.
final NotifierProvider<MemoryController, List<Decimal?>> memoryProvider =
    NotifierProvider<MemoryController, List<Decimal?>>(
      MemoryController.new,
      name: 'memory',
    );
