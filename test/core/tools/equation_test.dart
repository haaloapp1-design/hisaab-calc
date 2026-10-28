import 'package:calculator/core/tools/equation.dart';
import 'package:calculator/core/tools/tool_format.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Decimal d(String source) => Decimal.parse(source);

  String root(EquationRoot root) => root.isComplex
      ? '${formatToolNumber(root.real)} '
            '${root.imaginary.sign < 0 ? '−' : '+'} '
            '${formatToolNumber(root.imaginary.abs())}i'
      : formatToolNumber(root.real);

  test('2x − 8 = 0 has the root 4', () {
    final EquationResult result = EquationSolver.linear(a: d('2'), b: d('-8'));

    expect(result.type, EquationType.oneRoot);
    expect(result.roots, hasLength(1));
    expect(formatToolNumber(result.roots.single.real), '4.00');
    expect(result.roots.single.isComplex, isFalse);
    expect(result.c, isNull);
    expect(result.discriminant, isNull);
    expect(result.isLinearFallback, isFalse);
  });

  test('3x + 1 = 0 has the root −1/3', () {
    final EquationResult result = EquationSolver.linear(a: d('3'), b: d('1'));

    expect(formatToolNumber(result.roots.single.real), '−0.33');
  });

  test('a = 0 with b ≠ 0 has no solution', () {
    final EquationResult result = EquationSolver.linear(
      a: Decimal.zero,
      b: d('5'),
    );

    expect(result.type, EquationType.noSolution);
    expect(result.roots, isEmpty);
    expect(result.hasRoots, isFalse);
  });

  test('a = 0 and b = 0 is true for every x', () {
    final EquationResult result = EquationSolver.linear(
      a: Decimal.zero,
      b: Decimal.zero,
    );

    expect(result.type, EquationType.everyX);
    expect(result.roots, isEmpty);
  });

  test('x² − 3x + 2 = 0 has D = 1 and the roots 1 and 2', () {
    final EquationResult result = EquationSolver.quadratic(
      a: d('1'),
      b: d('-3'),
      c: d('2'),
    );

    expect(result.type, EquationType.twoRoots);
    expect(result.discriminant, d('1'));
    expect(result.roots.map(root), <String>['1.00', '2.00']);
    expect(result.roots.every((EquationRoot r) => !r.isComplex), isTrue);
    expect(result.isLinearFallback, isFalse);
  });

  test('D = 0 gives one repeated root', () {
    final EquationResult result = EquationSolver.quadratic(
      a: d('1'),
      b: d('-2'),
      c: d('1'),
    );

    expect(result.type, EquationType.oneRoot);
    expect(result.discriminant, Decimal.zero);
    expect(result.roots.map(root), <String>['1.00']);
  });

  test('D < 0 gives two complex-conjugate roots', () {
    final EquationResult result = EquationSolver.quadratic(
      a: d('1'),
      b: d('-3'),
      c: d('2.5'),
    );

    expect(result.type, EquationType.complexRoots);
    expect(result.discriminant, d('-1'));
    expect(result.roots.map(root), <String>['1.50 + 0.50i', '1.50 − 0.50i']);
    expect(result.roots[0].imaginary, d('0.5'));
    expect(result.roots[1].imaginary, d('-0.5'));
  });

  test(
    'a negative leading coefficient keeps the imaginary parts symmetric',
    () {
      final EquationResult result = EquationSolver.quadratic(
        a: d('-1'),
        b: d('3'),
        c: d('-2.5'),
      );

      expect(result.type, EquationType.complexRoots);
      expect(result.roots.map(root), <String>['1.50 + 0.50i', '1.50 − 0.50i']);
    },
  );

  test('irrational roots are sorted and rounded for display', () {
    final EquationResult result = EquationSolver.quadratic(
      a: d('1'),
      b: d('2'),
      c: d('-1'),
    );

    expect(result.discriminant, d('8'));
    expect(result.roots.map(root), <String>['−2.41', '0.41']);
  });

  test('a negative a still sorts the real roots ascending', () {
    final EquationResult result = EquationSolver.quadratic(
      a: d('-1'),
      b: Decimal.zero,
      c: d('4'),
    );

    expect(result.roots.map(root), <String>['−2.00', '2.00']);
  });

  test('a = 0 in a quadratic falls back to the linear equation', () {
    final EquationResult result = EquationSolver.quadratic(
      a: Decimal.zero,
      b: d('2'),
      c: d('-8'),
    );

    expect(result.type, EquationType.oneRoot);
    expect(result.isLinearFallback, isTrue);
    expect(result.c, d('-8'));
    expect(result.discriminant, isNull);
    expect(result.roots.map(root), <String>['4.00']);
  });

  test('a = 0 with b = 0 keeps the no-solution and every-x cases', () {
    expect(
      EquationSolver.quadratic(
        a: Decimal.zero,
        b: Decimal.zero,
        c: d('5'),
      ).type,
      EquationType.noSolution,
    );
    expect(
      EquationSolver.quadratic(
        a: Decimal.zero,
        b: Decimal.zero,
        c: Decimal.zero,
      ).type,
      EquationType.everyX,
    );
  });

  test('the result prints its type, roots and discriminant', () {
    final EquationResult result = EquationSolver.quadratic(
      a: d('1'),
      b: d('-3'),
      c: d('2'),
    );

    expect(result.toString(), contains('twoRoots'));
    expect(result.toString(), contains('1'));
    expect(result.toString(), contains('2'));
  });
}
