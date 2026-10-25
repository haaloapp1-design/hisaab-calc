import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/kv_store.dart';
import '../../core/storage/kv_store_provider.dart';
import '../settings/settings_controller.dart';
import 'history_entry.dart';
import 'history_log.dart';

/// Owns the saved calculations and persists them through [KvStore]
/// (BUSINESS_LOGIC §10, ARCHITECTURE "State").
///
/// It starts empty so the first frame is usable, restores asynchronously and
/// prunes entries older than the Settings retention during that restore.
/// Tests await [restoreDone] and [persistDone] instead of pumping a widget.
///
/// Writes are held back until the restore finishes: otherwise a history entry
/// saved while the stored list was still loading would overwrite that list.
class HistoryController extends Notifier<List<HistoryEntry>> {
  /// The KvStore key holding the entry array.
  static const String key = 'history_v1';

  Future<void>? _restore;
  Future<void> _lastPersist = Future<void>.value();
  bool _restored = false;
  bool _changed = false;
  bool _cleared = false;

  @override
  List<HistoryEntry> build() {
    _restore ??= _restoreHistory();
    return const <HistoryEntry>[];
  }

  /// Completes when the stored entries have been loaded and pruned. Test hook.
  Future<void> get restoreDone => _restore ?? Future<void>.value();

  /// Completes when the last persisted write has finished. Test hook.
  Future<void> get persistDone => _lastPersist;

  /// §10 saves a successful `=`. Returns null when it repeated the newest
  /// calculation (nothing is stored) or the new entry otherwise.
  HistoryEntry? add({
    required String expression,
    required String result,
    required HistoryMode mode,
    DateTime? at,
  }) {
    final HistoryEntry entry = HistoryEntry.create(
      expression: expression,
      result: result,
      mode: mode,
      createdAt: at ?? DateTime.now(),
    );
    final List<HistoryEntry> next = HistoryLog.add(state, entry);
    if (identical(next, state)) {
      return null;
    }
    _commit(next);
    return entry;
  }

  /// Removes one entry (SPEC §2 long-press delete).
  void remove(String id) {
    final List<HistoryEntry> next = HistoryLog.remove(state, id);
    if (identical(next, state)) {
      return;
    }
    _commit(next);
  }

  /// "Clear history" (SPEC §2, §10): drops every entry and its stored key.
  Future<void> clear() async {
    _cleared = true;
    _changed = true;
    await _lastPersist;
    await ref.read(kvStoreProvider).remove(key);
    if (!ref.mounted) {
      return;
    }
    state = const <HistoryEntry>[];
  }

  /// Drops entries older than the current retention; called on start-up and
  /// useful after Settings changes.
  void prune({DateTime? now}) {
    final List<HistoryEntry> next = HistoryLog.prune(
      state,
      now: now ?? DateTime.now(),
      retentionDays: ref.read(settingsProvider).historyRetention.days,
    );
    if (identical(next, state)) {
      return;
    }
    _commit(next);
  }

  /// Replaces the state and queues its JSON, once the stored list is loaded.
  void _commit(List<HistoryEntry> next) {
    _changed = true;
    state = next;
    if (!_restored) {
      return;
    }
    _lastPersist = _lastPersist.then(
      (_) => ref.read(kvStoreProvider).setString(key, HistoryLog.encode(next)),
    );
  }

  Future<void> _restoreHistory() async {
    final KvStore store = ref.read(kvStoreProvider);
    final List<HistoryEntry> stored = HistoryLog.decode(
      await store.getString(key),
    );
    // The retention comes from Settings, which may still be loading.
    await ref.read(settingsProvider.notifier).restoreDone;
    if (!ref.mounted) {
      return;
    }
    if (_cleared) {
      // "Clear all saved data" already removed the key: do not resurrect it.
      _restored = true;
      return;
    }
    final List<HistoryEntry> merged = _withPendingWrites(stored);
    final List<HistoryEntry> kept = HistoryLog.prune(
      merged,
      now: DateTime.now(),
      retentionDays: ref.read(settingsProvider).historyRetention.days,
    );
    _restored = true;
    state = kept;
    if (_changed || !identical(kept, stored)) {
      _lastPersist = _lastPersist.then(
        (_) => store.setString(key, HistoryLog.encode(kept)),
      );
    }
  }

  /// Puts anything saved while the restore was in flight in front of the
  /// stored entries, keeping the newest 500.
  List<HistoryEntry> _withPendingWrites(List<HistoryEntry> stored) {
    if (!_changed) {
      return stored;
    }
    final Set<String> ids = <String>{
      for (final HistoryEntry entry in state) entry.id,
    };
    final List<HistoryEntry> next = <HistoryEntry>[
      ...state,
      ...stored.where((HistoryEntry entry) => !ids.contains(entry.id)),
    ];
    if (next.length > HistoryLog.maxEntries) {
      next.removeRange(HistoryLog.maxEntries, next.length);
    }
    return next;
  }
}

/// ARCHITECTURE "State": the saved calculations, newest first.
final NotifierProvider<HistoryController, List<HistoryEntry>> historyProvider =
    NotifierProvider<HistoryController, List<HistoryEntry>>(
      HistoryController.new,
      name: 'history',
    );
