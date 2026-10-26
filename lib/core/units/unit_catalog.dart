import 'package:decimal/decimal.dart';

import 'unit.dart';

export 'unit.dart';

/// Every converter unit and its factor (BUSINESS_LOGIC §12, SPEC §4).
///
/// Factors are decimal text so the data stays `const`. Values that repeat
/// (`1/3.6`, `π/180`) are written out to 40+ significant digits; conversions
/// display six significant digits, so the rounding is far below the display
/// precision. Temperature is not a factor: it uses Kelvin formulas.
abstract final class UnitCatalog {
  /// The categories and units, in hub order.
  static const List<UnitCategoryData> categories = <UnitCategoryData>[
    UnitCategoryData(UnitCategory.length, <Unit>[
      FactorUnit('mm', 'Millimetre', 'mm', '0.001'),
      FactorUnit('cm', 'Centimetre', 'cm', '0.01'),
      FactorUnit('m', 'Metre', 'm', '1', popular: true),
      FactorUnit('km', 'Kilometre', 'km', '1000'),
      FactorUnit('in', 'Inch', 'in', '0.0254'),
      FactorUnit('ft', 'Foot', 'ft', '0.3048', popular: true),
      FactorUnit('yd', 'Yard', 'yd', '0.9144', popular: true),
      FactorUnit('mi', 'Mile', 'mi', '1609.344'),
      FactorUnit('nmi', 'Nautical mile', 'nmi', '1852', popular: true),
    ]),
    UnitCategoryData(UnitCategory.area, <Unit>[
      FactorUnit('mm2', 'Square millimetre', 'mm²', '0.000001'),
      FactorUnit('cm2', 'Square centimetre', 'cm²', '0.0001'),
      FactorUnit('m2', 'Square metre', 'm²', '1', popular: true),
      FactorUnit('hectare', 'Hectare', 'ha', '10000'),
      FactorUnit('km2', 'Square kilometre', 'km²', '1000000'),
      FactorUnit('in2', 'Square inch', 'in²', '0.00064516'),
      FactorUnit('ft2', 'Square foot', 'ft²', '0.09290304', popular: true),
      FactorUnit('yd2', 'Square yard', 'yd²', '0.83612736'),
      FactorUnit('acre', 'Acre', 'acre', '4046.8564224', popular: true),
      FactorUnit('marla', 'Marla', 'marla', '25.29285264'),
      FactorUnit('kanal', 'Kanal', 'kanal', '505.8570528', popular: true),
    ]),
    UnitCategoryData(UnitCategory.volume, <Unit>[
      FactorUnit('ml', 'Millilitre', 'mL', '0.001', popular: true),
      FactorUnit('l', 'Litre', 'L', '1', popular: true),
      FactorUnit('m3', 'Cubic metre', 'm³', '1000'),
      FactorUnit('tsp', 'Teaspoon', 'tsp', '0.00492892159375'),
      FactorUnit('tbsp', 'Tablespoon', 'tbsp', '0.01478676478125'),
      FactorUnit('cup_us', 'Cup', 'US cup', '0.2365882365', popular: true),
      FactorUnit('floz_us', 'Fluid ounce', 'US fl oz', '0.0295735295625'),
      FactorUnit('gal_us', 'Gallon', 'US gal', '3.785411784', popular: true),
      FactorUnit('gal_uk', 'Gallon', 'UK gal', '4.54609'),
    ]),
    UnitCategoryData(UnitCategory.mass, <Unit>[
      FactorUnit('mg', 'Milligram', 'mg', '0.000001'),
      FactorUnit('g', 'Gram', 'g', '0.001', popular: true),
      FactorUnit('kg', 'Kilogram', 'kg', '1', popular: true),
      FactorUnit('tonne', 'Tonne', 't', '1000'),
      FactorUnit('oz', 'Ounce', 'oz', '0.028349523125', popular: true),
      FactorUnit('lb', 'Pound', 'lb', '0.45359237', popular: true),
      FactorUnit('stone', 'Stone', 'st', '6.35029318'),
      FactorUnit('tola', 'Tola', 'tola', '0.0116638038'),
      FactorUnit('maund', 'Maund', 'maund', '37.3242'),
    ]),
    UnitCategoryData(UnitCategory.temperature, <Unit>[
      TemperatureUnit(
        'celsius',
        'Celsius',
        '°C',
        toKelvin: _celsiusToKelvin,
        fromKelvin: _kelvinToCelsius,
        popular: true,
      ),
      TemperatureUnit(
        'fahrenheit',
        'Fahrenheit',
        '°F',
        toKelvin: _fahrenheitToKelvin,
        fromKelvin: _kelvinToFahrenheit,
        popular: true,
      ),
      TemperatureUnit(
        'kelvin',
        'Kelvin',
        'K',
        toKelvin: _identity,
        fromKelvin: _identity,
        popular: true,
      ),
    ]),
    UnitCategoryData(UnitCategory.speed, <Unit>[
      FactorUnit('mps', 'Metre per second', 'm/s', '1', popular: true),
      FactorUnit(
        'kmh',
        'Kilometre per hour',
        'km/h',
        '0.2777777777777777777777777777777777777778',
        popular: true,
      ),
      FactorUnit('mph', 'Mile per hour', 'mph', '0.44704', popular: true),
      FactorUnit(
        'knot',
        'Knot',
        'knot',
        '0.5144444444444444444444444444444444444444',
        popular: true,
      ),
    ]),
    UnitCategoryData(UnitCategory.time, <Unit>[
      FactorUnit('ms', 'Millisecond', 'ms', '0.001'),
      FactorUnit('s', 'Second', 's', '1', popular: true),
      FactorUnit('min', 'Minute', 'min', '60', popular: true),
      FactorUnit('h', 'Hour', 'h', '3600', popular: true),
      FactorUnit('day', 'Day', 'day', '86400', popular: true),
      FactorUnit('week', 'Week', 'week', '604800'),
      FactorUnit('year', 'Year', 'year', '31536000'),
    ]),
    UnitCategoryData(UnitCategory.data, <Unit>[
      FactorUnit('bit', 'Bit', 'bit', '0.125'),
      FactorUnit('byte', 'Byte', 'B', '1', popular: true),
      FactorUnit('kb', 'Kilobyte', 'KB', '1000', popular: true),
      FactorUnit('mb', 'Megabyte', 'MB', '1000000', popular: true),
      FactorUnit('gb', 'Gigabyte', 'GB', '1000000000', popular: true),
      FactorUnit('tb', 'Terabyte', 'TB', '1000000000000'),
      FactorUnit('kib', 'Kibibyte', 'KiB', '1024'),
      FactorUnit('mib', 'Mebibyte', 'MiB', '1048576'),
      FactorUnit('gib', 'Gibibyte', 'GiB', '1073741824'),
    ]),
    UnitCategoryData(UnitCategory.pressure, <Unit>[
      FactorUnit('pa', 'Pascal', 'Pa', '1', popular: true),
      FactorUnit('kpa', 'Kilopascal', 'kPa', '1000', popular: true),
      FactorUnit('bar', 'Bar', 'bar', '100000', popular: true),
      FactorUnit(
        'psi',
        'Pound per square inch',
        'psi',
        '6894.757293168',
        popular: true,
      ),
      FactorUnit('atm', 'Atmosphere', 'atm', '101325'),
      FactorUnit('mmhg', 'Millimetre of mercury', 'mmHg', '133.322387415'),
    ]),
    UnitCategoryData(UnitCategory.energy, <Unit>[
      FactorUnit('j', 'Joule', 'J', '1', popular: true),
      FactorUnit('kj', 'Kilojoule', 'kJ', '1000', popular: true),
      FactorUnit('cal', 'Calorie', 'cal', '4.184', popular: true),
      FactorUnit('kcal', 'Kilocalorie', 'kcal', '4184', popular: true),
      FactorUnit('wh', 'Watt-hour', 'Wh', '3600'),
      FactorUnit('kwh', 'Kilowatt-hour', 'kWh', '3600000'),
    ]),
    UnitCategoryData(UnitCategory.power, <Unit>[
      FactorUnit('w', 'Watt', 'W', '1', popular: true),
      FactorUnit('kw', 'Kilowatt', 'kW', '1000', popular: true),
      FactorUnit('hp', 'Horsepower', 'hp', '745.69987158227', popular: true),
    ]),
    UnitCategoryData(UnitCategory.angle, <Unit>[
      FactorUnit(
        'degree',
        'Degree',
        '°',
        '0.017453292519943295769236907684886127134428718885417',
        popular: true,
      ),
      FactorUnit('radian', 'Radian', 'rad', '1', popular: true),
      FactorUnit(
        'gradian',
        'Gradian',
        'grad',
        '0.0157079632679489661923132169163975144209858469968755',
        popular: true,
      ),
    ]),
  ];

