import 'package:calculator/core/engine/formatter.dart';
import 'package:calculator/core/units/converter.dart';
import 'package:calculator/core/units/unit_catalog.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

Unit unitOf(UnitCategory category, String id) =>
    UnitCatalog.of(category).units.firstWhere((Unit unit) => unit.id == id);

Decimal convertValue(
  Decimal value,
  UnitCategory category,
  String from,
  String to,
) {
  final ConversionResult result = UnitConverter.convert(
    value,
    category: category,
    from: unitOf(category, from),
    to: unitOf(category, to),
  );
  expect(result, isA<ConversionSuccess>(), reason: '$from → $to');
  return (result as ConversionSuccess).value;
}

ConversionResult convertResult(
  Decimal value,
  UnitCategory category,
  String from,
  String to,
) => UnitConverter.convert(
  value,
  category: category,
  from: unitOf(category, from),
  to: unitOf(category, to),
);

String rule(
  UnitCategory category,
  String from,
  String to, {
  NumberFormatOptions options = const NumberFormatOptions(),
}) => UnitConverter.ruleLine(
  category: category,
  from: unitOf(category, from),
  to: unitOf(category, to),
  options: options,
);

List<String> alsoIds(
  UnitCategory category,
  String from,
  String to, {
  int count = 4,
}) => UnitConverter.isAlso(
  category: category,
  from: unitOf(category, from),
  to: unitOf(category, to),
  count: count,
).map((Unit unit) => unit.id).toList();

void expectDecimalClose(Decimal actual, Decimal expected, {String? reason}) {
  expect(
    (actual - expected).abs() <= Decimal.parse('1e-12'),
    isTrue,
    reason: '${reason ?? 'value'}: $actual != $expected',
  );
}

