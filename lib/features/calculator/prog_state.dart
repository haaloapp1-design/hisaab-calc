import '../../core/engine/calc_result.dart';
import '../../core/programmer/base_format.dart';
import '../../core/programmer/word.dart';

/// Everything the Programmer screen renders (SPEC §1.4, BUSINESS_LOGIC §11).
///
/// The typed [source] is what the keypad builds (`FF AND 0F`); [value] is its
/// live result, re-masked into [size]. The four base rows and the big line are
/// formatted from [value], so switching [base] converts the value, never the
/// text.
final class ProgState {
  ProgState({
    this.source = '',
    Word? value,
    this.base = NumberBase.dec,
    this.size = WordSize.standard,
    this.error,
    this.justEvaluated = false,
  }) : value = value ?? Word.zero(size: size);

  /// The expression the user is typing, in `ProgEngine` spellings.
  final String source;

  /// The current value: the live result of [source], or the last good one.
  final Word value;

  /// The base the keypad types in and the big line shows.
  final NumberBase base;

  /// The word width; every result is re-masked into it (§11).
  final WordSize size;

  /// The error of the last failed `=`; typing clears it.
  final CalcError? error;

  /// §1.1 after `=`: the big line is committed and the expression hides.
  final bool justEvaluated;

  /// Line 1: hidden right after `=`, like the Basic display.
  String get expression => justEvaluated ? '' : source;

  /// Whether the big line is a live preview (typing) rather than committed.
  bool get preview =>
      !justEvaluated && source.trim().isNotEmpty && error == null;

  ProgState copyWith({
    String? source,
    Word? value,
    NumberBase? base,
    WordSize? size,
    CalcError? error,
    bool clearError = false,
    bool? justEvaluated,
  }) => ProgState(
    source: source ?? this.source,
    value: value ?? this.value,
    base: base ?? this.base,
    size: size ?? this.size,
    error: clearError ? null : (error ?? this.error),
    justEvaluated: justEvaluated ?? this.justEvaluated,
  );

  @override
  String toString() =>
      'ProgState("$source", ${value.signed}, ${base.label}, ${size.label}, '
      'error: $error, justEvaluated: $justEvaluated)';
}
