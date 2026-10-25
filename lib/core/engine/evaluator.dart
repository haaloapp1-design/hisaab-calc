import 'package:decimal/decimal.dart';

import 'ast.dart';
import 'calc_result.dart';
import 'token.dart';

final Decimal _pi = Decimal.parse('3.14159265358979323846');
final Decimal _e = Decimal.parse('2.71828182845904523536');
final Decimal _overflowLimit = Decimal.parse('1e300');
final Decimal _hundredth = Decimal.parse('0.01');

/// Evaluates an AST with exact [Decimal] arithmetic (BUSINESS_LOGIC §2, §4).
///
/// T10 covers `+ − × ÷`, unary signs, constants and percent. Powers, factorial
/// and functions arrive in T11–T12 and currently report `CalcError.syntax`
/// instead of throwing.
CalcResult evaluate(Node node) {
  switch (node) {
    case NumberNode(:final Decimal value):
      return _check(value);
    case ConstNode(:final MathConstant constant):
      return Success(_constant(constant));
    case UnaryNode(:final bool negative, :final Node operand):
      final CalcResult inner = evaluate(operand);
      if (inner is Failure) {
        return inner;
      }
      final Decimal value = (inner as Success).value;
      return _check(negative ? -value : value);
    case BinaryNode(
      :final OperatorType operator,
      :final Node left,
      :final Node right,
    ):
      return _binary(operator, left, right);
    case PostfixNode(:final PostfixType postfix, :final Node operand):
      final CalcResult inner = evaluate(operand);
      if (inner is Failure) {
        return inner;
      }
      final Decimal value = (inner as Success).value;
      return switch (postfix) {
        PostfixType.percent => _check(_percentOf(value)),
        // Factorial, square and cube arrive in T12.
        PostfixType.factorial ||
        PostfixType.square ||
        PostfixType.cube => const Failure(CalcError.syntax),
      };
    case FuncNode():
      return const Failure(CalcError.syntax);
  }
}

CalcResult _binary(OperatorType operator, Node left, Node right) {
  final CalcResult leftResult = evaluate(left);
  if (leftResult is Failure) {
    return leftResult;
  }
  final Decimal a = (leftResult as Success).value;

  // §4: `%` after the right operand of + or − is taken of the left operand.
  if ((operator == OperatorType.add || operator == OperatorType.subtract) &&
      right is PostfixNode &&
      right.postfix == PostfixType.percent) {
    final CalcResult percentResult = evaluate(right.operand);
    if (percentResult is Failure) {
      return percentResult;
    }
    final Decimal percent = (percentResult as Success).value;
    final Decimal delta = _percentOf(a * percent);
    return _check(operator == OperatorType.add ? a + delta : a - delta);
  }

  final CalcResult rightResult = evaluate(right);
  if (rightResult is Failure) {
    return rightResult;
  }
  final Decimal b = (rightResult as Success).value;

  return switch (operator) {
    OperatorType.add => _check(a + b),
    OperatorType.subtract => _check(a - b),
    OperatorType.multiply => _check(a * b),
    OperatorType.divide =>
      b == Decimal.zero
          ? const Failure(CalcError.divideByZero)
          : _check((a / b).toDecimal(scaleOnInfinitePrecision: 32)),
    // Powers and mod are added in T12.
    OperatorType.power || OperatorType.mod => const Failure(CalcError.syntax),
  };
}

CalcResult _check(Decimal value) => value.abs() >= _overflowLimit
    ? const Failure(CalcError.overflow)
    : Success(value);

Decimal _percentOf(Decimal value) => value * _hundredth;

Decimal _constant(MathConstant constant) => switch (constant) {
  MathConstant.pi => _pi,
  MathConstant.e => _e,
};
