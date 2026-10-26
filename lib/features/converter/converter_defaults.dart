import '../../core/units/unit_catalog.dart';

/// The pair each category opens with, by unit id (screen 07 shows km → mi).
///
/// It is a UI choice, not catalog data: the first visit to a category starts
/// with two familiar units, and a unit opened from the hub search becomes the
/// From side.
const Map<UnitCategory, List<String>> _defaultPairs =
    <UnitCategory, List<String>>{
      UnitCategory.length: <String>['km', 'mi'],
      UnitCategory.area: <String>['m2', 'ft2'],
      UnitCategory.volume: <String>['l', 'gal_us'],
      UnitCategory.mass: <String>['kg', 'lb'],
      UnitCategory.temperature: <String>['celsius', 'fahrenheit'],
      UnitCategory.speed: <String>['kmh', 'mph'],
      UnitCategory.time: <String>['h', 'min'],
      UnitCategory.data: <String>['mb', 'gb'],
      UnitCategory.pressure: <String>['bar', 'psi'],
      UnitCategory.energy: <String>['kcal', 'kj'],
      UnitCategory.power: <String>['kw', 'hp'],
      UnitCategory.angle: <String>['degree', 'radian'],
    };

/// The From/To pair for [category], honouring an already chosen [from]/[to].
///
/// When [from] equals the preferred To unit (a unit opened from the hub
/// search), To falls back to the other default and then to the category's
/// first popular unit, so the two sides are never the same.
({Unit from, Unit to}) defaultUnits(
  UnitCategory category, {
  Unit? from,
  Unit? to,
}) {
  final UnitCategoryData data = UnitCatalog.of(category);
  final List<String> ids = _defaultPairs[category]!;
  final Unit preferredFrom = _byId(data, ids[0]);
  final Unit preferredTo = _byId(data, ids[1]);
  final Unit chosenFrom = from ?? preferredFrom;
  final Unit chosenTo = to != null && to.id != chosenFrom.id
      ? to
      : _other(data, chosenFrom, preferredTo);
  return (from: chosenFrom, to: chosenTo);
}

Unit _byId(UnitCategoryData data, String id) =>
    data.units.firstWhere((Unit unit) => unit.id == id);

Unit _other(UnitCategoryData data, Unit from, Unit preferred) {
  if (preferred.id != from.id) {
    return preferred;
  }
  for (final Unit unit in data.popularUnits) {
    if (unit.id != from.id) {
      return unit;
    }
  }
  return data.units.firstWhere((Unit unit) => unit.id != from.id);
}
