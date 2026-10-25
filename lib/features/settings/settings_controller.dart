import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/engine/angle_mode.dart';
import '../../core/storage/kv_store.dart';
import '../../core/storage/kv_store_provider.dart';
import 'settings_model.dart';

/// Owns the app's [Settings] and persists every change through [KvStore]
/// (SPEC §3, ARCHITECTURE "State").
///
/// Like the calculator, it starts from the defaults so the first frame is
/// usable, then restores asynchronously. Tests await [restoreDone] and
/// [persistDone] instead of pumping a widget.
class SettingsController extends Notifier<Settings> {
  /// The KvStore key holding the [Settings] JSON.
  static const String key = 'settings_v1';

  Future<void>? _restore;
  Future<void> _lastPersist = Future<void>.value();
  bool _changed = false;

  @override
  Settings build() {
    _restore ??= _restoreSettings();
    return const Settings();
  }

  /// Completes when the stored settings have been loaded. Test hook.
  Future<void> get restoreDone => _restore ?? Future<void>.value();

  /// Completes when the last persisted write has finished. Test hook.
  Future<void> get persistDone => _lastPersist;

  /// SPEC §3 theme row.
  void setThemeMode(AppThemeMode value) =>
      _save(state.copyWith(themeMode: value));

  /// SPEC §3 accent swatches.
  void setAccent(AccentSwatch value) => _save(state.copyWith(accent: value));

  /// SPEC §3 angle unit; T27 feeds this to the calculator.
  void setAngleMode(AngleMode value) =>
      _save(state.copyWith(angleMode: value));

  /// SPEC §3 decimal row: 0–10, or null for Auto.
  void setDecimalPlaces(int? value) =>
      _save(state.copyWith(decimalPlaces: () => value));

  /// SPEC §3 thousands separator switch.
  void setThousandsSeparator(bool value) =>
      _save(state.copyWith(thousandsSeparator: value));

  /// SPEC §3 "Vibrate on key press".
  void setHaptics(bool value) => _save(state.copyWith(haptics: value));

  /// SPEC §3 "Key sounds".
  void setKeySounds(bool value) => _save(state.copyWith(keySounds: value));

  /// SPEC §3 "Keep history for".
  void setHistoryRetention(HistoryRetention value) =>
      _save(state.copyWith(historyRetention: value));

  /// Writes [next] and schedules its JSON for storage. Equal values are a
  /// no-op, so a rebuild does not touch the store.
  void _save(Settings next) {
    if (next == state) {
      return;
    }
    _changed = true;
    state = next;
    final String text = next.encode();
    final KvStore store = ref.read(kvStoreProvider);
    _lastPersist = _lastPersist.then((_) => store.setString(key, text));
  }

  Future<void> _restoreSettings() async {
    final String? raw = await ref.read(kvStoreProvider).getString(key);
    // A choice made while the read was in flight wins over the stored value.
    if (!ref.mounted || _changed || raw == null) {
      return;
    }
    state = Settings.decode(raw);
  }
}

/// ARCHITECTURE "State": the settings every screen reads.
final NotifierProvider<SettingsController, Settings> settingsProvider =
    NotifierProvider<SettingsController, Settings>(
      SettingsController.new,
      name: 'settings',
    );
