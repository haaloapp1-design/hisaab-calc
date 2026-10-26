import 'dart:convert';

import 'unit_catalog.dart';

/// A From → To pair on the unit converter, e.g. Length `km → mi` (SPEC §4).
///
/// It stores the units themselves and persists their ids, so a saved pair
/// resolves back to the catalog instances after a restart.
final class ConverterPair {
  const ConverterPair({
    required this.category,
    required this.from,
    required this.to,
  });

  /// The category the pair belongs to.
  final UnitCategory category;

  /// The From unit.
  final Unit from;

  /// The To unit.
  final Unit to;

  /// True when both units are in [category] and the sides differ.
  bool get isValid {
    if (from.id == to.id) {
      return false;
    }
    final List<Unit> units = UnitCatalog.of(category).units;
    return units.any((Unit unit) => unit.id == from.id) &&
        units.any((Unit unit) => unit.id == to.id);
  }

  /// True when [other] is the same pair, ignoring any equal-looking unit.
  bool samePair(ConverterPair other) =>
      other.category == category &&
      other.from.id == from.id &&
      other.to.id == to.id;

  /// The persisted form of this pair.
  Map<String, Object?> toJson() => <String, Object?>{
    'category': category.name,
    'from': from.id,
    'to': to.id,
  };

  /// Reads one stored pair, or null when it is unusable.
  ///
  /// Unknown categories, missing units, units from another category and equal
  /// sides are all dropped, so a bad row never breaks the converter.
  static ConverterPair? fromJson(Map<String, Object?> json) {
    final UnitCategory? category = _categoryByName(json['category']);
    final Object? fromId = json['from'];
    final Object? toId = json['to'];
    if (category == null || fromId is! String || toId is! String) {
      return null;
    }
    final Unit? from = _unitIn(category, fromId);
    final Unit? to = _unitIn(category, toId);
    if (from == null || to == null || from.id == to.id) {
      return null;
    }
    return ConverterPair(category: category, from: from, to: to);
  }

  @override
  bool operator ==(Object other) => other is ConverterPair && samePair(other);

  @override
  int get hashCode => Object.hash(category, from.id, to.id);

  @override
  String toString() => 'ConverterPair(${category.name}, ${from.id} → ${to.id})';

  static UnitCategory? _categoryByName(Object? name) {
    for (final UnitCategory category in UnitCategory.values) {
      if (category.name == name) {
        return category;
      }
    }
    return null;
  }

  static Unit? _unitIn(UnitCategory category, String id) {
    for (final Unit unit in UnitCatalog.of(category).units) {
      if (unit.id == id) {
        return unit;
      }
    }
    return null;
  }
}

/// The remembered converter state: the last pair and the favourite pairs
/// (SPEC §4: "Last used category and unit pair are remembered. Star =
/// favourite pair (shown at top of hub)").
final class ConverterMemory {
  const ConverterMemory({this.last, this.favourites = const <ConverterPair>[]});

  /// How many favourite pairs the hub shows.
  static const int maxFavourites = 8;

  /// The pair the converter opens with next time.
  final ConverterPair? last;

  /// The starred pairs, newest first.
  final List<ConverterPair> favourites;

  /// True when nothing has been saved yet.
  bool get isEmpty => last == null && favourites.isEmpty;

  /// True when [pair] is starred.
  bool isFavourite(ConverterPair pair) =>
      favourites.any((ConverterPair favourite) => favourite.samePair(pair));

  /// A copy with [pair] as the last used pair.
  ConverterMemory withLast(ConverterPair pair) =>
      ConverterMemory(last: pair, favourites: favourites);

  /// Adds [pair] when it is not starred, otherwise removes it.
  ConverterMemory toggleFavourite(ConverterPair pair) {
    if (isFavourite(pair)) {
      return ConverterMemory(
        last: last,
        favourites: favourites
            .where((ConverterPair favourite) => !favourite.samePair(pair))
            .toList(growable: false),
      );
    }
    final List<ConverterPair> next = <ConverterPair>[pair, ...favourites];
    if (next.length > maxFavourites) {
      next.removeRange(maxFavourites, next.length);
    }
    return ConverterMemory(last: last, favourites: next);
  }

  /// The stored JSON object.
  String encode() => jsonEncode(<String, Object?>{
    'last': last?.toJson(),
    'favourites': <Map<String, Object?>>[
      for (final ConverterPair pair in favourites) pair.toJson(),
    ],
  });

  /// Reads the stored object; missing or corrupt data reads as empty.
  static ConverterMemory decode(String? source) {
    if (source == null || source.isEmpty) {
      return const ConverterMemory();
    }
    try {
      final Object? json = jsonDecode(source);
      if (json is! Map<String, Object?>) {
        return const ConverterMemory();
      }
      final Object? lastJson = json['last'];
      final ConverterPair? last = lastJson is Map<String, Object?>
          ? ConverterPair.fromJson(lastJson)
          : null;
      final List<ConverterPair> favourites = <ConverterPair>[];
      final Object? rows = json['favourites'];
      if (rows is List<Object?>) {
        for (final Object? row in rows) {
          if (favourites.length == maxFavourites) {
            break;
          }
          if (row is! Map<String, Object?>) {
            continue;
          }
          final ConverterPair? pair = ConverterPair.fromJson(row);
          if (pair == null ||
              favourites.any((ConverterPair kept) => kept.samePair(pair))) {
            continue;
          }
          favourites.add(pair);
        }
      }
      return ConverterMemory(last: last, favourites: favourites);
    } on FormatException {
      return const ConverterMemory();
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is! ConverterMemory) {
      return false;
    }
    if (last != other.last || favourites.length != other.favourites.length) {
      return false;
    }
    for (int i = 0; i < favourites.length; i++) {
      if (!favourites[i].samePair(other.favourites[i])) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    last,
    Object.hashAll(<String>[
      for (final ConverterPair pair in favourites)
        '${pair.category.name}/${pair.from.id}/${pair.to.id}',
    ]),
  );

  @override
  String toString() => 'ConverterMemory(last: $last, favourites: $favourites)';
}
