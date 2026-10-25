import 'dart:math' as math;

import 'package:decimal/decimal.dart';

import 'angle_mode.dart';
import 'ast.dart';
import 'calc_result.dart';
import 'token.dart';

final Decimal _pi = Decimal.parse('3.14159265358979323846');
final Decimal _e = Decimal.parse('2.71828182845904523536');
final Decimal _overflowLimit = Decimal.parse('1e300');
final Decimal _hundredth = Decimal.parse('0.01');
final Decimal _snapLimit = Decimal.parse('1e-12');
final Decimal _minusOne = Decimal.fromInt(-1);
final Decimal _ninety = Decimal.fromInt(90);
final Decimal _oneEighty = Decimal.fromInt(180);
final Decimal _maxExactExponent = Decimal.fromInt(1000);
final Decimal _maxFactorial = Decimal.fromInt(170);

/// Evaluates an AST with exact [Decimal] arithmetic (BUSINESS_LOGIC §2, §4, §6).
///
/// Trig functions honour [angleMode] (DEG by default, like the app).
CalcResult evaluate(Node node, {AngleMode angleMode = AngleMode.deg}) {
  switch (node) {
    case NumberNode(:final Decimal value):
      return _check(value);
    case ConstNode(:final MathConstant constant):
      return Success(_constant(constant));
    case UnaryNode(:final bool negative, :final Node operand):
      final CalcResult inner = evaluate(operand, angleMode: angleMode);
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
      return _binary(operator, left, right, angleMode);
    case PostfixNode(:final PostfixType postfix, :final Node operand):
      final CalcResult inner = evaluate(operand, angleMode: angleMode);
      if (inner is Failure) {
        return inner;
      }
      return _postfix(postfix, (inner as Success).value);
    case FuncNode(:final String name, :final Node argument):
      return _function(name, argument, angleMode);
  }
}

CalcResult _binary(
  OperatorType operator,
  Node left,
  Node right,
  AngleMode angleMode,
) {
  final CalcResult leftResult = evaluate(left, angleMode: angleMode);
  if (leftResult is Failure) {
    return leftResult;
  }
  final Decimal a = (leftResult as Success).value;

  // §4: `%` after the right operand of + or − is taken of the left operand.
  if ((operator == OperatorType.add || operator == OperatorType.subtract) &&
      right is PostfixNode &&
      right.postfix == PostfixType.percent) {
    final CalcResult percentResult = evaluate(
      right.operand,
      angleMode: angleMode,
    );
    if (percentResult is Failure) {
      return percentResult;
    }
    final Decimal percent = (percentResult as Success).value;
    final Decimal delta = _percentOf(a * percent);
    return _check(operator == OperatorType.add ? a + delta : a - delta);
  }

  final CalcResult rightResult = evaluate(right, angleMode: angleMode);
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
    OperatorType.power => _power(a, b),
    OperatorType.root => _nthRoot(a, b),
    // `mod` belongs to programmer mode (integer Word), not the Decimal engine.
    OperatorType.mod => const Failure(CalcError.syntax),
  };
}

CalcResult _postfix(PostfixType postfix, Decimal value) => switch (postfix) {
  PostfixType.percent => _check(_percentOf(value)),
  PostfixType.factorial => _factorial(value),
  PostfixType.square => _check(value * value),
  PostfixType.cube => _check(value * value * value),
  PostfixType.reciprocal =>
    value == Decimal.zero
        ? const Failure(CalcError.divideByZero)
        : _check(
            (Decimal.one / value).toDecimal(scaleOnInfinitePrecision: 32),
          ),
};

CalcResult _function(String name, Node argument, AngleMode angleMode) {
  final CalcResult argumentResult = evaluate(argument, angleMode: angleMode);
  if (argumentResult is Failure) {
    return argumentResult;
  }
  final Decimal x = (argumentResult as Success).value;

  return switch (name) {
    'sin' => _trig(x, angleMode: angleMode, fn: math.sin),
    'cos' => _trig(x, angleMode: angleMode, fn: math.cos),
    'tan' => _tan(x, angleMode),
    'sin⁻¹' => _inverseTrig(
      x,
      angleMode: angleMode,
      fn: math.asin,
      bounded: true,
    ),
    'cos⁻¹' => _inverseTrig(
      x,
      angleMode: angleMode,
      fn: math.acos,
      bounded: true,
    ),
    'tan⁻¹' => _inverseTrig(
      x,
      angleMode: angleMode,
      fn: math.atan,
      bounded: false,
    ),
    'ln' =>
      x <= Decimal.zero
          ? const Failure(CalcError.domain)
          : _fromDouble(math.log(x.toDouble())),
    'log' =>
      x <= Decimal.zero
          ? const Failure(CalcError.domain)
          : _fromDouble(math.log(x.toDouble()) / math.ln10),
    'eˣ' => _fromDouble(math.exp(x.toDouble())),
    '10ˣ' => _fromDouble(math.pow(10, x.toDouble()).toDouble()),
    '√' => _root(x, cube: false),
    '∛' => _root(x, cube: true),
    _ => const Failure(CalcError.syntax),
  };
}

