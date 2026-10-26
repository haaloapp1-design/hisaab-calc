import 'package:calculator/core/units/unit_catalog.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

Unit unitOf(UnitCategory category, String id) =>
    UnitCatalog.of(category).units.firstWhere((Unit unit) => unit.id == id);

FactorUnit factorUnitOf(UnitCategory category, String id) =>
    unitOf(category, id) as FactorUnit;

/// Decimal equality with the small rounding a division can introduce.
void expectDecimalClose(Decimal actual, Decimal expected, {String? reason}) {
  final Decimal difference = (actual - expected).abs();
  expect(
    difference <= Decimal.parse('1e-12'),
    isTrue,
    reason: '${reason ?? 'value'}: $actual != $expected',
  );
}

void main() {
  test('lists the twelve SPEC §4 categories in hub order', () {
    expect(
      UnitCatalog.categories.map((UnitCategoryData entry) => entry.category),
      UnitCategory.values,
    );
  });

  test('lists exactly the units SPEC §4 requires', () {
    const Map<UnitCategory, List<String>>
    expected = <UnitCategory, List<String>>{
      UnitCategory.length: <String>[
        'mm',
        'cm',
        'm',
        'km',
        'in',
        'ft',
        'yd',
        'mi',
        'nmi',
      ],
      UnitCategory.area: <String>[
        'mm2',
        'cm2',
        'm2',
        'hectare',
        'km2',
        'in2',
        'ft2',
        'yd2',
        'acre',
        'marla',
        'kanal',
      ],
      UnitCategory.volume: <String>[
        'ml',
        'l',
        'm3',
        'tsp',
        'tbsp',
        'cup_us',
        'floz_us',
        'gal_us',
        'gal_uk',
      ],
      UnitCategory.mass: <String>[
        'mg',
        'g',
        'kg',
        'tonne',
        'oz',
        'lb',
        'stone',
        'tola',
        'maund',
      ],
      UnitCategory.temperature: <String>['celsius', 'fahrenheit', 'kelvin'],
      UnitCategory.speed: <String>['mps', 'kmh', 'mph', 'knot'],
      UnitCategory.time: <String>['ms', 's', 'min', 'h', 'day', 'week', 'year'],
      UnitCategory.data: <String>[
        'bit',
        'byte',
        'kb',
        'mb',
        'gb',
        'tb',
        'kib',
        'mib',
        'gib',
      ],
      UnitCategory.pressure: <String>['pa', 'kpa', 'bar', 'psi', 'atm', 'mmhg'],
      UnitCategory.energy: <String>['j', 'kj', 'cal', 'kcal', 'wh', 'kwh'],
      UnitCategory.power: <String>['w', 'kw', 'hp'],
      UnitCategory.angle: <String>['degree', 'radian', 'gradian'],
    };

    for (final UnitCategory category in UnitCategory.values) {
      expect(
        UnitCatalog.of(category).units.map((Unit unit) => unit.id),
        expected[category],
        reason: category.label,
      );
    }
  });

  test('has unique ids, unique symbols per category and a base unit', () {
    final Set<String> ids = <String>{};
    for (final UnitCategoryData entry in UnitCatalog.categories) {
      final List<String> symbols = entry.units
          .map((Unit unit) => unit.symbol)
          .toList();
      expect(
        symbols.toSet(),
        hasLength(symbols.length),
        reason: '${entry.category.label} has duplicate symbols',
      );
      expect(
        symbols,
        contains(entry.category.baseSymbol),
        reason: '${entry.category.label} is missing its base unit',
      );
      for (final Unit unit in entry.units) {
        expect(ids.add(unit.id), isTrue, reason: 'duplicate id ${unit.id}');
      }
    }
    expect(ids, hasLength(79));
    expect(UnitCatalog.all, hasLength(79));
  });

  test('every factor category has exactly one unit with factor 1', () {
    for (final UnitCategoryData entry in UnitCatalog.categories) {
      if (entry.category == UnitCategory.temperature) {
        continue;
      }
      final List<FactorUnit> ones = entry.units
          .whereType<FactorUnit>()
          .where((FactorUnit unit) => unit.factor == Decimal.one)
          .toList();
      expect(ones, hasLength(1), reason: entry.category.label);
      expect(ones.single.symbol, entry.category.baseSymbol);
    }
  });

  test('every unit converts 1 to base and back unchanged', () {
    for (final UnitCategoryData entry in UnitCatalog.categories) {
      for (final Unit unit in entry.units) {
        final Decimal base = unit.toBase(Decimal.one);
        final Decimal back = unit.fromBase(base);
        expectDecimalClose(
          back,
          Decimal.one,
          reason: '${entry.category.label} ${unit.id}',
        );
      }
    }
  });

  test('uses the §12 factors to the base unit', () {
    const Map<UnitCategory, Map<String, String>> factors =
        <UnitCategory, Map<String, String>>{
          UnitCategory.length: <String, String>{
            'mm': '0.001',
            'cm': '0.01',
            'm': '1',
            'km': '1000',
            'in': '0.0254',
            'ft': '0.3048',
            'yd': '0.9144',
            'mi': '1609.344',
            'nmi': '1852',
          },
          UnitCategory.area: <String, String>{
            'mm2': '0.000001',
            'cm2': '0.0001',
            'm2': '1',
            'hectare': '10000',
            'km2': '1000000',
            'in2': '0.00064516',
            'ft2': '0.09290304',
            'yd2': '0.83612736',
            'acre': '4046.8564224',
            'marla': '25.29285264',
            'kanal': '505.8570528',
          },
          UnitCategory.volume: <String, String>{
            'ml': '0.001',
            'l': '1',
            'm3': '1000',
            'tsp': '0.00492892159375',
            'tbsp': '0.01478676478125',
            'cup_us': '0.2365882365',
            'floz_us': '0.0295735295625',
            'gal_us': '3.785411784',
            'gal_uk': '4.54609',
          },
          UnitCategory.mass: <String, String>{
            'mg': '0.000001',
            'g': '0.001',
            'kg': '1',
            'tonne': '1000',
            'oz': '0.028349523125',
            'lb': '0.45359237',
            'stone': '6.35029318',
            'tola': '0.0116638038',
            'maund': '37.3242',
          },
          UnitCategory.speed: <String, String>{'mps': '1', 'mph': '0.44704'},
          UnitCategory.time: <String, String>{
            'ms': '0.001',
            's': '1',
            'min': '60',
            'h': '3600',
            'day': '86400',
            'week': '604800',
            'year': '31536000',
          },
          UnitCategory.data: <String, String>{
            'bit': '0.125',
            'byte': '1',
            'kb': '1000',
            'mb': '1000000',
            'gb': '1000000000',
            'tb': '1000000000000',
            'kib': '1024',
            'mib': '1048576',
            'gib': '1073741824',
          },
          UnitCategory.pressure: <String, String>{
            'pa': '1',
            'kpa': '1000',
            'bar': '100000',
            'psi': '6894.757293168',
            'atm': '101325',
            'mmhg': '133.322387415',
          },
          UnitCategory.energy: <String, String>{
            'j': '1',
            'kj': '1000',
            'cal': '4.184',
            'kcal': '4184',
            'wh': '3600',
            'kwh': '3600000',
          },
          UnitCategory.power: <String, String>{
            'w': '1',
            'kw': '1000',
            'hp': '745.69987158227',
          },
          UnitCategory.angle: <String, String>{'radian': '1'},
        };

    for (final MapEntry<UnitCategory, Map<String, String>> entry
        in factors.entries) {
      for (final MapEntry<String, String> factor in entry.value.entries) {
        expect(
          factorUnitOf(entry.key, factor.key).factor,
          Decimal.parse(factor.value),
          reason: '${entry.key.label}/${factor.key}',
        );
      }
    }
  });

  test('keeps the repeating §12 ratios', () {
    expectDecimalClose(
      factorUnitOf(UnitCategory.speed, 'kmh').toBase(Decimal.fromInt(18)),
      Decimal.fromInt(5),
      reason: '18 km/h in m/s',
    );
    expectDecimalClose(
      factorUnitOf(UnitCategory.speed, 'knot').toBase(Decimal.fromInt(3600)),
      Decimal.fromInt(1852),
      reason: '3600 knots in m/s',
    );

    final Decimal pi = Decimal.parse(
      '3.14159265358979323846264338327950288419716939937510',
    );
    expectDecimalClose(
      factorUnitOf(UnitCategory.angle, 'degree').toBase(Decimal.fromInt(180)),
      pi,
      reason: '180 degrees in radians',
    );
    expectDecimalClose(
      factorUnitOf(UnitCategory.angle, 'gradian').toBase(Decimal.fromInt(200)),
      pi,
      reason: '200 gradians in radians',
    );
  });

  test('converts temperature through Kelvin', () {
    final Unit celsius = unitOf(UnitCategory.temperature, 'celsius');
    final Unit fahrenheit = unitOf(UnitCategory.temperature, 'fahrenheit');
    final Unit kelvin = unitOf(UnitCategory.temperature, 'kelvin');

    expect(celsius.toBase(Decimal.zero), Decimal.parse('273.15'));
    expect(celsius.toBase(Decimal.fromInt(100)), Decimal.parse('373.15'));
    expect(fahrenheit.toBase(Decimal.fromInt(32)), Decimal.parse('273.15'));
    expect(fahrenheit.toBase(Decimal.fromInt(212)), Decimal.parse('373.15'));
    expect(
      fahrenheit.toBase(Decimal.fromInt(-40)),
      celsius.toBase(Decimal.fromInt(-40)),
    );
    expect(kelvin.toBase(Decimal.parse('273.15')), Decimal.parse('273.15'));

    expect(celsius.fromBase(Decimal.parse('273.15')), Decimal.zero);
    expect(celsius.fromBase(Decimal.zero), Decimal.parse('-273.15'));
    expect(fahrenheit.fromBase(Decimal.parse('273.15')), Decimal.fromInt(32));
    expect(fahrenheit.fromBase(Decimal.parse('373.15')), Decimal.fromInt(212));
    expectDecimalClose(
      fahrenheit.fromBase(celsius.toBase(Decimal.fromInt(-40))),
      Decimal.fromInt(-40),
      reason: '-40 °C in °F',
    );
  });

  test('defines at most four popular units per category', () {
    expect(
      UnitCatalog.of(UnitCategory.length).popularUnits
          .map((Unit unit) => unit.id),
      <String>['m', 'ft', 'yd', 'nmi'],
    );
    for (final UnitCategoryData entry in UnitCatalog.categories) {
      expect(entry.popularUnits, isNotEmpty, reason: entry.category.label);
      expect(
        entry.popularUnits.length,
        lessThanOrEqualTo(4),
        reason: entry.category.label,
      );
    }
  });

  test('labels units the way the design shows them', () {
    expect(unitOf(UnitCategory.length, 'km').label, 'Kilometre (km)');
    expect(unitOf(UnitCategory.volume, 'gal_us').label, 'Gallon (US gal)');
    expect(unitOf(UnitCategory.time, 'day').label, 'Day');
    expect(unitOf(UnitCategory.area, 'marla').label, 'Marla');
  });

  test('looks units up by id and returns the catalog instance', () {
    expect(UnitCatalog.byId('km')?.name, 'Kilometre');
    expect(UnitCatalog.byId('gal_uk')?.symbol, 'UK gal');
    expect(UnitCatalog.byId('nope'), isNull);
    for (final Unit unit in UnitCatalog.all) {
      expect(UnitCatalog.byId(unit.id), same(unit));
    }
  });
}
