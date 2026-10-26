import 'dart:async';

import 'package:calculator/core/storage/kv_store.dart';
import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/core/units/converter_memory.dart';
import 'package:calculator/core/units/unit_catalog.dart';
import 'package:calculator/features/converter/converter_memory_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Blocks reads until the test opens the gate, so a write can be made while
/// the start-up restore is still in flight.
final class _SlowStore implements KvStore {
  _SlowStore(this._inner);

  final MemoryKvStore _inner;
  final Completer<void> gate = Completer<void>();

  MemoryKvStore get inner => _inner;

  @override
  Future<String?> getString(String key) async {
    await gate.future;
    return _inner.getString(key);
  }

  @override
  Future<void> setString(String key, String value) =>
      _inner.setString(key, value);

  @override
  Future<void> remove(String key) => _inner.remove(key);
}

void main() {
  Unit unit(String id) => UnitCatalog.byId(id)!;

  ConverterPair pair(UnitCategory category, String from, String to) =>
      ConverterPair(category: category, from: unit(from), to: unit(to));

  ConverterPair kmToMi() => pair(UnitCategory.length, 'km', 'mi');

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

  ConverterMemoryController controller() =>
      container.read(converterMemoryProvider.notifier);
  ConverterMemory memory() => container.read(converterMemoryProvider);

  group('restore', () {
    test('starts empty', () async {
      await controller().restoreDone;
      expect(memory().isEmpty, isTrue);
    });

    test('loads the stored last pair and favourites', () async {
      final ConverterMemory stored = ConverterMemory(
        last: kmToMi(),
        favourites: <ConverterPair>[
          pair(UnitCategory.temperature, 'celsius', 'fahrenheit'),
        ],
      );
      boot(
        values: <String, String>{
          ConverterMemoryController.key: stored.encode(),
        },
      );

      await controller().restoreDone;

      expect(memory(), stored);
    });

    test('corrupt data starts empty instead of throwing', () async {
      boot(values: <String, String>{ConverterMemoryController.key: 'not json'});
      await controller().restoreDone;
      expect(memory().isEmpty, isTrue);
    });

    test('a save during the restore wins over the stored pair', () async {
      final _SlowStore slow = _SlowStore(
        MemoryKvStore(<String, String>{
          ConverterMemoryController.key: ConverterMemory(last: kmToMi())
              .encode(),
        }),
      );
      boot(kvStore: slow);

      final ConverterPair area = pair(UnitCategory.area, 'm2', 'ft2');
      controller().remember(area);
      slow.gate.complete();
      await controller().restoreDone;
      await controller().persistDone;

      expect(memory().last, area);
      expect(
        ConverterMemory.decode(
          await slow.inner.getString(ConverterMemoryController.key),
        ).last,
        area,
      );
    });
  });

  test('remembers the pair and persists it', () async {
    await controller().restoreDone;

    controller().remember(kmToMi());
    await controller().persistDone;

    expect(memory().last, kmToMi());
    expect(
      ConverterMemory.decode(
        await store.getString(ConverterMemoryController.key),
      ).last,
      kmToMi(),
    );
  });

  test('remembers only a changed pair', () async {
    await controller().restoreDone;
    controller().remember(kmToMi());
    await controller().persistDone;

    controller().remember(kmToMi());
    await controller().persistDone;

    expect(memory().favourites, isEmpty);
    expect(memory().last, kmToMi());
  });

  test('toggles a favourite and persists the star', () async {
    await controller().restoreDone;

    expect(controller().toggleFavourite(kmToMi()), isTrue);
    await controller().persistDone;
    expect(memory().isFavourite(kmToMi()), isTrue);
    expect(
      ConverterMemory.decode(
        await store.getString(ConverterMemoryController.key),
      ).favourites,
      <ConverterPair>[kmToMi()],
    );

    expect(controller().toggleFavourite(kmToMi()), isFalse);
    await controller().persistDone;
    expect(memory().isFavourite(kmToMi()), isFalse);
    expect(
      ConverterMemory.decode(
        await store.getString(ConverterMemoryController.key),
      ).favourites,
      isEmpty,
    );
  });

  test('keeps the last pair when starring', () async {
    await controller().restoreDone;
    controller().remember(kmToMi());

    controller().toggleFavourite(kmToMi());

    expect(memory().last, kmToMi());
    expect(memory().isFavourite(kmToMi()), isTrue);
  });

  test('clear removes the key and the memory', () async {
    await controller().restoreDone;
    controller().remember(kmToMi());
    controller().toggleFavourite(kmToMi());
    await controller().persistDone;

    await controller().clear();

    expect(memory().isEmpty, isTrue);
    expect(await store.getString(ConverterMemoryController.key), isNull);
  });

  test(
    'a clear during the restore does not resurrect the stored data',
    () async {
      final _SlowStore slow = _SlowStore(
        MemoryKvStore(<String, String>{
          ConverterMemoryController.key: ConverterMemory(last: kmToMi())
              .encode(),
        }),
      );
      boot(kvStore: slow);

      final Future<void> clearing = controller().clear();
      slow.gate.complete();
      await clearing;
      await controller().restoreDone;

      expect(memory().isEmpty, isTrue);
      expect(await slow.inner.getString(ConverterMemoryController.key), isNull);
    },
  );
}
