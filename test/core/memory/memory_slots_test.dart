import 'package:calculator/core/memory/memory_slots.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Decimal d(int value) => Decimal.fromInt(value);

  group('slots', () {
    test('starts with ten empty slots and no main value', () {
      final List<Decimal?> slots = MemorySlots.empty;

      expect(slots, hasLength(10));
      expect(slots, everyElement(isNull));
      expect(MemorySlots.main(slots), isNull);
      expect(MemorySlots.mainOrZero(slots), Decimal.zero);
      expect(MemorySlots.showsChip(slots), isFalse);
      expect(MemorySlots.usedSlots(slots), isEmpty);
      expect(MemorySlots.nextSlot(slots), 0);
    });

    test('store fills the next free slot, M1 first', () {
      final List<Decimal?> one = MemorySlots.store(MemorySlots.empty, d(128));
      final List<Decimal?> two = MemorySlots.store(one, d(3));

      expect(one, <Decimal?>[
        d(128),
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
      ]);
      expect(MemorySlots.nextSlot(one), 1);
      expect(two[0], d(128));
      expect(two[1], d(3));
      expect(MemorySlots.usedSlots(two), <int>[0, 1]);
    });

    test('store overwrites M1 when every slot is full', () {
      List<Decimal?> slots = MemorySlots.empty;
      for (int index = 1; index <= 10; index++) {
        slots = MemorySlots.store(slots, d(index));
      }

      expect(MemorySlots.nextSlot(slots), 0);
      expect(slots, hasLength(10));

      final List<Decimal?> next = MemorySlots.store(slots, d(99));

      expect(next[0], d(99));
      expect(next[1], d(2));
      expect(next[9], d(10));
    });
  });

  group('clear', () {
    test('clearing a slot moves the later values up', () {
      List<Decimal?> slots = MemorySlots.empty;
      for (int index = 1; index <= 3; index++) {
        slots = MemorySlots.store(slots, d(index));
      }

      final List<Decimal?> next = MemorySlots.clearSlot(slots, 0);

      expect(next, <Decimal?>[
        d(2),
        d(3),
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
      ]);
      expect(MemorySlots.main(next), d(2));
    });

    test('clearing an empty or invalid slot keeps the same list', () {
      final List<Decimal?> slots = MemorySlots.store(MemorySlots.empty, d(1));

      expect(identical(MemorySlots.clearSlot(slots, 1), slots), isTrue);
      expect(identical(MemorySlots.clearSlot(slots, -1), slots), isTrue);
      expect(identical(MemorySlots.clearSlot(slots, 10), slots), isTrue);
    });

    test('clearAll returns ten empty slots', () {
      final List<Decimal?> slots = MemorySlots.store(MemorySlots.empty, d(1));

      expect(MemorySlots.clearAll(), MemorySlots.empty);
      expect(MemorySlots.clearAll(), isNot(same(slots)));
    });
  });

  group('add and subtract', () {
    test('M+ and M- use the slot value, treating empty as zero', () {
      List<Decimal?> slots = MemorySlots.addTo(MemorySlots.empty, 0, d(5));
      expect(slots[0], d(5));

      slots = MemorySlots.addTo(slots, 0, Decimal.parse('2.5'));
      expect(slots[0], Decimal.parse('7.5'));

      slots = MemorySlots.subtractFrom(slots, 0, d(10));
      expect(slots[0], Decimal.parse('-2.5'));
    });

    test('an invalid index keeps the same list', () {
      final List<Decimal?> slots = MemorySlots.empty;

      expect(identical(MemorySlots.addTo(slots, 10, d(1)), slots), isTrue);
      expect(
        identical(MemorySlots.subtractFrom(slots, -1, d(1)), slots),
        isTrue,
      );
    });
  });

  group('chip rule', () {
    test('any set slot shows, including a stored zero', () {
      expect(MemorySlots.showsChip(<Decimal?>[d(1)]), isTrue);
      expect(MemorySlots.showsChip(<Decimal?>[Decimal.zero]), isTrue);
      expect(MemorySlots.showsChip(<Decimal?>[null, Decimal.zero]), isTrue);
      expect(MemorySlots.showsChip(<Decimal?>[Decimal.zero, d(2)]), isTrue);
    });

    test('no set slot hides the chip', () {
      expect(MemorySlots.showsChip(<Decimal?>[null]), isFalse);
      expect(MemorySlots.showsChip(MemorySlots.empty), isFalse);
    });
  });

  group('persistence', () {
    test('encode and decode round-trip every slot', () {
      List<Decimal?> slots = MemorySlots.empty;
      slots = MemorySlots.store(slots, Decimal.parse('-1.25'));
      slots = MemorySlots.store(slots, Decimal.parse('0'));
      slots = MemorySlots.store(slots, Decimal.parse('3.14159'));

      expect(MemorySlots.decode(MemorySlots.encode(slots)), slots);
    });

    test('decode pads a short array and trims a long one', () {
      expect(MemorySlots.decode('["1","2"]'), <Decimal?>[
        d(1),
        d(2),
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
      ]);
      expect(
        MemorySlots.decode('["1","2","3","4","5","6","7","8","9","10","11"]'),
        hasLength(10),
      );
      expect(
        MemorySlots.decode('["1","2","3","4","5","6","7","8","9","10"]')[9],
        d(10),
      );
    });

    test('bad rows become empty slots without losing the rest', () {
      expect(MemorySlots.decode('["1", 2, "bad", null, "5"]'), <Decimal?>[
        d(1),
        null,
        null,
        null,
        d(5),
        null,
        null,
        null,
        null,
        null,
      ]);
    });

    test('missing, corrupt or non-list data reads as empty', () {
      expect(MemorySlots.decode(null), MemorySlots.empty);
      expect(MemorySlots.decode('not json'), MemorySlots.empty);
      expect(MemorySlots.decode('{"0":"1"}'), MemorySlots.empty);
      expect(MemorySlots.decode('"1"'), MemorySlots.empty);
    });
  });
}
