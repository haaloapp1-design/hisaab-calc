import 'package:decimal/decimal.dart';

/// The WHO adult BMI bands (§14 BMI).
enum BmiCategory { underweight, normal, overweight, obese }

/// The English name of a [BmiCategory], used by the page.
extension BmiCategoryLabel on BmiCategory {
  String get label => switch (this) {
    BmiCategory.underweight => 'Underweight',
    BmiCategory.normal => 'Normal',
    BmiCategory.overweight => 'Overweight',
    BmiCategory.obese => 'Obese',
  };
}

/// The result of a BMI calculation.
final class BmiResult {
  const BmiResult({
    required this.bmi,
    required this.heightMeters,
    required this.weightKg,
    required this.category,
  });

  /// `weightKg / heightMeters²`, unrounded.
  final Decimal bmi;

  /// The height in metres after the unit conversion.
  final Decimal heightMeters;

  /// The weight in kilograms after the unit conversion.
  final Decimal weightKg;

  /// The WHO adult band for [bmi].
  final BmiCategory category;

  @override
  String toString() =>
      'BmiResult($bmi, ${category.label}, $heightMeters m, $weightKg kg)';
}

/// The BMI formulas of §14.
///
/// A height or weight that is zero or negative has no BMI, so the metric and
/// imperial entry points return null and the page shows a dash. They share one
/// `kg / m²` core.
abstract final class BmiCalculator {
  static final Decimal _hundred = Decimal.fromInt(100);
  static final Decimal _twelve = Decimal.fromInt(12);
  static final Decimal _inchMeters = Decimal.parse('0.0254');
  static final Decimal _poundKg = Decimal.parse('0.45359237');
  static final Decimal _underweightMax = Decimal.parse('18.5');
  static final Decimal _normalMax = Decimal.fromInt(25);
  static final Decimal _overweightMax = Decimal.fromInt(30);

  /// BMI from a height in centimetres and a weight in kilograms.
  static BmiResult? metric({
    required Decimal heightCm,
    required Decimal weightKg,
  }) {
    if (heightCm <= Decimal.zero || weightKg <= Decimal.zero) {
      return null;
    }
    return _result(_divide(heightCm, _hundred), weightKg);
  }

  /// BMI from feet + inches and a weight in pounds.
  static BmiResult? imperial({
    required Decimal feet,
    required Decimal inches,
    required Decimal pounds,
  }) {
    final Decimal totalInches = feet * _twelve + inches;
    if (feet < Decimal.zero ||
        inches < Decimal.zero ||
        totalInches <= Decimal.zero ||
        pounds <= Decimal.zero) {
      return null;
    }
    return _result(totalInches * _inchMeters, pounds * _poundKg);
  }

  /// The WHO adult band of [bmi]: < 18.5, < 25, < 30, else obese.
  static BmiCategory categoryFor(Decimal bmi) {
    if (bmi < _underweightMax) {
      return BmiCategory.underweight;
    }
    if (bmi < _normalMax) {
      return BmiCategory.normal;
    }
    if (bmi < _overweightMax) {
      return BmiCategory.overweight;
    }
    return BmiCategory.obese;
  }

  static BmiResult _result(Decimal meters, Decimal kg) {
    final Decimal bmi = _divide(kg, meters * meters);
    return BmiResult(
      bmi: bmi,
      heightMeters: meters,
      weightKg: kg,
      category: categoryFor(bmi),
    );
  }

  static Decimal _divide(Decimal a, Decimal b) =>
      (a / b).toDecimal(scaleOnInfinitePrecision: 32);
}
