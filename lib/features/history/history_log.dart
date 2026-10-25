import 'dart:convert';

import 'history_entry.dart';

/// One calendar day of history, newest day first (SPEC §2, §10).
final class HistoryDayGroup {
  const HistoryDayGroup({
    required this.day,
    required this.label,
    required this.entries,
  });

  /// Local midnight of the day this group covers.
  final DateTime day;

  /// `Today`, `Yesterday` or the day as `d MMM yyyy` (§10).
  final String label;

  /// Entries of that day, newest first.
  final List<HistoryEntry> entries;
}

/// Pure list helpers for history: add, delete, retention and grouping
/// (BUSINESS_LOGIC §10).
///
/// Every function returns the same list instance when nothing changed, so the
/// controller can tell "skipped" from "new list" without comparing contents.
abstract final class HistoryLog {
  /// §10 the newest 500 entries are kept.
  static const int maxEntries = 500;

  /// Puts [entry] at the front, skipping a repeat of the previous calculation
  /// and dropping anything past [maxEntries].
  static List<HistoryEntry> add(
    List<HistoryEntry> entries,
    HistoryEntry entry,
  ) {
    if (entries.isNotEmpty && entries.first.sameCalculation(entry)) {
      return entries;
    }
    final List<HistoryEntry> next = <HistoryEntry>[entry, ...entries];
    if (next.length > maxEntries) {
      next.removeRange(maxEntries, next.length);
    }
    return next;
  }

  /// Drops the entry with [id]; returns [entries] when it is not there.
  static List<HistoryEntry> remove(List<HistoryEntry> entries, String id) {
    final List<HistoryEntry> next = entries
        .where((HistoryEntry entry) => entry.id != id)
        .toList(growable: false);
    return next.length == entries.length ? entries : next;
  }

  /// Drops entries older than [retentionDays] days before [now]; null
  /// (Forever) keeps everything. Called on start-up (§10).
  static List<HistoryEntry> prune(
    List<HistoryEntry> entries, {
    required DateTime now,
    required int? retentionDays,
  }) {
    if (retentionDays == null) {
      return entries;
    }
    final DateTime cutoff = now.subtract(Duration(days: retentionDays));
    final List<HistoryEntry> next = entries
        .where(
          (HistoryEntry entry) => !entry.createdAt.toLocal().isBefore(cutoff),
        )
        .toList(growable: false);
    return next.length == entries.length ? entries : next;
  }

  /// Groups [entries] by their local calendar day, keeping the given order
  /// (the store is newest first) so the newest day is the first group.
  static List<HistoryDayGroup> groupByDay(
    List<HistoryEntry> entries, {
    required DateTime now,
  }) {
    final DateTime today = _dateOnly(now.toLocal());
    final List<HistoryDayGroup> groups = <HistoryDayGroup>[];

    for (final HistoryEntry entry in entries) {
      final DateTime day = _dateOnly(entry.createdAt.toLocal());
      if (groups.isEmpty || !groups.last.day.isAtSameMomentAs(day)) {
        groups.add(
          HistoryDayGroup(
            day: day,
            label: _label(day, today),
            entries: <HistoryEntry>[],
          ),
        );
      }
      groups.last.entries.add(entry);
    }
    return groups;
  }

  static DateTime _dateOnly(DateTime moment) =>
      DateTime(moment.year, moment.month, moment.day);

  /// The design language is English, so the day uses fixed month names and
  /// does not need intl's locale data loaded (which would throw on start-up
  /// for a device locale the app has not initialised).
  static const List<String> _months = <String>[
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

  static String _label(DateTime day, DateTime today) {
    if (day.isAtSameMomentAs(today)) {
      return 'Today';
    }
    final DateTime yesterday = DateTime(today.year, today.month, today.day - 1);
    if (day.isAtSameMomentAs(yesterday)) {
      return 'Yesterday';
    }
    return '${day.day} ${_months[day.month - 1]} ${day.year}';
  }

  /// The stored JSON array, newest first.
  static String encode(List<HistoryEntry> entries) =>
      jsonEncode(<Map<String, Object?>>[
        for (final HistoryEntry entry in entries) entry.toJson(),
      ]);

  /// Reads a stored array, skipping unusable rows, capping at [maxEntries].
  ///
  /// Missing, empty or corrupt data reads as an empty history: a bad value
  /// must never stop the app from starting.
  static List<HistoryEntry> decode(String? source) {
    if (source == null || source.isEmpty) {
      return const <HistoryEntry>[];
    }
    try {
      final Object? json = jsonDecode(source);
      if (json is! List<Object?>) {
        return const <HistoryEntry>[];
      }
      final List<HistoryEntry> entries = <HistoryEntry>[];
      for (final Object? row in json) {
        if (entries.length == maxEntries) {
          break;
        }
        if (row is! Map<String, Object?>) {
          continue;
        }
        final HistoryEntry? entry = HistoryEntry.fromJson(row);
        if (entry != null) {
          entries.add(entry);
        }
      }
      return entries;
    } on FormatException {
      return const <HistoryEntry>[];
    }
  }
}
