/// The date strings the date tools show.
///
/// The app itself is English, so the month and weekday names are fixed lists
/// (like `formatRateDate`); every value is read in UTC because the date tools
/// work on calendar days, not moments.
library;

const List<String> _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const List<String> _weekdays = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// `28 Oct 2026`, the short form used in fields, captions and summaries.
String formatToolDate(DateTime value) {
  final DateTime utc = value.toUtc();
  return '${utc.day} ${_months[utc.month - 1]} ${utc.year}';
}

/// The full English weekday of a date, e.g. `Wednesday`.
String formatToolWeekday(DateTime value) =>
    _weekdays[value.toUtc().weekday - 1];

/// `1 Jan 2026 → 28 Oct 2026`, the date-difference caption.
String formatToolDateRange(DateTime start, DateTime end) =>
    '${formatToolDate(start)} → ${formatToolDate(end)}';
