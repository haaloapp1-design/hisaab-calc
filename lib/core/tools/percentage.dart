import 'package:decimal/decimal.dart';

/// Working scale for the percentage divisions.
const int _scale = 32;

/// The percentage formulas of BUSINESS_LOGIC §14.
///
/// The three modes share one calculator so the page only picks the mode and
/// formats the result. A zero denominator returns null instead of throwing:
/// the page shows a dash, and the user can keep typing.
abstract final class PercentageCalculator {
  /// `X% of Y = X × Y / 100`.
  static Decimal of({required Decimal percent, required Decimal value}) =>
      _divide(percent * value, _hundred);

  /// `X is what % of Y = X / Y × 100`; null when [whole] is zero.
  static Decimal? ratio({required Decimal part, required Decimal whole}) =>
      whole == Decimal.zero ? null : _divide(part * _hundred, whole);

  /// `% change = (Y − X) / X × 100`; null when [from] is zero.
  static Decimal? change({required Decimal from, required Decimal to}) =>
      from == Decimal.zero ? null : _divide((to - from) * _hundred, from);

  static final Decimal _hundred = Decimal.fromInt(100);

  static Decimal _divide(Decimal a, Decimal b) =>
      (a / b).toDecimal(scaleOnInfinitePrecision: _scale);
}
