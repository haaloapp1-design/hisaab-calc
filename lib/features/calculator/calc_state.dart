import 'package:decimal/decimal.dart';

import '../../core/engine/angle_mode.dart';
import '../../core/engine/calc_engine.dart';
import '../../core/engine/calc_result.dart';
import '../../core/engine/token.dart';
import '../../core/input/input_buffer.dart';
import '../../core/input/last_operation.dart';

/// The three calculator modes the segmented switcher selects (SPEC §1).
enum CalcMode { basic, scientific, programmer }

/// Everything the calculator screen renders (ARCHITECTURE "State").
///
/// Immutable: a key produces a new [CalcState]. [preview] is the live result
/// of the unfinished expression, or null when there is nothing to preview
/// (BUSINESS_LOGIC §5). It stays a [Decimal] so the display can format it with
/// the current settings and memory keys (`M+`/`M−`) can use the same value.
final class CalcState {
  CalcState({
    this.buffer = const InputBuffer.empty(),
    this.preview,
    Decimal? ans,
    this.result,
    this.error,
    this.justEvaluated = false,
    this.lastOperation,
    this.mode = CalcMode.basic,
    this.angleMode = AngleMode.deg,
    this.second = false,
  }) : ans = ans ?? Decimal.zero;

  /// The tokens the user has typed so far.
  final InputBuffer buffer;

  /// §5 live preview: success only, never an error.
  final Decimal? preview;

  /// §9 the last `=` result, persisted between launches.
  final Decimal ans;

  /// The value of the last successful `=` (§5 `=` row).
  final Decimal? result;

  /// The error of the last failed `=`; the buffer is kept so it can be fixed.
  final CalcError? error;

  /// §5 after `=`: a digit/function/constant starts a new expression, an
  /// operator continues from the result.
  final bool justEvaluated;

  /// §5 the operator + right operand a second `=` repeats.
  final LastOperation? lastOperation;

  /// The mode the segmented switcher selected (persisted between launches).
  final CalcMode mode;

  /// §6 the unit trig functions use; the DEG/RAD chip drives it.
  final AngleMode angleMode;

  /// SPEC §1.3 `2nd`: swaps the scientific alternate labels and functions.
  final bool second;

  bool get isEmpty => buffer.isEmpty;

  /// SPEC §1.3 the number of brackets still open, shown in the badge.
  int get openBrackets {
    int count = 0;
    for (final Token token in buffer.tokens) {
      if (token is LeftParenToken || token is FunctionToken) {
        count++;
      } else if (token is RightParenToken && count > 0) {
        count--;
      }
    }
    return count;
  }

  /// A copy with different screen-level settings; the buffer and its values
  /// are untouched. Only the three interface switches need replacing, so the
  /// nullable display fields keep their values.
  CalcState copyWith({CalcMode? mode, AngleMode? angleMode, bool? second}) =>
      CalcState(
        buffer: buffer,
        preview: preview,
        ans: ans,
        result: result,
        error: error,
        justEvaluated: justEvaluated,
        lastOperation: lastOperation,
        mode: mode ?? this.mode,
        angleMode: angleMode ?? this.angleMode,
        second: second ?? this.second,
      );

  /// The number the big display line shows (SPEC §1.1).
  ///
  /// The committed result wins, then the live preview. With neither (a plain
  /// number, `(−5)` or `π` before any operator) the value of what is typed so
  /// far is shown. An unfinished tail is trimmed until the rest evaluates, so
  /// `5 + 3 +` keeps showing `8` instead of dropping back to `3`.
  Decimal get displayValue {
    final Decimal? shown = result ?? preview;
    if (shown != null) {
      return shown;
    }

    final List<Token> tokens = List<Token>.of(buffer.tokens);
    while (tokens.isNotEmpty) {
      final CalcResult current = CalcEngine.evaluate(
        tokens,
        angleMode: angleMode,
      );
      if (current is Success) {
        return current.value;
      }
      tokens.removeLast();
    }
    return Decimal.zero;
  }

  @override
  String toString() =>
      'CalcState($buffer, preview: $preview, result: $result, '
      'error: $error, ans: $ans, mode: $mode)';
}
