import 'angle_mode.dart';
import 'calc_result.dart';
import 'evaluator.dart' as evaluator;
import 'parser.dart';
import 'token.dart';
import 'tokenizer.dart';

/// The engine facade: tokens → AST → [CalcResult] (BUSINESS_LOGIC §1).
///
/// Nothing throws to the UI: tokenizer/parser [FormatException]s become
/// `Failure(CalcError.syntax)`.
abstract final class CalcEngine {
  /// Evaluates the tokens held by the input buffer.
  static CalcResult evaluate(
    List<Token> tokens, {
    AngleMode angleMode = AngleMode.deg,
  }) {
    try {
      return evaluator.evaluate(Parser(tokens).parse(), angleMode: angleMode);
    } on FormatException {
      return const Failure(CalcError.syntax);
    }
  }

  /// Evaluates a source string (paste, history, tests).
  static CalcResult evaluateSource(
    String source, {
    AngleMode angleMode = AngleMode.deg,
  }) {
    try {
      return evaluator.evaluate(
        Parser(tokenize(source)).parse(),
        angleMode: angleMode,
      );
    } on FormatException {
      return const Failure(CalcError.syntax);
    }
  }
}
