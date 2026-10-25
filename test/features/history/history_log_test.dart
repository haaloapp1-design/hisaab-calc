import 'package:calculator/features/history/history_entry.dart';
import 'package:calculator/features/history/history_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime base = DateTime(2024, 3, 10, 9);

  HistoryEntry entry(
    int index, {
    String? expression,
    DateTime? createdAt,
    HistoryMode mode = HistoryMode.basic,
  }) => HistoryEntry.create(
    expression: expression ?? '${index + 1} + 1',
    result: '${index + 2}',
    mode: mode,
    createdAt: createdAt ?? base.add(Duration(seconds: index)),
  );

  List<HistoryEntry> entries(int count) => <HistoryEntry>[
    for (int index = 0; index < count; index++) entry(index),
  ];

  group('add', () {
    test('puts the newest entry first', () {
      final List<HistoryEntry> list = HistoryLog.add(
        <HistoryEntry>[],
        entry(0),
      );
      final List<HistoryEntry> next = HistoryLog.add(list, entry(1));

      expect(next, <HistoryEntry>[entry(1), entry(0)]);
    });

    test('skips a repeat of the previous calculation', () {
      final List<HistoryEntry> list = HistoryLog.add(
        <HistoryEntry>[],
        entry(0),
      );
      final HistoryEntry repeat = entry(
        0,
        createdAt: base.add(const Duration(minutes: 1)),
      );

      final List<HistoryEntry> next = HistoryLog.add(list, repeat);

      expect(next, same(list));
      expect(next, hasLength(1));
    });

    test('allows a calculation again after a different one', () {
      List<HistoryEntry> list = HistoryLog.add(<HistoryEntry>[], entry(0));
      list = HistoryLog.add(list, entry(1));
      list = HistoryLog.add(
        list,
        entry(0, createdAt: base.add(const Duration(minutes: 2))),
      );

      expect(list, hasLength(3));
      expect(list.first.expression, entry(0).expression);
    });

    test('keeps the newest 500 entries', () {
      final List<HistoryEntry> next = entries(HistoryLog.maxEntries + 1)
          .fold(<HistoryEntry>[], HistoryLog.add);

      expect(next, hasLength(500));
      expect(next.first, entry(HistoryLog.maxEntries));
      expect(next.last, entry(1));
      expect(next.any((HistoryEntry row) => row == entry(0)), isFalse);
    });

    test('is not full at exactly 500', () {
      final List<HistoryEntry> next = entries(HistoryLog.maxEntries)
          .fold(<HistoryEntry>[], HistoryLog.add);

      expect(next, hasLength(500));
      expect(next.last, entry(0));
    });
  });

  group('remove', () {
    test('drops the matching id', () {
      final List<HistoryEntry> list = entries(3);

      expect(HistoryLog.remove(list, entry(1).id), <HistoryEntry>[
        entry(0),
        entry(2),
      ]);
    });

    test('returns the same list for an unknown id', () {
      final List<HistoryEntry> list = entries(2);

      expect(HistoryLog.remove(list, 'missing'), same(list));
    });
  });

  group('prune', () {
    test('keeps entries inside 7, 30 and 90 days', () {
      final DateTime now = base;
      final HistoryEntry day6 = entry(
        0,
        createdAt: now.subtract(const Duration(days: 6)),
      );
      final HistoryEntry day7 = entry(
        1,
        createdAt: now.subtract(const Duration(days: 7)),
      );
      final HistoryEntry day29 = entry(
        2,
        createdAt: now.subtract(const Duration(days: 29)),
      );
      final HistoryEntry day30 = entry(
        3,
        createdAt: now.subtract(const Duration(days: 30)),
      );
      final HistoryEntry day89 = entry(
        4,
        createdAt: now.subtract(const Duration(days: 89)),
      );
      final HistoryEntry day90 = entry(
        5,
        createdAt: now.subtract(const Duration(days: 90)),
      );
      final List<HistoryEntry> list = <HistoryEntry>[
        day6,
        day7,
        day29,
        day30,
        day89,
        day90,
      ];

      expect(HistoryLog.prune(list, now: now, retentionDays: 7), <HistoryEntry>[
        day6,
        day7,
      ]);
      expect(
        HistoryLog.prune(list, now: now, retentionDays: 30),
        <HistoryEntry>[day6, day7, day29, day30],
      );
      expect(HistoryLog.prune(list, now: now, retentionDays: 90), list);
    });

    test('drops older entries', () {
      final HistoryEntry old = entry(
        0,
        createdAt: base.subtract(const Duration(days: 8)),
      );
      final HistoryEntry recent = entry(
        1,
        createdAt: base.subtract(const Duration(days: 1)),
      );
      final List<HistoryEntry> list = <HistoryEntry>[old, recent];

      expect(
        HistoryLog.prune(list, now: base, retentionDays: 7),
        <HistoryEntry>[recent],
      );
    });

    test('Forever and a list with nothing to drop keep the instance', () {
      final List<HistoryEntry> list = entries(3);

      expect(
        HistoryLog.prune(list, now: base, retentionDays: null),
        same(list),
      );
      expect(HistoryLog.prune(list, now: base, retentionDays: 30), same(list));
    });

    test('an empty history stays empty', () {
      expect(
        HistoryLog.prune(<HistoryEntry>[], now: base, retentionDays: 7),
        isEmpty,
      );
    });
  });

  group('groupByDay', () {
    final DateTime now = DateTime(2024, 3, 10, 12);

    test('labels Today, Yesterday and older days', () {
      final HistoryEntry todayLate = entry(
        0,
        createdAt: DateTime(2024, 3, 10, 10),
      );
      final HistoryEntry todayEarly = entry(
        1,
        createdAt: DateTime(2024, 3, 10, 8),
      );
      final HistoryEntry yesterday = entry(
        2,
        createdAt: DateTime(2024, 3, 9, 23, 59),
      );
      final HistoryEntry marchFirst = entry(
        3,
        createdAt: DateTime(2024, 3, 1, 10),
      );
      final HistoryEntry newYearsEve = entry(
        4,
        createdAt: DateTime(2023, 12, 31, 23, 59),
      );
      final List<HistoryEntry> list = <HistoryEntry>[
        todayLate,
        todayEarly,
        yesterday,
        marchFirst,
        newYearsEve,
      ];

      final List<HistoryDayGroup> groups = HistoryLog.groupByDay(
        list,
        now: now,
      );

      expect(groups.map((HistoryDayGroup group) => group.label), <String>[
        'Today',
        'Yesterday',
        '1 Mar 2024',
        '31 Dec 2023',
      ]);
      expect(groups[0].day, DateTime(2024, 3, 10));
      expect(groups[0].entries, <HistoryEntry>[todayLate, todayEarly]);
      expect(groups[1].entries, <HistoryEntry>[yesterday]);
      expect(groups[2].entries, <HistoryEntry>[marchFirst]);
      expect(groups[3].entries, <HistoryEntry>[newYearsEve]);
    });

    test('Yesterday works across a month and year boundary', () {
      final List<HistoryDayGroup> groups = HistoryLog.groupByDay(<HistoryEntry>[
        entry(0, createdAt: DateTime(2023, 12, 31, 22)),
      ], now: DateTime(2024, 1, 1, 1));

      expect(groups.single.label, 'Yesterday');
    });

    test('an empty history has no groups', () {
      expect(HistoryLog.groupByDay(<HistoryEntry>[], now: now), isEmpty);
    });
  });

  group('search and clipboard text', () {
    final HistoryEntry sum = entry(0, expression: '1800 + 21');
    final HistoryEntry percent = entry(
      1,
      expression: '15% of 4800',
      mode: HistoryMode.scientific,
    );

    test('matches the expression or the result, ignoring case', () {
      final List<HistoryEntry> list = <HistoryEntry>[sum, percent];

      expect(HistoryLog.search(list, '1800'), <HistoryEntry>[sum]);
      expect(HistoryLog.search(list, '4800'), <HistoryEntry>[percent]);
      expect(HistoryLog.search(list, '2'), <HistoryEntry>[sum]);
      expect(HistoryLog.search(list, '  '), same(list));
      expect(HistoryLog.search(list, 'nothing'), isEmpty);
    });

    test('entryText uses an ASCII minus for copying', () {
      final HistoryEntry negative = entry(2, expression: '5 − 9');

      expect(HistoryLog.entryText(negative), '5 - 9 = 4');
    });

    test('asText joins one line per entry, newest first', () {
      final List<HistoryEntry> list = <HistoryEntry>[sum, percent];

      expect(
        HistoryLog.asText(list),
        '${HistoryLog.entryText(sum)}\n'
        '${HistoryLog.entryText(percent)}',
      );
      expect(HistoryLog.asText(<HistoryEntry>[]), '');
    });
  });

  group('JSON', () {
    test('round-trips the list', () {
      final List<HistoryEntry> list = <HistoryEntry>[
        entry(0, mode: HistoryMode.converter),
        entry(1, mode: HistoryMode.tool),
      ];

      expect(HistoryLog.decode(HistoryLog.encode(list)), list);
    });

    test('empty and corrupt values read as an empty history', () {
      expect(HistoryLog.decode(null), isEmpty);
      expect(HistoryLog.decode(''), isEmpty);
      expect(HistoryLog.decode('not json'), isEmpty);
      expect(HistoryLog.decode('{}'), isEmpty);
      expect(HistoryLog.decode('[1, "x", null]'), isEmpty);
    });

    test('skips unusable rows but keeps the rest', () {
      final String good = HistoryLog.encode(<HistoryEntry>[entry(0)]);
      final String source =
          '[{"id":"a"}, ${good.substring(1, good.length - 1)}]';

      expect(HistoryLog.decode(source), <HistoryEntry>[entry(0)]);
    });

    test('caps a stored list at 500', () {
      final String source = HistoryLog.encode(entries(501));

      final List<HistoryEntry> decoded = HistoryLog.decode(source);

      expect(decoded, hasLength(500));
      expect(decoded.first, entry(0));
      expect(decoded.last, entry(499));
    });
  });
}
