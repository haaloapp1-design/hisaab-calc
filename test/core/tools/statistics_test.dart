import 'package:calculator/core/tools/statistics.dart';
import 'package:calculator/core/tools/tool_format.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<Decimal> list(List<String> values) => values.map(Decimal.parse).toList();

  StatisticsResult stats(List<String> values) =>
      StatisticsCalculator.calculate(list(values))!;

  test('the classic six-number list summarises every row', () {
    final StatisticsResult result = stats(<String>[
      '4',
      '8',
      '15',
      '16',
      '23',
      '42',
    ]);

    expect(result.count, 6);
    expect(formatToolNumber(result.sum), '108.00');
    expect(formatToolNumber(result.mean), '18.00');
    expect(formatToolNumber(result.median), '15.50');
    expect(result.modes, isEmpty);
    expect(formatToolNumber(result.min), '4.00');
    expect(formatToolNumber(result.max), '42.00');
    expect(formatToolNumber(result.range), '38.00');
    expect(formatToolNumber(result.populationSd), '12.32');
    expect(formatToolNumber(result.sampleSd!), '13.49');
  });

  test('an odd count has the middle value as median', () {
    final StatisticsResult result = stats(<String>['5', '1', '3']);

    expect(result.count, 3);
    expect(formatToolNumber(result.mean), '3.00');
    expect(formatToolNumber(result.median), '3.00');
  });

  test('an even count averages the two middle values', () {
    expect(
      formatToolNumber(stats(<String>['4', '1', '3', '2']).median),
      '2.50',
    );
    expect(formatToolNumber(stats(<String>['1', '2']).median), '1.50');
  });

  test('the mode keeps every tied value, ascending', () {
    final StatisticsResult result = stats(<String>['3', '2', '2', '3', '1']);

    expect(result.modes.map(formatToolNumber), <String>['2.00', '3.00']);
  });

  test('all values once has no mode', () {
    expect(stats(<String>['1', '2', '3']).modes, isEmpty);
    expect(stats(<String>['7']).modes, isEmpty);
  });

  test('min, max and range work with negatives', () {
    final StatisticsResult result = stats(<String>['-5', '0', '5', '10']);

    expect(formatToolNumber(result.min), '−5.00');
    expect(formatToolNumber(result.max), '10.00');
    expect(formatToolNumber(result.range), '15.00');
  });

  test('the population and sample SDs differ for a small list', () {
    final StatisticsResult result = stats(<String>['1', '3']);

    expect(formatToolNumber(result.populationSd), '1.00');
    expect(formatToolNumber(result.sampleSd!), '1.41');
  });

  test('a single value has a zero population SD and no sample SD', () {
    final StatisticsResult result = stats(<String>['5']);

    expect(result.populationSd, Decimal.zero);
    expect(result.sampleSd, isNull);
  });

  test('identical values have no spread', () {
    final StatisticsResult result = stats(<String>['2.5', '2.5', '2.5']);

    expect(result.populationSd, Decimal.zero);
    expect(result.sampleSd, Decimal.zero);
  });

  test('the order of the input does not matter', () {
    final StatisticsResult a = stats(<String>[
      '42',
      '4',
      '23',
      '8',
      '16',
      '15',
    ]);
    final StatisticsResult b = stats(<String>[
      '4',
      '8',
      '15',
      '16',
      '23',
      '42',
    ]);

    expect(a.mean, b.mean);
    expect(a.median, b.median);
    expect(a.populationSd, b.populationSd);
    expect(a.sampleSd, b.sampleSd);
  });

  test('an empty list has no statistics', () {
    expect(StatisticsCalculator.calculate(<Decimal>[]), isNull);
  });

  test('parseInput accepts commas, spaces and semicolons', () {
    expect(
      StatisticsCalculator.parseInput('1, 2;3  4')!.map(formatToolNumber),
      <String>['1.00', '2.00', '3.00', '4.00'],
    );
    expect(StatisticsCalculator.parseInput('4,8,15,16,23,42')!.length, 6);
  });

  test('parseInput skips empty parts and leading plus signs', () {
    expect(
      StatisticsCalculator.parseInput('1, 2,')!.map(formatToolNumber),
      <String>['1.00', '2.00'],
    );
    expect(
      StatisticsCalculator.parseInput('+5, -2, 3.5')!.map(formatToolNumber),
      <String>['5.00', '−2.00', '3.50'],
    );
    expect(StatisticsCalculator.parseInput(''), isEmpty);
  });

  test('parseInput rejects a token that is not a number', () {
    expect(StatisticsCalculator.parseInput('1, x, 3'), isNull);
    expect(StatisticsCalculator.parseInput('1.2.3'), isNull);
    expect(StatisticsCalculator.parseInput('.'), isNull);
  });

  test('the result prints its summary', () {
    final StatisticsResult result = stats(<String>['1', '2', '2']);

    expect(result.toString(), contains('3 values'));
    expect(result.toString(), contains('mean'));
    expect(result.toString(), contains('modes'));
  });
}
