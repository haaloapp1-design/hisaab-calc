import 'package:decimal/decimal.dart';

import '../engine/formatter.dart';
import 'unit_catalog.dart';

/// The outcome of a unit conversion (BUSINESS_LOGIC §12).
sealed class ConversionResult {
  const ConversionResult();
}

/// A successful conversion.
final class ConversionSuccess extends ConversionResult {
  const ConversionSuccess(this.value);

  final Decimal value;

  @override
  bool operator ==(Object other) =>
      other is ConversionSuccess && other.value == value;

  @override
  int get hashCode => Object.hash(ConversionSuccess, value);

  @override
  String toString() => 'ConversionSuccess($value)';
}

/// A failed conversion.
final class ConversionFailure extends ConversionResult {
  const ConversionFailure(this.error);

  final ConversionError error;

  @override
  bool operator ==(Object other) =>
      other is ConversionFailure && other.error == error;

  @override
  int get hashCode => Object.hash(ConversionFailure, error);

  @override
  String toString() => 'ConversionFailure(${error.name})';
}

/// Every error a conversion can report.
enum ConversionError {
  belowAbsoluteZero('Below absolute zero');

  const ConversionError(this.message);

  /// The text the To card shows (BUSINESS_LOGIC §12).
  final String message;
}

/// The conversion rules of BUSINESS_LOGIC §12.
///
/// `valueInBase = v × factor` and `result = valueInBase / factorTo`, in
/// [Decimal]. Temperature is not a factor: it goes through Kelvin, and a
/// temperature below 0 K is the "Below absolute zero" error.
abstract final class UnitConverter {
  /// Converts [value] from [from] to [to] inside [category].
  static ConversionResult convert(
    Decimal value, {
    required UnitCategory category,
    required Unit from,
    required Unit to,
  }) {
    _checkUnits(category, from, to);
    final Decimal base = from.toBase(value);
    if (category == UnitCategory.temperature && base < Decimal.zero) {
      return const ConversionFailure(ConversionError.belowAbsoluteZero);
    }
    return ConversionSuccess(to.fromBase(base));
  }

  /// The rule under the cards: `1 km = 0.621371 mi` (§12, 6 significant digits).
  ///
  /// One of any unit is always above absolute zero, so this cannot fail.
  static String ruleLine({
    required UnitCategory category,
    required Unit from,
    required Unit to,
    NumberFormatOptions options = const NumberFormatOptions(),
  }) {
    _checkUnits(category, from, to);
    final Decimal converted = to.fromBase(from.toBase(Decimal.one));
    return '1 ${from.symbol} = '
        '${formatConversionValue(converted, options: options)} ${to.symbol}';
  }

  /// The "is also" units: four popular units, excluding [from] and [to] (§12).
  ///
  /// When excluding the pair leaves fewer than [count] popular units, the rest
  /// of the category fills the list in catalog order. A category with fewer
  /// than [count] + 2 units returns everything it has.
  static List<Unit> isAlso({
    required UnitCategory category,
    required Unit from,
    required Unit to,
    int count = 4,
  }) {
    final UnitCategoryData data = _checkUnits(category, from, to);
    if (count <= 0) {
      return const <Unit>[];
    }

    final List<Unit> chosen = <Unit>[];
    void add(Unit unit) {
      if (unit.id == from.id ||
          unit.id == to.id ||
          chosen.any((Unit other) => other.id == unit.id)) {
        return;
      }
      chosen.add(unit);
    }

    for (final Unit unit in data.popularUnits) {
      add(unit);
      if (chosen.length >= count) {
        return chosen;
      }
    }
    for (final Unit unit in data.units) {
      add(unit);
      if (chosen.length >= count) {
        return chosen;
      }
    }
    return chosen;
  }
}

/// Formats a converted value with the six significant digits of §12.
///
/// Grouping, the decimal mark and the typographic `−` follow [options], like
/// the rest of the app's numbers. Trailing zeros are dropped (`212`, not
/// `212.000`), which is what the screen 07 values show.
String formatConversionValue(
  Decimal value, {
  NumberFormatOptions options = const NumberFormatOptions(),
}) {
  final Decimal rounded = Decimal.parse(value.toStringAsPrecision(6));
  final Decimal magnitude = rounded.abs();
  final String raw = magnitude.toString();
  final int dot = raw.indexOf('.');
  final String integerPart = dot == -1 ? raw : raw.substring(0, dot);
  final String fraction = dot == -1 ? '' : raw.substring(dot + 1);
  final String integer = options.useGrouping
      ? groupDigits(integerPart, separator: options.groupSeparator)
      : integerPart;
  final String body = dot == -1
      ? integer
      : '$integer${options.decimalSeparator}$fraction';
  return rounded < Decimal.zero ? '−$body' : body;
}

/// Resolves [category] and makes sure both units belong to it.
UnitCategoryData _checkUnits(UnitCategory category, Unit from, Unit to) {
  final UnitCategoryData data = UnitCatalog.of(category);
  assert(
    data.units.contains(from),
    'from ${from.id} does not belong to ${category.label}',
  );
  assert(
    data.units.contains(to),
    'to ${to.id} does not belong to ${category.label}',
  );
  return data;
}
