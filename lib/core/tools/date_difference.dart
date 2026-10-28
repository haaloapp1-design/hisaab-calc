import 'date_math.dart';

/// The result of the difference between two dates (§14 Date difference).
final class DateDifferenceResult {
  const DateDifferenceResult({
    required this.start,
    required this.end,
    required this.includeEndDate,
    required this.days,
    required this.weeks,
    required this.weekDays,
    required this.months,
    required this.monthDays,
    required this.isNegative,
  });

  /// The first date, normalised to UTC midnight.
  final DateTime start;

  /// The second date, normalised to UTC midnight.
  final DateTime end;

  /// Whether the end day itself was counted.
  final bool includeEndDate;

  /// `end − start`, plus one when [includeEndDate] is set. Negative when
  /// [end] is before [start].
  final int days;

  /// Whole weeks in [days], ignoring the sign.
  final int weeks;

  /// Days left after [weeks], ignoring the sign.
  final int weekDays;

  /// Whole calendar months from the earlier date to the later one.
  final int months;

  /// Days left after [months], ignoring the sign.
  final int monthDays;

  /// True when [end] is before [start].
  final bool isNegative;

  @override
  String toString() =>
      'DateDifferenceResult($days days, $weeks w $weekDays d, '
      '$months m $monthDays d, includeEndDate: $includeEndDate)';
}

/// The date-difference rules of §14.
abstract final class DateDifferenceCalculator {
  /// The days, weeks and calendar months between [start] and [end].
  static DateDifferenceResult between({
    required DateTime start,
    required DateTime end,
    bool includeEndDate = false,
  }) {
    final DateTime from = dateOnly(start);
    final DateTime to = dateOnly(end);
    final int raw = to.difference(from).inDays;
    final int days = raw + (includeEndDate ? 1 : 0);
    final int magnitude = days.abs();
    final bool reversed = raw < 0;

    final ({int months, int days}) calendar = monthDifference(
      reversed ? to : from,
      reversed ? from : to,
    );

    return DateDifferenceResult(
      start: from,
      end: to,
      includeEndDate: includeEndDate,
      days: days,
      weeks: magnitude ~/ 7,
      weekDays: magnitude % 7,
      months: calendar.months,
      monthDays: calendar.days,
      isNegative: days < 0,
    );
  }
}

/// Adding and subtracting whole days from a date (§14).
abstract final class DateShift {
  /// [date] moved by [days] (negative moves back), as a UTC date-only value.
  static DateTime shift({required DateTime date, required int days}) =>
      dateOnly(dateOnly(date).add(Duration(days: days)));
}