  /// Every unit in the catalog, in hub order.
  static Iterable<Unit> get all =>
      categories.expand((UnitCategoryData entry) => entry.units);

  /// The category data for [category].
  static UnitCategoryData of(UnitCategory category) => categories.firstWhere(
    (UnitCategoryData entry) => entry.category == category,
  );

  /// The unit with [id], or null when the saved id is unknown.
  static Unit? byId(String id) {
    for (final UnitCategoryData entry in categories) {
      for (final Unit unit in entry.units) {
        if (unit.id == id) {
          return unit;
        }
      }
    }
    return null;
  }

  /// Every unit whose name or symbol contains [query], in catalog order.
  ///
  /// The hub search is a plain, case-insensitive substring match, so `inch`
  /// finds both `Inch` and `Square inch`. A blank query matches nothing.
  static List<UnitMatch> search(String query) {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return const <UnitMatch>[];
    }
    final List<UnitMatch> matches = <UnitMatch>[];
    for (final UnitCategoryData entry in categories) {
      for (final Unit unit in entry.units) {
        if (unit.name.toLowerCase().contains(needle) ||
            unit.symbol.toLowerCase().contains(needle)) {
          matches.add(UnitMatch(entry.category, unit));
        }
      }
    }
    return matches;
  }
}

/// One result of [UnitCatalog.search]: the unit and the category it belongs to.
final class UnitMatch {
  const UnitMatch(this.category, this.unit);

  final UnitCategory category;
  final Unit unit;

  @override
  String toString() => '${category.label}/${unit.id}';
}

final Decimal _kelvinOffset = Decimal.parse('273.15');
final Decimal _five = Decimal.fromInt(5);
final Decimal _nine = Decimal.fromInt(9);
final Decimal _thirtyTwo = Decimal.fromInt(32);

Decimal _celsiusToKelvin(Decimal celsius) => celsius + _kelvinOffset;

Decimal _kelvinToCelsius(Decimal kelvin) => kelvin - _kelvinOffset;

Decimal _fahrenheitToKelvin(Decimal fahrenheit) =>
    ((fahrenheit - _thirtyTwo) * _five / _nine).toDecimal(
      scaleOnInfinitePrecision: 32,
    ) +
    _kelvinOffset;

Decimal _kelvinToFahrenheit(Decimal kelvin) =>
    ((kelvin - _kelvinOffset) * _nine / _five).toDecimal(
      scaleOnInfinitePrecision: 32,
    ) +
    _thirtyTwo;

Decimal _identity(Decimal value) => value;
