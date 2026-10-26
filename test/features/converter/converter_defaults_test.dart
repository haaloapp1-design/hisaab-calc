import 'package:calculator/core/units/unit_catalog.dart';
import 'package:calculator/features/converter/converter_defaults.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('opens Length on the screen 07 pair', () {
    final ({Unit from, Unit to}) pair = defaultUnits(UnitCategory.length);
    expect(pair.from.id, 'km');
    expect(pair.to.id, 'mi');
  });

  test('every category opens on two different units of the category', () {
    for (final UnitCategory category in UnitCategory.values) {
      final ({Unit from, Unit to}) pair = defaultUnits(category);
      final List<Unit> units = UnitCatalog.of(category).units;
      expect(units, contains(pair.from), reason: category.label);
      expect(units, contains(pair.to), reason: category.label);
      expect(pair.from.id, isNot(pair.to.id), reason: category.label);
    }
  });

  test('a unit opened from the hub search becomes From', () {
    final ({Unit from, Unit to}) pair = defaultUnits(
      UnitCategory.area,
      from: UnitCatalog.byId('marla'),
    );
    expect(pair.from.id, 'marla');
    expect(pair.to.id, 'ft2');
  });

  test('falls back when the searched unit is the preferred To unit', () {
    final ({Unit from, Unit to}) pair = defaultUnits(
      UnitCategory.area,
      from: UnitCatalog.byId('ft2'),
    );
    expect(pair.from.id, 'ft2');
    expect(pair.to.id, 'm2');
  });

  test('honours an explicit To unit and keeps the sides different', () {
    final ({Unit from, Unit to}) pair = defaultUnits(
      UnitCategory.length,
      to: UnitCatalog.byId('in'),
    );
    expect(pair.from.id, 'km');
    expect(pair.to.id, 'in');

    final ({Unit from, Unit to}) same = defaultUnits(
      UnitCategory.length,
      from: UnitCatalog.byId('mi'),
      to: UnitCatalog.byId('mi'),
    );
    expect(same.from.id, 'mi');
    expect(same.to.id, 'm');
  });
}
