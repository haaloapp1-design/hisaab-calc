import 'package:calculator/features/history/history_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime at = DateTime(2024, 3, 9, 14, 30);

  HistoryEntry entry({
    String expression = '2 + 3',
    String result = '5',
    HistoryMode mode = HistoryMode.basic,
    DateTime? createdAt,
  }) => HistoryEntry.create(
    expression: expression,
    result: result,
    mode: mode,
    createdAt: createdAt ?? at,
  );

  test('create keeps UTC and derives the id from the moment', () {
    final HistoryEntry saved = entry();

    expect(saved.id, '${at.toUtc().microsecondsSinceEpoch}');
    expect(saved.createdAt.isUtc, isTrue);
    expect(saved.createdAt, at.toUtc());
    expect(saved.mode, HistoryMode.basic);
  });

  test('JSON round-trips every field', () {
    final HistoryEntry saved = entry(mode: HistoryMode.scientific);
    final Map<String, Object?> json = saved.toJson();

    expect(json['mode'], 'scientific');
    expect(json['createdAt'], at.toUtc().toIso8601String());
    expect(HistoryEntry.fromJson(json), saved);
  });

  test('a local ISO date is read back as the same moment in UTC', () {
    final Map<String, Object?> json = entry().toJson()
      ..['createdAt'] = '2024-03-09T14:30:00.000';

    final HistoryEntry? saved = HistoryEntry.fromJson(json);

    expect(saved, isNotNull);
    expect(saved!.createdAt.isUtc, isTrue);
    expect(saved.createdAt.toLocal(), DateTime(2024, 3, 9, 14, 30));
  });

  test('sameCalculation compares the maths, not the id or time', () {
    final HistoryEntry first = entry();
    final HistoryEntry later = entry(
      createdAt: at.add(const Duration(minutes: 5)),
    );

    expect(later.sameCalculation(first), isTrue);
    expect(later, isNot(first));
    expect(entry(result: '6').sameCalculation(first), isFalse);
    expect(entry(expression: '3 + 2').sameCalculation(first), isFalse);
    expect(entry(mode: HistoryMode.programmer).sameCalculation(first), isFalse);
  });

  test('equality covers every field', () {
    final HistoryEntry saved = entry();

    expect(saved, entry());
    expect(saved.hashCode, entry().hashCode);
    expect(saved.toString(), contains('2 + 3 = 5'));
  });

  group('fromJson rejects unusable rows', () {
    final Map<String, Object?> valid = entry().toJson();

    test('a valid row with extra keys is accepted', () {
      final Map<String, Object?> json = <String, Object?>{
        ...valid,
        'unexpected': true,
      };

      expect(HistoryEntry.fromJson(json), entry());
    });

    test('missing or empty id', () {
      expect(
        HistoryEntry.fromJson(
          <String, Object?>{}
            ..addAll(valid)
            ..remove('id'),
        ),
        isNull,
      );
      expect(
        HistoryEntry.fromJson(<String, Object?>{...valid, 'id': ''}),
        isNull,
      );
      expect(
        HistoryEntry.fromJson(<String, Object?>{...valid, 'id': 7}),
        isNull,
      );
    });

    test('non-string expression or result', () {
      expect(
        HistoryEntry.fromJson(<String, Object?>{...valid, 'expression': 2}),
        isNull,
      );
      expect(
        HistoryEntry.fromJson(<String, Object?>{...valid, 'result': null}),
        isNull,
      );
    });

    test('unknown mode', () {
      expect(
        HistoryEntry.fromJson(<String, Object?>{
          ...valid,
          'mode': 'spreadsheet',
        }),
        isNull,
      );
      expect(
        HistoryEntry.fromJson(<String, Object?>{...valid}..remove('mode')),
        isNull,
      );
    });

    test('missing or unparseable createdAt', () {
      expect(
        HistoryEntry.fromJson(<String, Object?>{...valid, 'createdAt': 'soon'}),
        isNull,
      );
      expect(
        HistoryEntry.fromJson(<String, Object?>{...valid, 'createdAt': 12}),
        isNull,
      );
    });
  });
}
