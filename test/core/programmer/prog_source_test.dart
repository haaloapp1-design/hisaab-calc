import 'package:calculator/core/programmer/prog_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('appendDigit', () {
    test('builds a number in any base', () {
      expect(ProgSource.appendDigit('', '1'), '1');
      expect(ProgSource.appendDigit('1', '2'), '12');
      expect(ProgSource.appendDigit('FF', 'A'), 'FFA');
      expect(ProgSource.appendDigit('5 + ', '3'), '5 + 3');
      expect(ProgSource.appendDigit('NOT ', '5'), 'NOT 5');
    });

    test('adds an explicit × after a closing bracket', () {
      expect(ProgSource.appendDigit('(5)', '3'), '(5) × 3');
    });
  });

  group('appendOperator', () {
    test('spaces a binary operator on both sides', () {
      expect(ProgSource.appendOperator('5', '+'), '5 + ');
      expect(ProgSource.appendOperator('5', 'AND'), '5 AND ');
      expect(ProgSource.appendOperator('FF', '<<'), 'FF << ');
    });

    test('replaces an operator the user already tapped', () {
      expect(ProgSource.appendOperator('5 + ', '×'), '5 × ');
      expect(ProgSource.appendOperator('5 AND ', 'OR'), '5 OR ');
      expect(ProgSource.appendOperator('5 mod ', '÷'), '5 ÷ ');
    });

    test('a leading − is a sign, other operators need a value', () {
      expect(ProgSource.appendOperator('', '−'), '−');
      expect(ProgSource.appendOperator('', '+'), '');
      expect(ProgSource.appendOperator('5 + ', '−'), '5 − ');
      expect(ProgSource.appendOperator('5 + −', '×'), '5 × ');
    });

    test('an open bracket takes the operator without a space', () {
      expect(ProgSource.appendOperator('(', '−'), '(− ');
      expect(ProgSource.appendOperator('5 × (', '−'), '5 × (− ');
    });
  });

  group('appendNot', () {
    test('prefixes the next value', () {
      expect(ProgSource.appendNot(''), 'NOT ');
      expect(ProgSource.appendNot('5 AND '), '5 AND NOT ');
      expect(ProgSource.appendNot('('), '(NOT ');
    });

    test(
      'inserts a × after a value because the engine has no implicit one',
      () {
        expect(ProgSource.appendNot('5'), '5 × NOT ');
        expect(ProgSource.appendNot('(5)'), '(5) × NOT ');
      },
    );
  });

  group('brackets', () {
    test('opening a bracket after a value multiplies', () {
      expect(ProgSource.appendOpenParen(''), '(');
      expect(ProgSource.appendOpenParen('5'), '5 × (');
      expect(ProgSource.appendOpenParen('5 + '), '5 + (');
      expect(ProgSource.appendOpenParen('('), '((');
    });

    test('closing needs an open bracket and a value', () {
      expect(ProgSource.appendCloseParen('(5'), '(5)');
      expect(ProgSource.appendCloseParen('((5)'), '((5))');
      expect(ProgSource.appendCloseParen('5'), '5');
      expect(ProgSource.appendCloseParen('(5 + '), '(5 + ');
      expect(ProgSource.appendCloseParen('(5)'), '(5)');
    });
  });

  group('backspace', () {
    test('removes one digit or bracket', () {
      expect(ProgSource.backspace('123'), '12');
      expect(ProgSource.backspace('FF'), 'F');
      expect(ProgSource.backspace('(5)'), '(5');
      expect(ProgSource.backspace(''), '');
    });

    test('removes a whole operator keyword in one step', () {
      expect(ProgSource.backspace('5 + '), '5');
      expect(ProgSource.backspace('5 AND '), '5');
      expect(ProgSource.backspace('5 NAND '), '5');
      expect(ProgSource.backspace('NOT '), '');
      expect(ProgSource.backspace('5 << '), '5');
    });
  });

  group('toggleSign', () {
    test('wraps the number being typed', () {
      expect(ProgSource.toggleSign(''), '−');
      expect(ProgSource.toggleSign('5'), '−5');
      expect(ProgSource.toggleSign('−5'), '5');
      expect(ProgSource.toggleSign('FF'), '−FF');
      expect(ProgSource.toggleSign('−FF'), 'FF');
    });

    test('signs the next number after an operator', () {
      expect(ProgSource.toggleSign('5 + '), '5 + −');
      expect(ProgSource.toggleSign('5 + −'), '5 +');
      expect(ProgSource.toggleSign('−'), '');
      expect(ProgSource.toggleSign('NOT '), 'NOT −');
    });

    test('does not mistake a subtraction for a sign', () {
      expect(ProgSource.toggleSign('5 − 3'), '5 − −3');
      expect(ProgSource.toggleSign('5 + −3'), '5 + 3');
      expect(ProgSource.toggleSign('5 − −3'), '5 − 3');
    });

    test('wraps and unwraps a bracketed group', () {
      expect(ProgSource.toggleSign('(5 − 3)'), '−(5 − 3)');
      expect(ProgSource.toggleSign('−(5 − 3)'), '(5 − 3)');
      expect(ProgSource.toggleSign('2 × (5 − 3)'), '2 × −(5 − 3)');
    });
  });
}
