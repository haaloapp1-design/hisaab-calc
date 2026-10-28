/// Date-only helpers shared by the Age and Date difference tools (§14).
///
/// Every value is normalised to UTC midnight before any arithmetic, so a device
/// timezone or a daylight-saving change can never move a calendar day.
library;

/// [value] as a UTC midnight [DateTime], dropping any time of day.
DateTime dateOnly(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);

/// True for a Gregorian leap year.
bool isLeapYear(int year) =>
    (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

/// The number of days in [month] of [year]; [month] may be outside 1–12.
int daysInMonth(int year, int month) {
  final int index = year * 12 + (month - 1);
  final int normalisedYear = index ~/ 12;
  final int normalisedMonth = index % 12 + 1;
  return DateTime.utc(normalisedYear, normalisedMonth + 1, 0).day;
}

/// [date] moved by [months], clamping the day to the target month's length.
///
/// `31 Jan + 1 month` is `28 Feb` (or `29 Feb` in a leap year), which is how
/// the calendar difference borrows days from the previous month's length.
DateTime addMonthsClamped(DateTime date, int months) {
  final DateTime day = dateOnly(date);
  final int index = day.year * 12 + (day.month - 1) + months;
  final int year = index ~/ 12;
  final int month = index % 12 + 1;
  final int maxDay = daysInMonth(year, month);
  return DateTime.utc(year, month, day.day > maxDay ? maxDay : day.day);
}

/// The calendar months and leftover days from [from] to [to].
///
/// [from] must not be after [to]. The months are the largest count whose
/// clamped anniversary still falls on or before [to], so the leftover days are
/// never negative (`31 Jan → 1 Mar` is `1 month 1 day`).
({int months, int days}) monthDifference(DateTime from, DateTime to) {
  final DateTime start = dateOnly(from);
  final DateTime end = dateOnly(to);
  int months = (end.year - start.year) * 12 + (end.month - start.month);
  DateTime anchor = addMonthsClamped(start, months);
  if (anchor.isAfter(end)) {
    months -= 1;
    anchor = addMonthsClamped(start, months);
  }
  return (months: months, days: end.difference(anchor).inDays);
}
