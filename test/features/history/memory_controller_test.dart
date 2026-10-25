import 'dart:async';

import 'package:calculator/core/memory/memory_slots.dart';
import 'package:calculator/core/storage/kv_store.dart';
import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/features/history/memory_controller.dart';
import 'package:decimal/decimal.dart';
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
  Decimal d(int value) => Decimal.fromInt(value);

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

  MemoryController controller() => container.read(memoryProvider.notifier);
  List<Decimal?> slots() => container.read(memoryProvider);

  group('restore', () {
    test('starts with ten empty slots', () async {
      await controller().restoreDone;

      expect(slots(), MemorySlots.empty);
    });

    test('loads the stored array in order', () async {
      boot(
        values: <String, String>{
          MemoryController.key: MemorySlots.encode(<Decimal?>[d(1), d(2)]),
        },
      );

      await controller().restoreDone;

      expect(slots()[0], d(1));
      expect(slots()[1], d(2));
      expect(slots()[2], isNull);
    });

    test('corrupt stored data reads as empty', () async {
      boot(values: <String, String>{MemoryController.key: 'not json'});

      await controller().restoreDone;

      expect(slots(), MemorySlots.empty);
    });

    test('a change made while loading wins over the stored values', () async {
      final _SlowStore slow = _SlowStore(
        MemoryKvStore(<String, String>{
          MemoryController.key: MemorySlots.encode(<Decimal?>[d(7)]),
        }),
      );
      boot(kvStore: slow);

      expect(controller().store(d(3)), 0);
      slow.gate.complete();
      await controller().restoreDone;
      await controller().persistDone;

      expect(slots()[0], d(3));
      expect(
        MemorySlots.decode(await slow.inner.getString(MemoryController.key))[0],
        d(3),
      );
    });
  });

  group('slots', () {
    test('MS stores in the next slot and persists it', () async {
      await controller().restoreDone;

      final int first = controller().store(d(128));
      final int second = controller().store(d(3));
      await controller().persistDone;

      expect(first, 0);
      expect(second, 1);
      expect(slots()[0], d(128));
      expect(slots()[1], d(3));
      expect(
        MemorySlots.decode(await store.getString(MemoryController.key)),
        slots(),
      );
    });

    test('MC clears a slot, closes the gap and persists', () async {
      await controller().restoreDone;
      controller().store(d(1));
      controller().store(d(2));
      controller().store(d(3));

      controller().clearSlot(0);
      await controller().persistDone;

      expect(slots()[0], d(2));
      expect(slots()[1], d(3));
      expect(slots()[2], isNull);
      expect(
        MemorySlots.decode(await store.getString(MemoryController.key))[0],
        d(2),
      );
    });

    test('M+ and M- change one slot and persist', () async {
      await controller().restoreDone;
      controller().store(d(10));

      controller().addTo(0, d(5));
      controller().subtractFrom(0, d(20));
      await controller().persistDone;

      expect(slots()[0], d(-5));
      expect(
        MemorySlots.decode(await store.getString(MemoryController.key))[0],
        d(-5),
      );
    });

    test('clear empties every slot and removes the key', () async {
      await controller().restoreDone;
      controller().store(d(1));
      await controller().persistDone;

      await controller().clear();

      expect(slots(), MemorySlots.empty);
      expect(await store.getString(MemoryController.key), isNull);
    });
  });
}
