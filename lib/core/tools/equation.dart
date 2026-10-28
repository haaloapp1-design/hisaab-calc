import 'dart:math' as math;

import 'package:decimal/decimal.dart';

/// The shape of an equation's solution set (§14 Equation solver).
enum EquationType {
  /// A single real root (a linear equation, or a quadratic with `D = 0`).
  oneRoot,

  /// Two distinct real roots (`D > 0`).
  twoRoots,

  /// Two complex-conjugate roots (`D < 0`).
  complexRoots,

  /// `a = 0` and `b ≠ 0`: no value of x works.
  noSolution,

  /// `a = 0` and `b = 0`: every value of x works.
  everyX,
}

/// One root of an equation.
final class EquationRoot {
  EquationRoot({required this.real, Decimal? imaginary})
    : imaginary = imaginary ?? Decimal.zero;

  /// The real part.
  final Decimal real;

  /// The imaginary part; zero for a real root.
  final Decimal imaginary;

  bool get isComplex => imaginary != Decimal.zero;

  @override
  String toString() => isComplex
      ? '$real ${imaginary.sign < 0 ? '−' : '+'} ${imaginary.abs()}i'
      : '$real';
}

/// The answer to one equation, with the coefficients that produced it.
final class EquationResult {
  const EquationResult({
    required this.type,
    required this.roots,
    required this.a,
    required this.b,
    this.c,
    this.discriminant,
    this.isLinearFallback = false,
  });

  final EquationType type;
  final List<EquationRoot> roots;
  final Decimal a;
  final Decimal b;

  /// The constant of a quadratic; null for a linear equation.
  final Decimal? c;

  /// `b² − 4ac` of a quadratic; null when the equation was linear.
  final Decimal? discriminant;

  /// True when a quadratic had `a = 0` and was solved as a linear equation.
  final bool isLinearFallback;

  bool get hasRoots => roots.isNotEmpty;

  @override
  String toString() =>
      'EquationResult($type, roots: ${roots.join(', ')}, D: $discriminant)';
}

/// The linear and quadratic formulas of §14.
///
/// Coefficients are [Decimal]s, so `ax + b = 0` stays exact. A quadratic
/// square root is irrational in general, so it goes through `double` and comes
/// back at 15 significant digits (the same precision the calculator uses).
abstract final class EquationSolver {
  static final Decimal _two = Decimal.fromInt(2);
  static final Decimal _four = Decimal.fromInt(4);

  /// `ax + b = 0`.
  static EquationResult linear({required Decimal a, required Decimal b}) {
    if (a == Decimal.zero) {
      return EquationResult(
        type: b == Decimal.zero ? EquationType.everyX : EquationType.noSolution,
        roots: const <EquationRoot>[],
        a: a,
        b: b,
      );
    }
    return EquationResult(
      type: EquationType.oneRoot,
      roots: <EquationRoot>[EquationRoot(real: _divide(-b, a))],
      a: a,
      b: b,
    );
  }

  /// `ax² + bx + c = 0`; an `a = 0` falls back to [linear].
  static EquationResult quadratic({
    required Decimal a,
    required Decimal b,
    required Decimal c,
  }) {
    if (a == Decimal.zero) {
      final EquationResult result = linear(a: b, b: c);
      return EquationResult(
        type: result.type,
        roots: result.roots,
        a: a,
        b: b,
        c: c,
        isLinearFallback: true,
      );
    }

    final Decimal discriminant = b * b - _four * a * c;
    final Decimal denominator = _two * a;

    if (discriminant < Decimal.zero) {
      final Decimal real = _divide(-b, denominator);
      final Decimal imaginary = _divide(
        _sqrt(-discriminant),
        denominator,
      ).abs();
      return EquationResult(
        type: EquationType.complexRoots,
        roots: <EquationRoot>[
          EquationRoot(real: real, imaginary: imaginary),
          EquationRoot(real: real, imaginary: -imaginary),
        ],
        a: a,
        b: b,
        c: c,
        discriminant: discriminant,
      );
    }

    if (discriminant == Decimal.zero) {
      return EquationResult(
        type: EquationType.oneRoot,
        roots: <EquationRoot>[EquationRoot(real: _divide(-b, denominator))],
        a: a,
        b: b,
        c: c,
        discriminant: discriminant,
      );
    }

    final Decimal root = _sqrt(discriminant);
    final List<Decimal> roots = <Decimal>[
      _divide(-b + root, denominator),
      _divide(-b - root, denominator),
    ]..sort();
    return EquationResult(
      type: EquationType.twoRoots,
      roots: <EquationRoot>[
        for (final Decimal value in roots) EquationRoot(real: value),
      ],
      a: a,
      b: b,
      c: c,
      discriminant: discriminant,
    );
  }

  static Decimal _divide(Decimal a, Decimal b) =>
      (a / b).toDecimal(scaleOnInfinitePrecision: 32);

  /// The square root of a non-negative value at 15 significant digits.
  static Decimal _sqrt(Decimal value) {
    if (value == Decimal.zero) {
      return Decimal.zero;
    }
    final double result = math.sqrt(value.toDouble());
    return Decimal.parse(result.toStringAsPrecision(15));
  }
}
