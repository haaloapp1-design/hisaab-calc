import 'package:calculator/core/tools/age.dart';
import 'package:calculator/core/tools/tool_date_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime utc(int year, int month, int day) => DateTime.utc(year, month, day);

  AgeResult calculate(DateTime dob, DateTime on) =>
      AgeCalculator.calculate(dateOfBirth: dob, onDate: on)!;

  test('1 Jan 1990 on 28 Oct 2026 is 36y 9m 27d', () {
    final AgeResult result = calculate(utc(1990, 1, 1), utc(2026, 10, 28));

    expect(result.years, 36);
    expect(result.months, 9);
    expect(result.days, 27);
    expect(result.totalDays, 13449);
    expect(formatToolDate(result.nextBirthday), '1 Jan 2027');
    expect(result.daysToNextBirthday, 65);
  });

  test('a 29 Feb birthday is 28 Feb in a non-leap year', () {
    final AgeResult result = calculate(utc(2000, 2, 29), utc(2023, 2, 28));

    expect(result.years, 23);
    expect(result.months, 0);
    expect(result.days, 0);
    expect(result.totalDays, 8400);
    expect(formatToolDate(result.nextBirthday), '29 Feb 2024');
    expect(result.daysToNextBirthday, 366);
  });

  test('a 29 Feb birthday in a leap year keeps the 29th', () {
    final AgeResult result = calculate(utc(2000, 2, 29), utc(2024, 2, 29));

    expect(result.years, 24);
    expect(result.months, 0);
    expect(result.days, 0);
    expect(result.totalDays, 8766);
  });

  test('the day after a 29 Feb birthday is one day', () {
    final AgeResult result = calculate(utc(2000, 2, 29), utc(2023, 3, 1));

    expect(result.years, 23);
    expect(result.months, 0);
    expect(result.days, 1);
  });

  test('month-end borrows from the previous month length', () {
    final AgeResult result = calculate(utc(2026, 1, 31), utc(2026, 3, 1));

    expect(result.years, 0);
    expect(result.months, 1);
    expect(result.days, 1);
    expect(result.totalDays, 29);
  });

  test('a leap-year month end also borrows 29 days', () {
    final AgeResult result = calculate(utc(2024, 1, 31), utc(2024, 3, 1));

    expect(result.months, 1);
    expect(result.days, 1);
    expect(result.totalDays, 30);
  });

  test('the same day is zero and the next birthday is a year away', () {
    final AgeResult result = calculate(utc(2026, 1, 1), utc(2026, 1, 1));

    expect(result.years, 0);
    expect(result.months, 0);
    expect(result.days, 0);
    expect(result.totalDays, 0);
    expect(formatToolDate(result.nextBirthday), '1 Jan 2027');
    expect(result.daysToNextBirthday, 365);
  });

  test('a birthday today counts the next one', () {
    final AgeResult result = calculate(utc(1990, 1, 1), utc(2026, 1, 1));

    expect(result.years, 36);
    expect(result.months, 0);
    expect(result.days, 0);
    expect(result.daysToNextBirthday, 365);
  });

  test('a birthday tomorrow is one day away', () {
    final AgeResult result = calculate(utc(1990, 1, 2), utc(2027, 1, 1));

    expect(result.daysToNextBirthday, 1);
    expect(formatToolDate(result.nextBirthday), '2 Jan 2027');
  });

  test('the time of day is ignored', () {
    final AgeResult result = calculate(
      DateTime(1990, 1, 1, 23, 59),
      DateTime(2026, 10, 28, 0, 1),
    );

    expect(result.years, 36);
    expect(result.months, 9);
    expect(result.days, 27);
    expect(result.totalDays, 13449);
  });

  test('an on date before the birth date has no answer', () {
    expect(
      AgeCalculator.calculate(
        dateOfBirth: utc(1990, 1, 1),
        onDate: utc(1989, 12, 31),
      ),
      isNull,
    );
  });

  test('total days matches the plain DateTime difference', () {
    final AgeResult result = calculate(utc(1990, 1, 1), utc(2026, 10, 28));

    expect(
      result.totalDays,
      utc(2026, 10, 28).difference(utc(1990, 1, 1)).inDays,
    );
  });
}
