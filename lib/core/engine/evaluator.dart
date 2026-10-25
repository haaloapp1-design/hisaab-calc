import 'package:decimal/decimal.dart';

import 'ast.dart';
import 'calc_result.dart';
import 'token.dart';

final Decimal _pi = Decimal.parse('3.14159265358979323846');
final Decimal _e = Decimal.parse('2.71828182845904523536');
final Decimal _overflowLimit = Decimal.parse('1e300');

/// Evaluates an AST with exact [Decimal] arithmetic (BUSINESS_LOGIC §2).
///
/// T09 covers `+ − × ÷`, unary signs and constants. Percent, postfix,
/// powers and functions arrive in T10–T12 and currently report
/// `CalcError.syntax` instead of throwing.
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
    case FuncNode():
    case PostfixNode():
      return const Failure(CalcError.syntax);
  }
}

CalcResult _binary(OperatorType operator, Node left, Node right) {
  final CalcResult leftResult = evaluate(left);
  if (leftResult is Failure) {
    return leftResult;
  }
  final CalcResult rightResult = evaluate(right);
  if (rightResult is Failure) {
    return rightResult;
  }

  final Decimal a = (leftResult as Success).value;
  final Decimal b = (rightResult as Success).value;

  return switch (operator) {
    OperatorType.add => _check(a + b),
    OperatorType.subtract => _check(a - b),
    OperatorType.multiply => _check(a * b),
    OperatorType.divide =>
      b == Decimal.zero
          ? const Failure(CalcError.divideByZero)
          : _check((a / b).toDecimal(scaleOnInfinitePrecision: 32)),
    // Powers, mod, postfix and functions are added in T10–T12.
    OperatorType.power || OperatorType.mod => const Failure(CalcError.syntax),
  };
}

CalcResult _check(Decimal value) => value.abs() >= _overflowLimit
    ? const Failure(CalcError.overflow)
    : Success(value);

Decimal _constant(MathConstant constant) => switch (constant) {
  MathConstant.pi => _pi,
  MathConstant.e => _e,
};
