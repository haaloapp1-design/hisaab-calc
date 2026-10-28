import 'package:decimal/decimal.dart';

/// One course line of the GPA tool: a name, its credits and its grade points.
final class GpaCourse {
  const GpaCourse({
    required this.name,
    required this.credits,
    required this.points,
  });

  /// The course name; empty is allowed and only used for display.
  final String name;

  /// Credit hours; zero keeps the course out of the average.
  final Decimal credits;

  /// Grade points earned (e.g. `4.0` on the 4.0 scale).
  final Decimal points;

  @override
  String toString() => 'GpaCourse($name, $credits cr, $points pts)';
}

/// The weighted average of a course list (§14 GPA).
final class GpaResult {
  const GpaResult({
    required this.gpa,
    required this.totalCredits,
    required this.percentage,
    required this.courseCount,
  });

  /// `Σ(credits × points) / Σ credits`, unrounded.
  final Decimal gpa;

  /// `Σ credits`.
  final Decimal totalCredits;

  /// [gpa] as a percentage of the chosen scale (`gpa / scale × 100`).
  final Decimal percentage;

  /// How many courses were averaged, including zero-credit ones.
  final int courseCount;

  @override
  String toString() =>
      'GpaResult($gpa, $totalCredits credits, ${percentage.toStringAsFixed(2)}%, '
      '$courseCount courses)';
}

/// The GPA formula of §14.
///
/// The grade scale is configurable and defaults to 4.0; it only affects the
/// percentage equivalent, because the points themselves are entered per
/// course. A list whose credits add up to zero has no average, so
/// [calculate] returns null and the page shows a dash. Negative credits or
/// points are programming errors; the fields cannot produce them.
abstract final class GpaCalculator {
  /// The default 4.0 scale.
  static final Decimal defaultScale = Decimal.fromInt(4);

  /// The 5.0 scale offered beside the default.
  static final Decimal fiveScale = Decimal.fromInt(5);

  /// The 10-point scale offered beside the default.
  static final Decimal tenScale = Decimal.fromInt(10);

  static final Decimal _hundred = Decimal.fromInt(100);

  /// The weighted GPA of [courses] on [scale] (4.0 when omitted).
  static GpaResult? calculate({
    required List<GpaCourse> courses,
    Decimal? scale,
  }) {
    final Decimal max = scale ?? defaultScale;
    if (max <= Decimal.zero) {
      throw ArgumentError.value(max, 'scale', 'must be greater than zero');
    }

    Decimal totalCredits = Decimal.zero;
    Decimal weighted = Decimal.zero;
    for (final GpaCourse course in courses) {
      if (course.credits < Decimal.zero) {
        throw ArgumentError.value(
          course.credits,
          'credits',
          'must not be negative',
        );
      }
      if (course.points < Decimal.zero) {
        throw ArgumentError.value(
          course.points,
          'points',
          'must not be negative',
        );
      }
      totalCredits += course.credits;
      weighted += course.credits * course.points;
    }

    if (totalCredits == Decimal.zero) {
      return null;
    }

    final Decimal gpa = _divide(weighted, totalCredits);
    return GpaResult(
      gpa: gpa,
      totalCredits: totalCredits,
      percentage: _divide(gpa * _hundred, max),
      courseCount: courses.length,
    );
  }

  static Decimal _divide(Decimal a, Decimal b) =>
      (a / b).toDecimal(scaleOnInfinitePrecision: 32);
}
