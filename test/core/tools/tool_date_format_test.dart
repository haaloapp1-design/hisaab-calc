import 'package:calculator/core/tools/tool_date_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats the short date in UTC', () {
    expect(formatToolDate(DateTime.utc(2026, 10, 28)), '28 Oct 2026');
    expect(formatToolDate(DateTime.utc(2026, 1, 1)), '1 Jan 2026');
    expect(formatToolDate(DateTime.utc(2026, 12, 31)), '31 Dec 2026');
    expect(formatToolDate(DateTime.utc(2026, 10, 28, 23, 59)), '28 Oct 2026');
  });

  test('formats the weekday', () {
    expect(formatToolWeekday(DateTime.utc(2026, 10, 28)), 'Wednesday');
    expect(formatToolWeekday(DateTime.utc(2026, 10, 26)), 'Monday');
    expect(formatToolWeekday(DateTime.utc(2026, 11, 1)), 'Sunday');
  });

  test('formats a range with an arrow', () {
    expect(
      formatToolDateRange(
        DateTime.utc(2026, 9, 28),
        DateTime.utc(2026, 10, 28),
      ),
      '28 Sep 2026 → 28 Oct 2026',
    );
  });
}
