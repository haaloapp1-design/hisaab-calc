import 'package:calculator/core/units/converter_memory.dart';
import 'package:calculator/core/units/unit_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Unit unit(String id) => UnitCatalog.byId(id)!;

  ConverterPair pair(UnitCategory category, String from, String to) =>
      ConverterPair(category: category, from: unit(from), to: unit(to));

  ConverterPair kmToMi() => pair(UnitCategory.length, 'km', 'mi');

  test('a pair needs two different units of its category', () {
    expect(kmToMi().isValid, isTrue);

    final ConverterPair same = pair(UnitCategory.length, 'km', 'km');
    expect(same.isValid, isFalse);

    final ConverterPair otherCategory = pair(UnitCategory.area, 'km', 'mi');
    expect(otherCategory.isValid, isFalse);

    final ConverterPair unknown = ConverterPair(
      category: UnitCategory.length,
      from: unit('km'),
      to: unit('marla'),
    );
    expect(unknown.isValid, isFalse);
  });

  test('compares category, From and To (direction matters)', () {
    expect(kmToMi(), kmToMi());
    expect(kmToMi().hashCode, kmToMi().hashCode);
    expect(kmToMi(), isNot(pair(UnitCategory.length, 'mi', 'km')));
    expect(kmToMi(), isNot(pair(UnitCategory.length, 'km', 'm')));
    expect(kmToMi(), isNot(pair(UnitCategory.area, 'km', 'mi')));
    expect(kmToMi().toString(), 'ConverterPair(length, km → mi)');
  });

  test('persists the category and unit ids and resolves them back', () {
    final ConverterMemory memory = ConverterMemory(
      last: kmToMi(),
      favourites: <ConverterPair>[
        kmToMi(),
        pair(UnitCategory.temperature, 'celsius', 'fahrenheit'),
      ],
    );

    final ConverterMemory decoded = ConverterMemory.decode(memory.encode());

    expect(decoded, memory);
    expect(decoded.last!.from.id, 'km');
    expect(decoded.last!.to.id, 'mi');
    expect(decoded.favourites.first, kmToMi());
    expect(decoded.favourites.last.category, UnitCategory.temperature);
    expect(decoded.favourites.last.to.id, 'fahrenheit');
  });

  test('the last pair and favourites change independently', () {
    const ConverterMemory empty = ConverterMemory();
    expect(empty.isEmpty, isTrue);

    final ConverterMemory remembered = empty.withLast(kmToMi());
    expect(remembered.last, kmToMi());
    expect(remembered.favourites, isEmpty);

    final ConverterMemory starred = remembered.toggleFavourite(kmToMi());
    expect(starred.isFavourite(kmToMi()), isTrue);
    expect(starred.last, kmToMi());
    expect(remembered.isFavourite(kmToMi()), isFalse);

    final ConverterMemory removed = starred.toggleFavourite(kmToMi());
    expect(removed.isFavourite(kmToMi()), isFalse);
    expect(removed.last, kmToMi());
  });

  test('favourites keep the newest first and cap at eight', () {
    ConverterMemory memory = const ConverterMemory();
    final List<ConverterPair> pairs = <ConverterPair>[
      for (final String id in <String>[
        'mm',
        'cm',
        'm',
        'in',
        'ft',
        'yd',
        'mi',
        'nmi',
      ])
        pair(UnitCategory.length, 'km', id),
    ];
    for (final ConverterPair favourite in pairs) {
      memory = memory.toggleFavourite(favourite);
    }
    expect(memory.favourites.first, pairs.last);
    expect(memory.favourites, hasLength(ConverterMemory.maxFavourites));

    final ConverterPair extra = pair(UnitCategory.length, 'm', 'ft');
    memory = memory.toggleFavourite(extra);
    expect(memory.favourites, hasLength(ConverterMemory.maxFavourites));
    expect(memory.isFavourite(extra), isTrue);
    expect(memory.isFavourite(pairs.first), isFalse);
  });

  test('decode drops bad rows, duplicates and rows past the cap', () {
    final String encoded =
        '{"last":{"category":"nope","from":"km","to":"mi"},'
        '"favourites":['
        '{"category":"length","from":"km","to":"mi"},'
        '{"category":"length","from":"km","to":"mi"},'
        '{"category":"area","from":"km","to":"mi"},'
        '{"category":"length","from":"km","to":"km"},'
        '{"category":"length","from":"km"},'
        '{"category":"length","from":"km","to":"marla"},'
        '{"category":"length","from":"m","to":"ft"}'
        ']}';

    final ConverterMemory memory = ConverterMemory.decode(encoded);

    expect(memory.last, isNull);
    expect(memory.favourites, <ConverterPair>[
      pair(UnitCategory.length, 'km', 'mi'),
      pair(UnitCategory.length, 'm', 'ft'),
    ]);
  });

  test('decode caps the stored favourites', () {
    final String rows = <String>[
      for (final String id in <String>[
        'mm',
        'cm',
        'm',
        'in',
        'ft',
        'yd',
        'mi',
        'nmi',
      ])
        '{"category":"length","from":"km","to":"$id"}',
    ].join(',');
    final ConverterMemory memory = ConverterMemory.decode(
      '{"favourites":[$rows]}',
    );
    expect(memory.favourites, hasLength(ConverterMemory.maxFavourites));
  });

  test('decode treats missing or corrupt data as empty', () {
    for (final String? source in <String?>[
      null,
      '',
      'not json',
      '[]',
      '42',
      '{"favourites":"nope"}',
    ]) {
      expect(ConverterMemory.decode(source), const ConverterMemory());
    }
  });

  test('memory equality compares the last pair and every favourite', () {
    final ConverterMemory one = ConverterMemory(
      last: kmToMi(),
      favourites: <ConverterPair>[kmToMi()],
    );
    final ConverterMemory same = ConverterMemory(
      last: kmToMi(),
      favourites: <ConverterPair>[kmToMi()],
    );
    final ConverterMemory other = ConverterMemory(
      last: kmToMi(),
      favourites: <ConverterPair>[pair(UnitCategory.length, 'mi', 'km')],
    );

    expect(one, same);
    expect(one.hashCode, same.hashCode);
    expect(one, isNot(other));
    expect(const ConverterMemory(), const ConverterMemory());
  });
}
