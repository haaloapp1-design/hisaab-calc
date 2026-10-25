import 'package:decimal/decimal.dart';

import '../engine/angle_mode.dart';
import '../engine/calc_engine.dart';
import '../engine/calc_result.dart';
import '../engine/token.dart';
import 'value_tokens.dart';

/// The operator and right operand that a repeated `=` applies
/// (BUSINESS_LOGIC §5).
final class LastOperation {
  const LastOperation({required this.operator, required this.rightTokens});

  final OperatorType operator;

  /// The tokens to the right of [operator], for example `[3]` in `5+3`.
  final List<Token> rightTokens;

  /// Finds the last binary operator outside every bracket, with the tokens
  /// after it. Returns null when there is nothing to repeat (a bare number, an
  /// expression ending in an operator, or no operator at all).
  static LastOperation? of(List<Token> tokens) {
    int depth = 0;
    int operatorIndex = -1;

    for (int i = 0; i < tokens.length; i++) {
      final Token token = tokens[i];
      if (token is LeftParenToken || token is FunctionToken) {
        depth++;
      } else if (token is RightParenToken) {
        depth--;
      } else if (depth == 0 && token is OperatorToken) {
        operatorIndex = i;
      }
    }

    if (operatorIndex < 0 || operatorIndex == tokens.length - 1) {
      return null;
    }
    return LastOperation(
      operator: (tokens[operatorIndex] as OperatorToken).operator,
      rightTokens: List<Token>.unmodifiable(tokens.sublist(operatorIndex + 1)),
    );
  }

  /// Applies `left <operator> right` as a fresh expression.
  CalcResult apply(Decimal left, {AngleMode angleMode = AngleMode.deg}) {
    return CalcEngine.evaluate(<Token>[
      ...valueTokens(left),
      OperatorToken(operator),
      ...rightTokens,
    ], angleMode: angleMode);
  }

  @override
  bool operator ==(Object other) =>
      other is LastOperation &&
      other.operator == operator &&
      other.rightTokens.length == rightTokens.length &&
      _sameTokens(other.rightTokens, rightTokens);

  @override
  int get hashCode => Object.hash(operator, Object.hashAll(rightTokens));

  @override
  String toString() => 'LastOperation(${operator.name}, $rightTokens)';

  static bool _sameTokens(List<Token> a, List<Token> b) {
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
