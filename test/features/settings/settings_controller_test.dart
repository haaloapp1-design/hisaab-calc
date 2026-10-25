import 'package:calculator/core/engine/angle_mode.dart';
import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/features/settings/settings_controller.dart';
import 'package:calculator/features/settings/settings_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemoryKvStore store;
  late ProviderContainer container;

  setUp(() {
    store = MemoryKvStore();
    container = ProviderContainer(
      overrides: [kvStoreProvider.overrideWithValue(store)],
    );
  });

  tearDown(() => container.dispose());

  SettingsController controller() =>
      container.read(settingsProvider.notifier);
  Settings settings() => container.read(settingsProvider);

  group('restore', () {
    test('starts from the defaults when nothing is stored', () async {
      await controller().restoreDone;

      expect(settings(), const Settings());
    });

    test('loads the stored JSON', () async {
      const Settings stored = Settings(
        themeMode: AppThemeMode.dark,
        accent: AccentSwatch.rust,
        angleMode: AngleMode.rad,
        decimalPlaces: 5,
        thousandsSeparator: false,
        haptics: false,
        keySounds: true,
        historyRetention: HistoryRetention.forever,
      );
      await store.setString(SettingsController.key, stored.encode());

      await controller().restoreDone;

      expect(settings(), stored);
    });

    test('corrupt JSON keeps the defaults instead of throwing', () async {
      await store.setString(SettingsController.key, '{oops');

      await controller().restoreDone;

      expect(settings(), const Settings());
    });

    test('a change made while loading is not overwritten', () async {
      await store.setString(
        SettingsController.key,
        const Settings(themeMode: AppThemeMode.light).encode(),
      );
      final SettingsController c = controller();

      c.setThemeMode(AppThemeMode.dark);
      await c.restoreDone;

      expect(settings().themeMode, AppThemeMode.dark);
    });
  });

  group('updates', () {
    test('each setter updates the state and queues a write', () async {
      await controller().restoreDone;
      final SettingsController c = controller();

      c.setThemeMode(AppThemeMode.dark);
      c.setAccent(AccentSwatch.teal);
      c.setAngleMode(AngleMode.rad);
      c.setDecimalPlaces(3);
      c.setThousandsSeparator(false);
      c.setHaptics(false);
      c.setKeySounds(true);
      c.setHistoryRetention(HistoryRetention.days90);
      await c.persistDone;

      const Settings expected = Settings(
        themeMode: AppThemeMode.dark,
        accent: AccentSwatch.teal,
        angleMode: AngleMode.rad,
        decimalPlaces: 3,
        thousandsSeparator: false,
        haptics: false,
        keySounds: true,
        historyRetention: HistoryRetention.days90,
      );
      expect(settings(), expected);
      expect(
        Settings.decode((await store.getString(SettingsController.key))!),
        expected,
      );
    });

    test('a fixed decimal count can be cleared back to Auto', () async {
      await controller().restoreDone;

      controller().setDecimalPlaces(2);
      controller().setDecimalPlaces(null);
      await controller().persistDone;

      expect(settings().decimalPlaces, isNull);
      expect(
        Settings.decode(
          (await store.getString(SettingsController.key))!,
        ).decimalPlaces,
        isNull,
      );
    });

    test('an equal value does not write to the store', () async {
      await controller().restoreDone;

      controller().setHaptics(true);
      await controller().persistDone;

      expect(await store.getString(SettingsController.key), isNull);
    });

    test('writes survive a fresh controller over the same store', () async {
      await controller().restoreDone;
      controller().setAccent(AccentSwatch.violet);
      await controller().persistDone;

      final ProviderContainer reopened = ProviderContainer(
        overrides: [kvStoreProvider.overrideWithValue(store)],
      );
      addTearDown(reopened.dispose);

      await reopened.read(settingsProvider.notifier).restoreDone;

      expect(reopened.read(settingsProvider).accent, AccentSwatch.violet);
    });
  });
}
