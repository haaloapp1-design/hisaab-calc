import 'dart:math' as math;

import 'package:decimal/decimal.dart';

/// The summary statistics of one list of numbers (§14 Statistics).
final class StatisticsResult {
  const StatisticsResult({
    required this.count,
    required this.sum,
    required this.mean,
    required this.median,
    required this.modes,
    required this.min,
    required this.max,
    required this.range,
    required this.populationSd,
    required this.sampleSd,
  });

  final int count;
  final Decimal sum;
  final Decimal mean;
  final Decimal median;

  /// Every value with the highest frequency, ascending; empty when all values
  /// appear once.
  final List<Decimal> modes;

  final Decimal min;
  final Decimal max;
  final Decimal range;

  /// `√(Σ(x−μ)²/n)`.
  final Decimal populationSd;

  /// `√(Σ(x−x̄)²/(n−1))`; null for a single value.
  final Decimal? sampleSd;

  @override
  String toString() =>
      'StatisticsResult($count values, mean $mean, median $median, '
      'modes $modes, SD $populationSd/$sampleSd)';
}

/// The statistics formulas of §14.
///
/// Sums, the mean, the median and the variance use [Decimal]; the two standard
/// deviations take a square root, so they come back at 15 significant digits.
/// An empty list has no statistics, so [calculate] returns null.
abstract final class StatisticsCalculator {
  /// The count, sum, mean, median, mode, min, max, range and both SDs.
  static StatisticsResult? calculate(List<Decimal> values) {
    if (values.isEmpty) {
      return null;
    }

    final List<Decimal> sorted = List<Decimal>.of(values)..sort();
    final int count = sorted.length;
    final Decimal sum = sorted.fold(
      Decimal.zero,
      (Decimal a, Decimal b) => a + b,
    );
    final Decimal mean = _divide(sum, Decimal.fromInt(count));
    final Decimal median = count.isOdd
        ? sorted[count ~/ 2]
        : _divide(
            sorted[count ~/ 2 - 1] + sorted[count ~/ 2],
            Decimal.fromInt(2),
          );

    Decimal squares = Decimal.zero;
    for (final Decimal value in sorted) {
      final Decimal difference = value - mean;
      squares += difference * difference;
    }

    final Decimal? sampleVariance = count < 2
        ? null
        : _divide(squares, Decimal.fromInt(count - 1));

    return StatisticsResult(
      count: count,
      sum: sum,
      mean: mean,
      median: median,
      modes: _modes(sorted),
      min: sorted.first,
      max: sorted.last,
      range: sorted.last - sorted.first,
      populationSd: _sqrt(_divide(squares, Decimal.fromInt(count))),
      sampleSd: sampleVariance == null ? null : _sqrt(sampleVariance),
    );
  }

  /// Reads a comma/space/semicolon separated list of numbers.
  ///
  /// Empty parts are skipped, so a trailing comma is fine. The field always
  /// uses `.` as the decimal mark (commas separate values), and a token that
  /// is not a number makes the whole input invalid, so the page can show a
  /// dash instead of a half-typed result. An empty input returns an empty list.
  static List<Decimal>? parseInput(String text) {
    final List<String> tokens = text
        .split(RegExp(r'[,\s;]+'))
        .where((String token) => token.isNotEmpty)
        .toList();
    final List<Decimal> values = <Decimal>[];
    for (final String token in tokens) {
      final String normalised = token.startsWith('+')
          ? token.substring(1)
          : token;
      final Decimal? value = Decimal.tryParse(normalised);
      if (value == null) {
        return null;
      }
      values.add(value);
    }
    return values;
  }

  /// Every value with the maximum frequency, in ascending order.
  static List<Decimal> _modes(List<Decimal> sorted) {
    final Map<Decimal, int> counts = <Decimal, int>{};
    for (final Decimal value in sorted) {
      counts[value] = (counts[value] ?? 0) + 1;
    }
    int highest = 0;
    for (final int count in counts.values) {
      if (count > highest) {
        highest = count;
      }
    }
    if (highest < 2) {
      return const <Decimal>[];
    }
    return <Decimal>[
      for (final MapEntry<Decimal, int> entry in counts.entries)
        if (entry.value == highest) entry.key,
    ];
  }

  static Decimal _divide(Decimal a, Decimal b) =>
      (a / b).toDecimal(scaleOnInfinitePrecision: 32);

  static Decimal _sqrt(Decimal value) {
    if (value == Decimal.zero) {
      return Decimal.zero;
    }
    final double result = math.sqrt(value.toDouble());
    return Decimal.parse(result.toStringAsPrecision(15));
  }
}
