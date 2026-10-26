import 'package:decimal/decimal.dart';

/// The converter categories, in the order the hub shows them (SPEC §4).
enum UnitCategory {
  length('Length', 'm', 'm'),
  area('Area', 'm²', 'm²'),
  volume('Volume', 'L', 'L'),
  mass('Mass', 'kg', 'kg'),
  temperature('Temperature', 'K', '°C'),
  speed('Speed', 'm/s', 'km/h'),
  time('Time', 's', 'h'),
  data('Data', 'B', 'MB'),
  pressure('Pressure', 'Pa', 'Pa'),
  energy('Energy', 'J', 'J'),
  power('Power', 'W', 'W'),
  angle('Angle', 'rad', 'rad');

  const UnitCategory(this.label, this.baseSymbol, this.hubSymbol);

  /// The hub and picker name, e.g. `Length`.
  final String label;

  /// The symbol of the category's base unit (BUSINESS_LOGIC §12).
  final String baseSymbol;

  /// The chip on the converter hub (`06-converter-hub.html`): a familiar unit
  /// rather than the base, e.g. `°C` for temperature.
  final String hubSymbol;
}

/// One unit of measure (BUSINESS_LOGIC §12).
///
/// Every unit converts to and from its category's base unit: [FactorUnit] uses
/// a factor and [TemperatureUnit] the Kelvin formulas. This is pure Dart, so
/// the converter logic and its tests share exactly the same code.
sealed class Unit {
  const Unit(this.id, this.name, this.symbol, {this.popular = false});

  /// Stable id for saved pairs and history (`km`, `marla`, `gal_us`).
  final String id;

  /// The long name a picker shows, e.g. `Kilometre`.
  final String name;

  /// The short form used in cards and rule lines, e.g. `km`.
  final String symbol;

  /// One of the "is also" units of its category (§12); only a hint.
  final bool popular;

  /// The picker label: `Kilometre (km)`, or just the name when it repeats.
  String get label =>
      name.toLowerCase() == symbol.toLowerCase() ? name : '$name ($symbol)';

  /// [value] in the category's base unit.
  Decimal toBase(Decimal value);

  /// A base-unit [value] in this unit.
  Decimal fromBase(Decimal value);
}

/// A unit defined by its factor to the category's base unit (§12).
final class FactorUnit extends Unit {
  const FactorUnit(
    super.id,
    super.name,
    super.symbol,
    this.factorText, {
    super.popular,
  });

  /// The factor as decimal text: [Decimal] is not const, so the catalog is.
  final String factorText;

  /// `valueInBase = v × factor`.
  Decimal get factor => Decimal.parse(factorText);

  @override
  Decimal toBase(Decimal value) => value * factor;

  @override
  Decimal fromBase(Decimal value) =>
      (value / factor).toDecimal(scaleOnInfinitePrecision: 32);
}

/// A temperature scale, converted through Kelvin with formulas (§12).
final class TemperatureUnit extends Unit {
  const TemperatureUnit(
    super.id,
    super.name,
    super.symbol, {
    required this.toKelvin,
    required this.fromKelvin,
    super.popular,
  });

  /// `K = toKelvin(v)`.
  final Decimal Function(Decimal) toKelvin;

  /// `v = fromKelvin(K)`.
  final Decimal Function(Decimal) fromKelvin;

  @override
  Decimal toBase(Decimal value) => toKelvin(value);

  @override
  Decimal fromBase(Decimal value) => fromKelvin(value);
}

/// One hub category with its units, in picker order.
final class UnitCategoryData {
  const UnitCategoryData(this.category, this.units);

  final UnitCategory category;
  final List<Unit> units;

  /// The "is also" hints (§12), at most four per category.
  List<Unit> get popularUnits =>
      units.where((Unit unit) => unit.popular).toList(growable: false);
}
