import 'package:decimal/decimal.dart';

/// Working scale for the tip divisions.
const int _scale = 32;

/// The result of a bill split (BUSINESS_LOGIC §14).
final class TipResult {
  const TipResult({
    required this.bill,
    required this.tipPercent,
    required this.people,
    required this.tip,
    required this.total,
    required this.perPerson,
    required this.roundedPerPerson,
  });

  /// The bill before the tip.
  final Decimal bill;

  /// The tip percentage.
  final Decimal tipPercent;

  /// The number of people sharing the bill; at least one.
  final int people;

  /// `bill × tipPercent / 100`.
  final Decimal tip;

  /// `bill + tip`.
  final Decimal total;

  /// `total / people`, unrounded.
  final Decimal perPerson;

  /// [perPerson] rounded up to the next whole currency unit.
  final Decimal roundedPerPerson;

  @override
  String toString() =>
      'TipResult(tip: $tip, total: $total, perPerson: $perPerson, '
      'roundedPerPerson: $roundedPerPerson)';
}

/// The tip / split formulas of BUSINESS_LOGIC §14.
///
/// Negative bills or tips and fewer than one person are programming errors;
/// the page clamps the people field before calling.
abstract final class TipCalculator {
  /// Calculates the tip, the total and the two per-person values.
  static TipResult calculate({
    required Decimal bill,
    required Decimal tipPercent,
    required int people,
  }) {
    if (bill < Decimal.zero) {
      throw ArgumentError.value(bill, 'bill', 'must not be negative');
    }
    if (tipPercent < Decimal.zero) {
      throw ArgumentError.value(
        tipPercent,
        'tipPercent',
        'must not be negative',
      );
    }
    if (people < 1) {
      throw ArgumentError.value(people, 'people', 'must be at least 1');
    }

    final Decimal tip = _divide(bill * tipPercent, _hundred);
    final Decimal total = bill + tip;
    final Decimal perPerson = _divide(total, Decimal.fromInt(people));

    return TipResult(
      bill: bill,
      tipPercent: tipPercent,
      people: people,
      tip: tip,
      total: total,
      perPerson: perPerson,
      roundedPerPerson: perPerson.ceil(),
    );
  }

  static final Decimal _hundred = Decimal.fromInt(100);

  static Decimal _divide(Decimal a, Decimal b) =>
      (a / b).toDecimal(scaleOnInfinitePrecision: _scale);
}