void main() {
  test('converts 5 km to 3.10686 mi', () {
    final Decimal value = convertValue(
      Decimal.fromInt(5),
      UnitCategory.length,
      'km',
      'mi',
    );
    expect(formatConversionValue(value), '3.10686');
    expectDecimalClose(value, Decimal.parse('3.10685596118667'));
  });

  test('converts the §12 temperature acceptance cases', () {
    expect(
      convertValue(
        Decimal.fromInt(100),
        UnitCategory.temperature,
        'celsius',
        'fahrenheit',
      ),
      Decimal.fromInt(212),
    );
    expect(
      convertValue(
        Decimal.fromInt(-40),
        UnitCategory.temperature,
        'celsius',
        'fahrenheit',
      ),
      Decimal.fromInt(-40),
    );
    expect(
      convertValue(
        Decimal.fromInt(32),
        UnitCategory.temperature,
        'fahrenheit',
        'celsius',
      ),
      Decimal.zero,
    );
    expect(
      convertValue(Decimal.zero, UnitCategory.temperature, 'kelvin', 'celsius'),
      Decimal.parse('-273.15'),
    );
    expect(
      convertValue(
        Decimal.parse('273.15'),
        UnitCategory.temperature,
        'kelvin',
        'fahrenheit',
      ),
      Decimal.fromInt(32),
    );
  });

  test('rejects temperatures below absolute zero', () {
    expect(
      convertResult(
        Decimal.fromInt(-300),
        UnitCategory.temperature,
        'celsius',
        'fahrenheit',
      ),
      const ConversionFailure(ConversionError.belowAbsoluteZero),
    );
    expect(
      convertResult(
        Decimal.fromInt(-1),
        UnitCategory.temperature,
        'kelvin',
        'celsius',
      ),
      const ConversionFailure(ConversionError.belowAbsoluteZero),
    );
    expect(
      convertResult(
        Decimal.fromInt(-500),
        UnitCategory.temperature,
        'fahrenheit',
        'kelvin',
      ),
      const ConversionFailure(ConversionError.belowAbsoluteZero),
    );
    expect(ConversionError.belowAbsoluteZero.message, 'Below absolute zero');
  });

  test('accepts exactly 0 K and the matching Celsius/Fahrenheit values', () {
    expect(
      convertResult(
        Decimal.parse('-273.15'),
        UnitCategory.temperature,
        'celsius',
        'kelvin',
      ),
      ConversionSuccess(Decimal.zero),
    );
    expect(
      convertResult(
        Decimal.parse('-459.67'),
        UnitCategory.temperature,
        'fahrenheit',
        'kelvin',
      ),
      ConversionSuccess(Decimal.zero),
    );
    expect(
      convertResult(
        Decimal.parse('-273.16'),
        UnitCategory.temperature,
        'celsius',
        'kelvin',
      ),
      const ConversionFailure(ConversionError.belowAbsoluteZero),
    );
    expect(
      convertResult(
        Decimal.parse('-459.68'),
        UnitCategory.temperature,
        'fahrenheit',
        'kelvin',
      ),
      const ConversionFailure(ConversionError.belowAbsoluteZero),
    );
  });

  test('converts the §12 factors', () {
    expect(
      convertValue(Decimal.one, UnitCategory.length, 'mi', 'km'),
      Decimal.parse('1.609344'),
    );
    expect(
      convertValue(Decimal.one, UnitCategory.mass, 'kg', 'g'),
      Decimal.fromInt(1000),
    );
    expect(
      formatConversionValue(
        convertValue(Decimal.one, UnitCategory.mass, 'kg', 'lb'),
      ),
      '2.20462',
    );
    expect(
      formatConversionValue(
        convertValue(Decimal.one, UnitCategory.volume, 'l', 'gal_us'),
      ),
      '0.264172',
    );
    expect(
      convertValue(Decimal.one, UnitCategory.area, 'acre', 'm2'),
      Decimal.parse('4046.8564224'),
    );
    expect(
      convertValue(Decimal.one, UnitCategory.area, 'marla', 'ft2'),
      Decimal.parse('272.25'),
    );
    expect(
      convertValue(Decimal.one, UnitCategory.area, 'kanal', 'marla'),
      Decimal.fromInt(20),
    );
    expect(
      convertValue(Decimal.one, UnitCategory.data, 'tb', 'bit'),
      Decimal.parse('8000000000000'),
    );
    expect(
      convertValue(Decimal.one, UnitCategory.data, 'kib', 'byte'),
      Decimal.fromInt(1024),
    );
    expect(
      convertValue(Decimal.one, UnitCategory.power, 'hp', 'w'),
      Decimal.parse('745.69987158227'),
    );
    expect(
      convertValue(Decimal.one, UnitCategory.time, 'year', 'day'),
      Decimal.fromInt(365),
    );
    expect(
      formatConversionValue(
        convertValue(
          Decimal.fromInt(180),
          UnitCategory.angle,
          'degree',
          'radian',
        ),
      ),
      '3.14159',
    );
    expect(
      formatConversionValue(
        convertValue(Decimal.one, UnitCategory.speed, 'knot', 'kmh'),
      ),
      '1.852',
    );
  });

  test('converts the same unit, zero and negative factor values', () {
    expect(
      convertValue(Decimal.fromInt(5), UnitCategory.length, 'km', 'km'),
      Decimal.fromInt(5),
    );
    expect(
      convertValue(Decimal.zero, UnitCategory.length, 'km', 'mi'),
      Decimal.zero,
    );
    expect(
      convertValue(Decimal.parse('1.1'), UnitCategory.length, 'km', 'm'),
      Decimal.fromInt(1100),
    );
    final Decimal negative = convertValue(
      Decimal.fromInt(-5),
      UnitCategory.length,
      'km',
      'm',
    );
    expect(negative, Decimal.fromInt(-5000));
    expect(formatConversionValue(negative), '−5,000');
  });

  test('builds the rule line with six significant digits', () {
    expect(rule(UnitCategory.length, 'km', 'mi'), '1 km = 0.621371 mi');
    // §12 says six significant digits, even though screen 07's static mock
    // prints the exact seven-digit factor for the reverse pair.
    expect(rule(UnitCategory.length, 'mi', 'km'), '1 mi = 1.60934 km');
    expect(
      rule(UnitCategory.temperature, 'celsius', 'fahrenheit'),
      '1 °C = 33.8 °F',
    );
    expect(rule(UnitCategory.mass, 'kg', 'lb'), '1 kg = 2.20462 lb');
    expect(rule(UnitCategory.data, 'kb', 'byte'), '1 KB = 1,000 B');
    expect(rule(UnitCategory.time, 'year', 'day'), '1 year = 365 day');
    expect(
      rule(
        UnitCategory.length,
        'km',
        'mi',
        options: const NumberFormatOptions(
          decimalSeparator: ',',
          groupSeparator: '.',
        ),
      ),
      '1 km = 0,621371 mi',
    );
  });

  test('formats converted values with six significant digits', () {
    expect(
      formatConversionValue(Decimal.parse('16404.1994750656')),
      '16,404.2',
    );
    expect(formatConversionValue(Decimal.parse('5468.0664916885')), '5,468.07');
    expect(formatConversionValue(Decimal.parse('2.6997840172786')), '2.69978');
    expect(formatConversionValue(Decimal.parse('-273.15')), '−273.15');
    expect(formatConversionValue(Decimal.zero), '0');
    expect(formatConversionValue(Decimal.parse('212.000')), '212');
    expect(
      formatConversionValue(Decimal.parse('0.000000000000125')),
      '0.000000000000125',
    );
    expect(
      formatConversionValue(Decimal.parse('8000000000000')),
      '8,000,000,000,000',
    );
    expect(
      formatConversionValue(
        Decimal.parse('16404.199'),
        options: const NumberFormatOptions(useGrouping: false),
      ),
      '16404.2',
    );
    expect(
      formatConversionValue(
        Decimal.parse('16404.199'),
        options: const NumberFormatOptions(
          decimalSeparator: ',',
          groupSeparator: '.',
        ),
      ),
      '16.404,2',
    );
  });

  test('picks four popular "is also" units without the pair', () {
    expect(alsoIds(UnitCategory.length, 'km', 'mi'), <String>[
      'm',
      'ft',
      'yd',
      'nmi',
    ]);
    expect(alsoIds(UnitCategory.length, 'm', 'ft'), <String>[
      'yd',
      'nmi',
      'mm',
      'cm',
    ]);
    expect(alsoIds(UnitCategory.temperature, 'celsius', 'fahrenheit'), <String>[
      'kelvin',
    ]);
    expect(alsoIds(UnitCategory.power, 'w', 'kw'), <String>['hp']);
    expect(alsoIds(UnitCategory.length, 'km', 'mi', count: 2), <String>[
      'm',
      'ft',
    ]);
    expect(alsoIds(UnitCategory.length, 'km', 'mi', count: 0), isEmpty);
  });

  test('is-also never repeats the pair or a unit', () {
    for (final UnitCategoryData entry in UnitCatalog.categories) {
      for (final Unit from in entry.units) {
        for (final Unit to in entry.units) {
          if (from.id == to.id) {
            continue;
          }
          final List<Unit> also = UnitConverter.isAlso(
            category: entry.category,
            from: from,
            to: to,
          );
          expect(
            also.any((Unit unit) => unit.id == from.id || unit.id == to.id),
            isFalse,
            reason: '${entry.category.label} ${from.id} → ${to.id}',
          );
          expect(
            also.map((Unit unit) => unit.id).toSet(),
            hasLength(also.length),
            reason: '${entry.category.label} ${from.id} → ${to.id}',
          );
          expect(also.length, lessThanOrEqualTo(4));
        }
      }
    }
  });

  test('conversion results compare by value', () {
    expect(ConversionSuccess(Decimal.one), ConversionSuccess(Decimal.one));
    expect(
      const ConversionFailure(ConversionError.belowAbsoluteZero),
      const ConversionFailure(ConversionError.belowAbsoluteZero),
    );
    expect(
      ConversionSuccess(Decimal.one) ==
          const ConversionFailure(ConversionError.belowAbsoluteZero),
      isFalse,
    );
    expect(ConversionSuccess(Decimal.one).toString(), 'ConversionSuccess(1)');
    expect(
      const ConversionFailure(ConversionError.belowAbsoluteZero).toString(),
      'ConversionFailure(belowAbsoluteZero)',
    );
  });
}
