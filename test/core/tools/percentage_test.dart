import 'package:calculator/core/tools/percentage.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Decimal d(String source) => Decimal.parse(source);

  group('of', () {
    test('15% of 200 is 30', () {
      expect(
        PercentageCalculator.of(percent: d('15'), value: d('200')),
        d('30'),
      );
    });

    test('a decimal percent keeps its value', () {
      expect(
        PercentageCalculator.of(percent: d('7.5'), value: d('200')),
        d('15'),
      );
    });

    test('zero percent is zero', () {
      expect(
        PercentageCalculator.of(percent: Decimal.zero, value: d('200')),
        Decimal.zero,
      );
    });

    test('a negative percent follows the sign', () {
      expect(
        PercentageCalculator.of(percent: d('-10'), value: d('50')),
        d('-5'),
      );
    });
  });

  group('ratio', () {
    test('25 of 200 is 12.5%', () {
      expect(
        PercentageCalculator.ratio(part: d('25'), whole: d('200')),
        d('12.5'),
      );
    });

    test('an endless division keeps 32 places', () {
      final Decimal? result = PercentageCalculator.ratio(
        part: Decimal.one,
        whole: Decimal.fromInt(3),
      );
      expect(result!.toStringAsFixed(4), '33.3333');
    });

    test('a zero whole has no answer', () {
      expect(
        PercentageCalculator.ratio(part: Decimal.one, whole: Decimal.zero),
        isNull,
      );
    });
  });

  group('change', () {
    test('200 to 250 is +25%', () {
      expect(
        PercentageCalculator.change(from: d('200'), to: d('250')),
        d('25'),
      );
    });

    test('250 to 200 is −20%', () {
      expect(
        PercentageCalculator.change(from: d('250'), to: d('200')),
        d('-20'),
      );
    });

    test('no change is zero', () {
      expect(
        PercentageCalculator.change(from: d('200'), to: d('200')),
        Decimal.zero,
      );
    });

    test('a zero start has no answer', () {
      expect(
        PercentageCalculator.change(from: Decimal.zero, to: d('50')),
        isNull,
      );
    });
  });
}
