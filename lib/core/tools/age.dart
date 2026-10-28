import 'date_math.dart';

/// The exact calendar age on a date (§14 Age).
final class AgeResult {
  const AgeResult({
    required this.dateOfBirth,
    required this.onDate,
    required this.years,
    required this.months,
    required this.days,
    required this.totalDays,
    required this.nextBirthday,
    required this.daysToNextBirthday,
  });

  /// The date of birth, normalised to UTC midnight.
  final DateTime dateOfBirth;

  /// The date the age is measured on, normalised to UTC midnight.
  final DateTime onDate;

  /// Completed calendar years.
  final int years;

  /// Completed calendar months after [years].
  final int months;

  /// Days after [years] and [months].
  final int days;

  /// `onDate − dateOfBirth` in whole days.
  final int totalDays;

  /// The next birthday after [onDate]; 29 Feb falls on 28 Feb in a non-leap
  /// year.
  final DateTime nextBirthday;

  /// Whole days from [onDate] to [nextBirthday]; never zero, because a
  /// birthday that is today counts the next one.
  final int daysToNextBirthday;

  @override
  String toString() =>
      'AgeResult($years y $months m $days d, $totalDays days, '
      'next in $daysToNextBirthday)';
}

/// The calendar-age rules of §14.
///
/// The age is the years / months / days between the two dates, where a month
/// that is too short clamps to its last day. A 29 Feb birthday is treated as
/// 28 Feb in non-leap years. An [onDate] before the birth date has no answer,
/// so [calculate] returns null and the page shows a dash.
abstract final class AgeCalculator {
  /// The age of someone born on [dateOfBirth] on [onDate].
  static AgeResult? calculate({
    required DateTime dateOfBirth,
    required DateTime onDate,
  }) {
    final DateTime dob = dateOnly(dateOfBirth);
    final DateTime on = dateOnly(onDate);
    if (on.isBefore(dob)) {
      return null;
    }

    final ({int months, int days}) difference = monthDifference(dob, on);
    final DateTime next = _nextBirthday(dob, on);

    return AgeResult(
      dateOfBirth: dob,
      onDate: on,
      years: difference.months ~/ 12,
      months: difference.months % 12,
      days: difference.days,
      totalDays: on.difference(dob).inDays,
      nextBirthday: next,
      daysToNextBirthday: next.difference(on).inDays,
    );
  }

  /// The first birthday strictly after [on].
  static DateTime _nextBirthday(DateTime dob, DateTime on) {
    DateTime candidate = _birthdayIn(dob, on.year);
    if (!candidate.isAfter(on)) {
      candidate = _birthdayIn(dob, on.year + 1);
    }
    return candidate;
  }

  /// The birthday in [year]; a 29 Feb birthday falls on 28 Feb when [year] is
  /// not a leap year.
  static DateTime _birthdayIn(DateTime dob, int year) {
    if (dob.month == 2 && dob.day == 29) {
      return DateTime.utc(year, 2, isLeapYear(year) ? 29 : 28);
    }
    return DateTime.utc(year, dob.month, dob.day);
  }
}
