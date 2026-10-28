import 'package:calculator/core/tools/bmi.dart';
import 'package:calculator/core/tools/tool_format.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Decimal d(String source) => Decimal.parse(source);

  test('170 cm and 70 kg is 24.22 Normal', () {
    final BmiResult result = BmiCalculator.metric(
      heightCm: d('170'),
      weightKg: d('70'),
    )!;

    expect(formatToolNumber(result.bmi), '24.22');
    expect(result.category, BmiCategory.normal);
    expect(result.category.label, 'Normal');
    expect(result.heightMeters, d('1.7'));
    expect(result.weightKg, d('70'));
  });

  test('180 cm and 81 kg lands exactly on 25.00 Overweight', () {
    final BmiResult result = BmiCalculator.metric(
      heightCm: d('180'),
      weightKg: d('81'),
    )!;

    expect(formatToolNumber(result.bmi), '25.00');
    expect(result.category, BmiCategory.overweight);
  });

  test('170 cm and 100 kg is 34.60 Obese', () {
    final BmiResult result = BmiCalculator.metric(
      heightCm: d('170'),
      weightKg: d('100'),
    )!;

    expect(formatToolNumber(result.bmi), '34.60');
    expect(result.category, BmiCategory.obese);
  });

  test('5 ft 7 in and 154 lb convert to metric first', () {
    final BmiResult result = BmiCalculator.imperial(
      feet: d('5'),
      inches: d('7'),
      pounds: d('154'),
    )!;

    expect(result.heightMeters, d('1.7018'));
    expect(result.weightKg, d('69.85322498'));
    expect(formatToolNumber(result.bmi), '24.12');
    expect(result.category, BmiCategory.normal);
  });

  test('6 ft and 180 lb is 24.41 Normal', () {
    final BmiResult result = BmiCalculator.imperial(
      feet: d('6'),
      inches: Decimal.zero,
      pounds: d('180'),
    )!;

    expect(result.heightMeters, d('1.8288'));
    expect(formatToolNumber(result.bmi), '24.41');
  });

  test('inches can carry past a foot', () {
    expect(
      BmiCalculator.imperial(
        feet: d('4'),
        inches: d('19'),
        pounds: d('154'),
      )!.heightMeters,
      d('1.7018'),
    );
  });

  test('the WHO bands use the lower bound of each range', () {
    expect(BmiCalculator.categoryFor(d('18.49')), BmiCategory.underweight);
    expect(BmiCalculator.categoryFor(d('18.5')), BmiCategory.normal);
    expect(BmiCalculator.categoryFor(d('24.9')), BmiCategory.normal);
    expect(BmiCalculator.categoryFor(d('25')), BmiCategory.overweight);
    expect(BmiCalculator.categoryFor(d('29.9')), BmiCategory.overweight);
    expect(BmiCalculator.categoryFor(d('30')), BmiCategory.obese);
    expect(BmiCalculator.categoryFor(d('0')), BmiCategory.underweight);
  });

  test('zero or negative heights and weights have no BMI', () {
    expect(
      BmiCalculator.metric(heightCm: Decimal.zero, weightKg: d('70')),
      isNull,
    );
    expect(
      BmiCalculator.metric(heightCm: d('170'), weightKg: Decimal.zero),
      isNull,
    );
    expect(
      BmiCalculator.metric(heightCm: d('-170'), weightKg: d('70')),
      isNull,
    );
    expect(
      BmiCalculator.metric(heightCm: d('170'), weightKg: d('-70')),
      isNull,
    );
    expect(
      BmiCalculator.imperial(
        feet: Decimal.zero,
        inches: Decimal.zero,
        pounds: d('154'),
      ),
      isNull,
    );
    expect(
      BmiCalculator.imperial(
        feet: d('5'),
        inches: d('7'),
        pounds: Decimal.zero,
      ),
      isNull,
    );
    expect(
      BmiCalculator.imperial(feet: d('5'), inches: d('-7'), pounds: d('154')),
      isNull,
    );
  });

  test('the result prints its value and category', () {
    final BmiResult result = BmiCalculator.metric(
      heightCm: d('170'),
      weightKg: d('70'),
    )!;

    expect(result.toString(), contains('Normal'));
    expect(result.toString(), contains('1.7 m'));
    expect(result.toString(), contains('70 kg'));
  });
}
