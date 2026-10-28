import 'package:calculator/core/tools/tip.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Decimal d(String source) => Decimal.parse(source);

  test('1000 with a 10% tip split by 3', () {
    final TipResult result = TipCalculator.calculate(
      bill: d('1000'),
      tipPercent: d('10'),
      people: 3,
    );

    expect(result.tip, d('100'));
    expect(result.total, d('1100'));
    expect(result.perPerson.toStringAsFixed(4), '366.6667');
    expect(result.roundedPerPerson, d('367'));
  });

  test('a zero tip leaves the bill unchanged', () {
    final TipResult result = TipCalculator.calculate(
      bill: d('1000'),
      tipPercent: Decimal.zero,
      people: 3,
    );

    expect(result.tip, Decimal.zero);
    expect(result.total, d('1000'));
    expect(result.perPerson.toStringAsFixed(4), '333.3333');
    expect(result.roundedPerPerson, d('334'));
  });

  test('one person pays the whole total', () {
    final TipResult result = TipCalculator.calculate(
      bill: d('250'),
      tipPercent: d('10'),
      people: 1,
    );

    expect(result.total, d('275'));
    expect(result.perPerson, d('275'));
    expect(result.roundedPerPerson, d('275'));
  });

  test('an exact division is not rounded further', () {
    final TipResult result = TipCalculator.calculate(
      bill: d('100'),
      tipPercent: Decimal.zero,
      people: 4,
    );

    expect(result.perPerson, d('25'));
    expect(result.roundedPerPerson, d('25'));
  });

  test('a half unit rounds up', () {
    final TipResult result = TipCalculator.calculate(
      bill: d('100'),
      tipPercent: d('10'),
      people: 4,
    );

    expect(result.perPerson, d('27.5'));
    expect(result.roundedPerPerson, d('28'));
  });

  test('negative inputs and zero people are rejected', () {
    expect(
      () => TipCalculator.calculate(
        bill: d('-1'),
        tipPercent: Decimal.zero,
        people: 1,
      ),
      throwsArgumentError,
    );
    expect(
      () =>
          TipCalculator.calculate(bill: d('1'), tipPercent: d('-1'), people: 1),
      throwsArgumentError,
    );
    expect(
      () => TipCalculator.calculate(
        bill: d('1'),
        tipPercent: Decimal.zero,
        people: 0,
      ),
      throwsArgumentError,
    );
  });
}
