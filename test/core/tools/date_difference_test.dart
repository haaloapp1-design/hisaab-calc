import 'package:calculator/core/tools/date_difference.dart';
import 'package:calculator/core/tools/date_math.dart';
import 'package:calculator/core/tools/tool_date_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime utc(int year, int month, int day) => DateTime.utc(year, month, day);

  DateDifferenceResult between(
    DateTime start,
    DateTime end, {
    bool inc = false,
  }) => DateDifferenceCalculator.between(
    start: start,
    end: end,
    includeEndDate: inc,
  );

  test('28 Sep to 28 Oct is 30 days', () {
    final DateDifferenceResult result = between(
      utc(2026, 9, 28),
      utc(2026, 10, 28),
    );

    expect(result.days, 30);
    expect(result.weeks, 4);
    expect(result.weekDays, 2);
    expect(result.months, 1);
    expect(result.monthDays, 0);
    expect(result.isNegative, isFalse);
    expect(result.includeEndDate, isFalse);
  });

  test('including the end date adds one day', () {
    final DateDifferenceResult result = between(
      utc(2026, 9, 28),
      utc(2026, 10, 28),
      inc: true,
    );

    expect(result.days, 31);
    expect(result.weeks, 4);
    expect(result.weekDays, 3);
    expect(result.includeEndDate, isTrue);
  });

  test('a reversed range is negative but keeps its magnitude', () {
    final DateDifferenceResult result = between(
      utc(2026, 10, 28),
      utc(2026, 9, 28),
    );

    expect(result.days, -30);
    expect(result.weeks, 4);
    expect(result.weekDays, 2);
    expect(result.months, 1);
    expect(result.monthDays, 0);
    expect(result.isNegative, isTrue);
  });

  test('including the end date on a reversed range moves toward zero', () {
    expect(between(utc(2026, 10, 28), utc(2026, 9, 28), inc: true).days, -29);
  });

  test('the same day is zero days, or one with the end included', () {
    final DateTime day = utc(2026, 10, 28);

    expect(between(day, day).days, 0);
    expect(between(day, day, inc: true).days, 1);
    expect(between(day, day, inc: true).weeks, 0);
  });

  test('a month-end range keeps the calendar months honest', () {
    final DateDifferenceResult result = between(
      utc(2026, 1, 31),
      utc(2026, 3, 1),
    );

    expect(result.days, 29);
    expect(result.months, 1);
    expect(result.monthDays, 1);
  });

  test('a full calendar month is one month zero days', () {
    final DateDifferenceResult result = between(
      utc(2026, 1, 1),
      utc(2026, 2, 1),
    );

    expect(result.days, 31);
    expect(result.weeks, 4);
    expect(result.weekDays, 3);
    expect(result.months, 1);
    expect(result.monthDays, 0);
  });

  test('a range across the leap day counts 29 Feb', () {
    expect(between(utc(2024, 2, 28), utc(2024, 3, 1)).days, 2);
  });

  test('shift moves by whole days and keeps UTC midnight', () {
    final DateTime start = utc(2026, 10, 28);

    expect(
      formatToolDate(DateShift.shift(date: start, days: 30)),
      '27 Nov 2026',
    );
    expect(
      formatToolDate(DateShift.shift(date: start, days: -30)),
      '28 Sep 2026',
    );
    expect(DateShift.shift(date: start, days: 0), start);
    expect(formatToolWeekday(DateShift.shift(date: start, days: 30)), 'Friday');
  });

  test('shift crosses a leap day and a year end', () {
    expect(
      formatToolDate(DateShift.shift(date: utc(2024, 2, 28), days: 1)),
      '29 Feb 2024',
    );
    expect(
      formatToolDate(DateShift.shift(date: utc(2026, 12, 31), days: 1)),
      '1 Jan 2027',
    );
  });

  test('shift ignores the time of day', () {
    final DateTime withTime = DateTime(2026, 10, 28, 23, 30);

    expect(
      formatToolDate(DateShift.shift(date: withTime, days: 1)),
      '29 Oct 2026',
    );
  });

  test('leap years and month lengths follow the Gregorian calendar', () {
    expect(isLeapYear(2024), isTrue);
    expect(isLeapYear(2026), isFalse);
    expect(isLeapYear(2000), isTrue);
    expect(isLeapYear(2100), isFalse);
    expect(daysInMonth(2024, 2), 29);
    expect(daysInMonth(2026, 2), 28);
    expect(daysInMonth(2026, 12), 31);
    expect(daysInMonth(2026, 13), 31);
    expect(daysInMonth(2026, 0), 31);
  });

  test('addMonthsClamped clamps the day to the target month', () {
    expect(
      formatToolDate(addMonthsClamped(utc(2026, 1, 31), 1)),
      '28 Feb 2026',
    );
    expect(
      formatToolDate(addMonthsClamped(utc(2024, 1, 31), 1)),
      '29 Feb 2024',
    );
    expect(
      formatToolDate(addMonthsClamped(utc(2026, 3, 31), 1)),
      '30 Apr 2026',
    );
  });

  test('monthDifference borrows the previous month length', () {
    expect(monthDifference(utc(2026, 1, 31), utc(2026, 3, 1)), (
      months: 1,
      days: 1,
    ));
    expect(monthDifference(utc(2026, 1, 1), utc(2026, 2, 1)), (
      months: 1,
      days: 0,
    ));
    expect(monthDifference(utc(2026, 1, 31), utc(2026, 2, 28)), (
      months: 1,
      days: 0,
    ));
  });
}
