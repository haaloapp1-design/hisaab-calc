import 'dart:convert';

import 'package:decimal/decimal.dart';

/// The ten memory slots M1..M10 (BUSINESS_LOGIC 9).
///
/// Pure Dart: values are [Decimal]s and every operation returns a new
/// unmodifiable list, so the controller can persist it and Riverpod can see a
/// changed instance. Used slots stay packed at the front: storing fills M1
/// first, and clearing a slot moves the later values up one place, which keeps
/// M1 the main memory the display chip reads.
abstract final class MemorySlots {
  /// The number of slots the Memory tab can show.
  static const int count = 10;

  /// Ten empty slots, in order.
  static List<Decimal?> get empty =>
      List<Decimal?>.unmodifiable(List<Decimal?>.filled(count, null));

  /// M1, or null when the main slot is empty.
  static Decimal? main(List<Decimal?> slots) =>
      slots.isEmpty ? null : slots.first;

  /// The value the display chip prints: M1, with an empty slot reading as 0.
  static Decimal mainOrZero(List<Decimal?> slots) =>
      main(slots) ?? Decimal.zero;

  /// BUSINESS_LOGIC 9: the chip shows as soon as any slot is set.
  ///
  /// A stored `0` counts as set: the chip is the only way to reach `MS`/`MC`,
  /// so hiding it for a zero value would leave no way to store another slot or
  /// clear that one.
  static bool showsChip(List<Decimal?> slots) =>
      slots.any((Decimal? value) => value != null);

  /// The slot the next `MS` fills: the first empty one, or M1 when full.
  static int nextSlot(List<Decimal?> slots) {
    final int index = slots.indexOf(null);
    return index < 0 ? 0 : index;
  }

  /// `MS`: store [value] in the next free slot, overwriting M1 when full.
  static List<Decimal?> store(List<Decimal?> slots, Decimal value) {
    final List<Decimal?> next = _copy(slots);
    next[nextSlot(slots)] = value;
    return List<Decimal?>.unmodifiable(next);
  }

  /// `MC`: empty one slot and move the following values up to close the gap.
  ///
  /// Clearing an empty or out-of-range slot returns [slots] unchanged, so the
  /// controller can skip a write.
  static List<Decimal?> clearSlot(List<Decimal?> slots, int index) {
    if (index < 0 || index >= slots.length || slots[index] == null) {
      return slots;
    }
    final List<Decimal?> next = _copy(slots);
    for (int slot = index; slot < next.length - 1; slot++) {
      next[slot] = next[slot + 1];
    }
    next[next.length - 1] = null;
    return List<Decimal?>.unmodifiable(next);
  }

  /// Empty every slot ("Clear all saved data").
  static List<Decimal?> clearAll() => empty;

  /// `M+`: add [value] to the slot, treating an empty slot as zero.
  static List<Decimal?> addTo(List<Decimal?> slots, int index, Decimal value) =>
      _change(slots, index, (Decimal current) => current + value);

  /// `M-`: subtract [value] from the slot, treating an empty slot as zero.
  static List<Decimal?> subtractFrom(
    List<Decimal?> slots,
    int index,
    Decimal value,
  ) => _change(slots, index, (Decimal current) => current - value);

  /// The indexes of the slots that hold a value, lowest first.
  static List<int> usedSlots(List<Decimal?> slots) => <int>[
    for (int index = 0; index < slots.length; index++)
      if (slots[index] != null) index,
  ];

  /// The stored form: a ten-item JSON array of decimal strings and `null`s.
  static String encode(List<Decimal?> slots) => jsonEncode(<String?>[
    for (int index = 0; index < count; index++)
      index < slots.length ? slots[index]?.toString() : null,
  ]);

  /// Reads [raw], falling back to empty slots for anything unusable.
  ///
  /// A bad row becomes an empty slot while the rest of the list is kept, so a
  /// hand-edited or older value cannot break start-up.
  static List<Decimal?> decode(String? raw) {
    if (raw == null) {
      return empty;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return empty;
    }
    if (decoded is! List) {
      return empty;
    }
    final List<Decimal?> slots = <Decimal?>[
      for (int index = 0; index < count; index++) _read(decoded, index),
    ];
    return List<Decimal?>.unmodifiable(slots);
  }

  static Decimal? _read(List<Object?> values, int index) {
    if (index >= values.length) {
      return null;
    }
    final Object? value = values[index];
    return value is String ? Decimal.tryParse(value) : null;
  }

  static List<Decimal?> _change(
    List<Decimal?> slots,
    int index,
    Decimal Function(Decimal current) operation,
  ) {
    if (index < 0 || index >= slots.length) {
      return slots;
    }
    final List<Decimal?> next = _copy(slots);
    next[index] = operation(next[index] ?? Decimal.zero);
    return List<Decimal?>.unmodifiable(next);
  }

  static List<Decimal?> _copy(List<Decimal?> slots) =>
      List<Decimal?>.filled(count, null)
        ..setRange(0, slots.length < count ? slots.length : count, slots);
}
