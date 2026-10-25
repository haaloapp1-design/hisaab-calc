import 'package:calculator/core/storage/kv_store.dart';
import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/features/history/history_controller.dart';
import 'package:calculator/features/history/history_entry.dart';
import 'package:calculator/features/history/history_log.dart';
import 'package:calculator/features/settings/settings_controller.dart';
import 'package:calculator/features/settings/settings_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts writes so a skipped duplicate can be shown to touch no storage.
final class _CountingStore implements KvStore {
  _CountingStore(this._inner);

  final MemoryKvStore _inner;
  int writes = 0;

  @override
  Future<String?> getString(String key) => _inner.getString(key);

  @override
  Future<void> setString(String key, String value) {
    writes++;
    return _inner.setString(key, value);
  }

  @override
  Future<void> remove(String key) => _inner.remove(key);
}

void main() {
  final DateTime now = DateTime.now();

  HistoryEntry entry(
    int index, {
    DateTime? createdAt,
    HistoryMode mode = HistoryMode.basic,
  }) => HistoryEntry.create(
    expression: '${index + 1} + 1',
    result: '${index + 2}',
    mode: mode,
    createdAt: createdAt ?? now.subtract(Duration(minutes: index)),
  );

  late MemoryKvStore store;
  ProviderContainer? previous;
  late ProviderContainer container;

  void boot({Map<String, String>? values, KvStore? kvStore}) {
    previous?.dispose();
    store = MemoryKvStore(values);
    container = ProviderContainer(
      overrides: [kvStoreProvider.overrideWithValue(kvStore ?? store)],
    );
    previous = container;
  }

  setUp(boot);
  tearDown(() {
    previous?.dispose();
    previous = null;
  });

  HistoryController controller() => container.read(historyProvider.notifier);
  List<HistoryEntry> entries() => container.read(historyProvider);

  group('restore', () {
    test('starts empty when nothing is stored', () async {
      await controller().restoreDone;

      expect(entries(), isEmpty);
    });

    test('loads the stored list in order', () async {
      final List<HistoryEntry> stored = <HistoryEntry>[entry(0), entry(1)];
      boot(
        values: <String, String>{
          HistoryController.key: HistoryLog.encode(stored),
        },
      );

      await controller().restoreDone;

      expect(entries(), stored);
    });

    test('corrupt or unusable data reads as empty history', () async {
      boot(values: <String, String>{HistoryController.key: '{"not":"a list"'});

      await controller().restoreDone;

      expect(entries(), isEmpty);
    });

    test(
      'drops entries older than the Settings retention on start-up',
      () async {
        final HistoryEntry old = entry(
          0,
          createdAt: now.subtract(const Duration(days: 40)),
        );
        final HistoryEntry fresh = entry(
          1,
          createdAt: now.subtract(const Duration(days: 2)),
        );
        boot(
          values: <String, String>{
            HistoryController.key: HistoryLog.encode(<HistoryEntry>[
              fresh,
              old,
            ]),
          },
        );

        await controller().restoreDone;
        await controller().persistDone;

        expect(entries(), <HistoryEntry>[fresh]);
        expect(
          HistoryLog.decode(await store.getString(HistoryController.key)),
          <HistoryEntry>[fresh],
        );
      },
    );

    test('Forever in Settings keeps old entries', () async {
      final HistoryEntry old = entry(
        0,
        createdAt: now.subtract(const Duration(days: 400)),
      );
      boot(
        values: <String, String>{
          SettingsController.key: const Settings(
            historyRetention: HistoryRetention.forever,
          ).encode(),
          HistoryController.key: HistoryLog.encode(<HistoryEntry>[old]),
        },
      );

      await controller().restoreDone;

      expect(entries(), <HistoryEntry>[old]);
    });

    test('keeps entries saved while the stored list was loading', () async {
      final HistoryEntry stored = entry(1);
      boot(
        values: <String, String>{
          HistoryController.key: HistoryLog.encode(<HistoryEntry>[stored]),
        },
      );

      final HistoryEntry? added = controller().add(
        expression: '9 + 9',
        result: '18',
        mode: HistoryMode.scientific,
        at: now,
      );
      await controller().restoreDone;
      await controller().persistDone;

      expect(added, isNotNull);
      expect(entries().map((HistoryEntry row) => row.expression), <String>[
        '9 + 9',
        stored.expression,
      ]);
      expect(
        HistoryLog.decode(await store.getString(HistoryController.key)),
        hasLength(2),
      );
    });

    test('a clear during the restore does not resurrect entries', () async {
      boot(
        values: <String, String>{
          HistoryController.key: HistoryLog.encode(<HistoryEntry>[entry(0)]),
        },
      );

      final Future<void> cleared = controller().clear();
      await controller().restoreDone;
      await cleared;

      expect(entries(), isEmpty);
      expect(await store.getString(HistoryController.key), isNull);
    });
  });

  group('add', () {
    test('stores the newest entry first and returns it', () async {
      await controller().restoreDone;

      final HistoryEntry? first = controller().add(
        expression: '2 + 3',
        result: '5',
        mode: HistoryMode.basic,
        at: now,
      );
      final HistoryEntry? second = controller().add(
        expression: '2 × 3',
        result: '6',
        mode: HistoryMode.scientific,
        at: now.add(const Duration(seconds: 1)),
      );
      await controller().persistDone;

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(entries().map((HistoryEntry row) => row.expression), <String>[
        '2 × 3',
        '2 + 3',
      ]);
      expect(
        HistoryLog.decode(await store.getString(HistoryController.key)),
        entries(),
      );
    });

    test('skips an identical calculation without writing', () async {
      final _CountingStore counted = _CountingStore(MemoryKvStore());
      boot(kvStore: counted);
      await controller().restoreDone;

      controller().add(
        expression: '2 + 3',
        result: '5',
        mode: HistoryMode.basic,
        at: now,
      );
      await controller().persistDone;
      final int writesAfterFirst = counted.writes;

      final HistoryEntry? repeat = controller().add(
        expression: '2 + 3',
        result: '5',
        mode: HistoryMode.basic,
        at: now.add(const Duration(minutes: 1)),
      );
      await controller().persistDone;

      expect(repeat, isNull);
      expect(entries(), hasLength(1));
      expect(counted.writes, writesAfterFirst);
    });

    test('a different mode counts as a new calculation', () async {
      await controller().restoreDone;

      controller().add(
        expression: '2 + 3',
        result: '5',
        mode: HistoryMode.basic,
        at: now,
      );
      controller().add(
        expression: '2 + 3',
        result: '5',
        mode: HistoryMode.programmer,
        at: now.add(const Duration(seconds: 1)),
      );

      expect(entries(), hasLength(2));
      expect(entries().first.mode, HistoryMode.programmer);
    });
  });

  test('remove drops one entry and persists the rest', () async {
    final List<HistoryEntry> stored = <HistoryEntry>[entry(0), entry(1)];
    boot(
      values: <String, String>{
        HistoryController.key: HistoryLog.encode(stored),
      },
    );
    await controller().restoreDone;

    controller().remove(stored.first.id);
    await controller().persistDone;

    expect(entries(), <HistoryEntry>[stored.last]);
    expect(
      HistoryLog.decode(await store.getString(HistoryController.key)),
      <HistoryEntry>[stored.last],
    );
  });

  test('clear empties the state and removes the key', () async {
    boot(
      values: <String, String>{
        HistoryController.key: HistoryLog.encode(<HistoryEntry>[entry(0)]),
      },
    );
    await controller().restoreDone;

    await controller().clear();

    expect(entries(), isEmpty);
    expect(await store.getString(HistoryController.key), isNull);
  });

  test('prune uses the current retention setting', () async {
    final HistoryEntry recent = entry(
      0,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    final HistoryEntry older = entry(
      1,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    );
    boot(
      values: <String, String>{
        HistoryController.key: HistoryLog.encode(<HistoryEntry>[recent, older]),
      },
    );
    await controller().restoreDone;
    container
        .read(settingsProvider.notifier)
        .setHistoryRetention(HistoryRetention.days7);

    controller().prune(now: DateTime.now());
    await controller().persistDone;

    expect(entries(), <HistoryEntry>[recent]);
    expect(
      HistoryLog.decode(await store.getString(HistoryController.key)),
      <HistoryEntry>[recent],
    );
  });
}
