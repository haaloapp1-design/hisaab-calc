/// One saved calculation (BUSINESS_LOGIC §10).
///
/// Pure Dart: the history controller persists it, the page renders it.
library;

/// Where the entry came from; stored by `name`.
///
/// The first three match the calculator modes, [converter] and [tool] are
/// results saved from other screens (SPEC §2).
enum HistoryMode { basic, scientific, programmer, converter, tool }

/// A single history row: the expression, its result and when it was made.
///
/// [createdAt] is kept in UTC so the stored ISO string is stable; the UI calls
/// `toLocal()` before grouping or showing it.
final class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.expression,
    required this.result,
    required this.mode,
    required this.createdAt,
  });

  /// Builds an entry with an id derived from [createdAt].
  ///
  /// Two entries made in the same microsecond would share an id; real key
  /// presses are milliseconds apart, and stored ids are only used for delete.
  factory HistoryEntry.create({
    required String expression,
    required String result,
    required HistoryMode mode,
    required DateTime createdAt,
  }) {
    final DateTime utc = createdAt.toUtc();
    return HistoryEntry(
      id: '${utc.microsecondsSinceEpoch}',
      expression: expression,
      result: result,
      mode: mode,
      createdAt: utc,
    );
  }

  final String id;
  final String expression;
  final String result;
  final HistoryMode mode;
  final DateTime createdAt;

  /// True when [other] is the same calculation (ignores id and time);
  /// §10 skips an entry identical to the previous one.
  bool sameCalculation(HistoryEntry other) =>
      expression == other.expression &&
      result == other.result &&
      mode == other.mode;

  /// The persisted form of this entry.
  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'expression': expression,
    'result': result,
    'mode': mode.name,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  /// Reads one stored entry, or null when it is unusable.
  ///
  /// A row written by another build (missing keys, unknown mode, bad date) is
  /// dropped instead of throwing or guessing its mode; [HistoryLog.decode]
  /// keeps the rest of the list.
  static HistoryEntry? fromJson(Map<String, Object?> json) {
    final Object? id = json['id'];
    final Object? expression = json['expression'];
    final Object? result = json['result'];
    final Object? createdAt = json['createdAt'];
    if (id is! String || id.isEmpty) {
      return null;
    }
    if (expression is! String || result is! String) {
      return null;
    }
    final DateTime? moment = createdAt is String
        ? DateTime.tryParse(createdAt)
        : null;
    final HistoryMode? mode = _modeByName(json['mode']);
    if (moment == null || mode == null) {
      return null;
    }
    return HistoryEntry(
      id: id,
      expression: expression,
      result: result,
      mode: mode,
      createdAt: moment.toUtc(),
    );
  }

  static HistoryMode? _modeByName(Object? name) {
    for (final HistoryMode mode in HistoryMode.values) {
      if (mode.name == name) {
        return mode;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is HistoryEntry &&
      other.id == id &&
      other.expression == expression &&
      other.result == result &&
      other.mode == mode &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, expression, result, mode, createdAt);

  @override
  String toString() =>
      'HistoryEntry($id, ${mode.name}, $expression = $result, '
      '${createdAt.toIso8601String()})';
}