/// §6: integer exponents use exact Decimal `pow`; other cases go via double.
CalcResult _power(Decimal base, Decimal exponent) {
  if (base == Decimal.zero && exponent == Decimal.zero) {
    return Success(Decimal.one);
  }
  if (exponent.isInteger && exponent.abs() <= _maxExactExponent) {
    if (base == Decimal.zero && exponent.sign < 0) {
      return const Failure(CalcError.divideByZero);
    }
    final exact = base.pow(exponent.toBigInt().toInt());
    return _check(exact.toDecimal(scaleOnInfinitePrecision: 32));
  }
  if (base.sign < 0) {
    return const Failure(CalcError.domain);
  }
  return _fromDouble(math.pow(base.toDouble(), exponent.toDouble()).toDouble());
}

/// §6: `ʸ√x` — the [degree]-th root of [radicand], i.e. `radicand^(1/degree)`.
///
/// A negative radicand is only real for an odd integer degree (`∛(−8) = −2`).
CalcResult _nthRoot(Decimal radicand, Decimal degree) {
  if (degree == Decimal.zero) {
    return const Failure(CalcError.divideByZero);
  }
  final Decimal exponent = (Decimal.one / degree).toDecimal(
    scaleOnInfinitePrecision: 32,
  );
  if (radicand < Decimal.zero) {
    if (!degree.isInteger || degree.toBigInt().isEven) {
      return const Failure(CalcError.domain);
    }
    final CalcResult positive = _power(-radicand, exponent);
    return positive is Failure ? positive : _check(-(positive as Success).value);
  }
  return _power(radicand, exponent);
}

/// §2: perfect squares/cubes of small Decimals come back exact because the
/// 15-significant-digit rounding removes the IEEE noise (e.g. `√144 = 12`).
CalcResult _root(Decimal x, {required bool cube}) {
  if (!cube && x < Decimal.zero) {
    return const Failure(CalcError.domain);
  }
  final double input = x.toDouble();
  final double result = cube
      ? (input < 0
            ? -math.pow(-input, 1 / 3).toDouble()
            : math.pow(input, 1 / 3).toDouble())
      : math.sqrt(input);
  return _fromDouble(result);
}

/// §6: `n!` is exact for a non-negative integer up to 170; larger overflows.
CalcResult _factorial(Decimal value) {
  if (!value.isInteger || value.sign < 0) {
    return const Failure(CalcError.domain);
  }
  if (value > _maxFactorial) {
    return const Failure(CalcError.overflow);
  }
  BigInt result = BigInt.one;
  final int n = value.toBigInt().toInt();
  for (int i = 2; i <= n; i++) {
    result *= BigInt.from(i);
  }
  return _check(Decimal.fromBigInt(result));
}

/// §6: `tan` is undefined at 90° + k·180° (or where cos ≈ 0 in RAD).
CalcResult _tan(Decimal x, AngleMode angleMode) {
  if (angleMode.isDegrees) {
    if (x % _oneEighty == _ninety) {
      return const Failure(CalcError.domain);
    }
  } else if (math.cos(x.toDouble()).abs() < 1e-12) {
    return const Failure(CalcError.domain);
  }
  return _trig(x, angleMode: angleMode, fn: math.tan);
}

CalcResult _trig(
  Decimal x, {
  required AngleMode angleMode,
  required double Function(double) fn,
}) {
  final double input = angleMode.isDegrees
      ? x.toDouble() * math.pi / 180
      : x.toDouble();
  return _fromDouble(fn(input));
}

CalcResult _inverseTrig(
  Decimal x, {
  required AngleMode angleMode,
  required double Function(double) fn,
  required bool bounded,
}) {
  if (bounded && (x < _minusOne || x > Decimal.one)) {
    return const Failure(CalcError.domain);
  }
  final double raw = fn(x.toDouble());
  final double value = angleMode.isDegrees ? raw * 180 / math.pi : raw;
  return _fromDouble(value);
}

/// §2: check NaN/infinity, round to 15 significant digits, then snap to 0.
CalcResult _fromDouble(double result) {
  if (result.isNaN) {
    return const Failure(CalcError.domain);
  }
  if (result.isInfinite) {
    return const Failure(CalcError.overflow);
  }
  Decimal value = Decimal.parse(result.toStringAsPrecision(15));
  if (value.abs() < _snapLimit) {
    value = Decimal.zero;
  }
  return _check(value);
}

CalcResult _check(Decimal value) => value.abs() >= _overflowLimit
    ? const Failure(CalcError.overflow)
    : Success(value);

Decimal _percentOf(Decimal value) => value * _hundredth;

Decimal _constant(MathConstant constant) => switch (constant) {
  MathConstant.pi => _pi,
  MathConstant.e => _e,
};
