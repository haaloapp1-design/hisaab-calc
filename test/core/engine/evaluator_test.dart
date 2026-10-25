import 'package:calculator/core/engine/ast.dart';
import 'package:calculator/core/engine/calc_result.dart';
import 'package:calculator/core/engine/evaluator.dart';
import 'package:calculator/core/engine/parser.dart';
import 'package:calculator/core/engine/tokenizer.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

CalcResult eval(String source) => evaluate(Parser(tokenize(source)).parse());

Decimal valueOf(CalcResult result) => (result as Success).value;

void main() {
  group('arithmetic', () {
    test('0.1 + 0.2 is exactly 0.3', () {
      expect(eval('0.1+0.2'), Success(Decimal.parse('0.3')));
    });

    test('addition, subtraction and multiplication', () {
      expect(valueOf(eval('7−2×3')), Decimal.one);
      expect(valueOf(eval('(1+2)×3')), Decimal.fromInt(9));
      expect(valueOf(eval('2+3+4')), Decimal.fromInt(9));
    });

    test('unary signs', () {
      expect(valueOf(eval('−5+2')), Decimal.fromInt(-3));
      expect(valueOf(eval('+5')), Decimal.fromInt(5));
      expect(valueOf(eval('−−4')), Decimal.fromInt(4));
    });

    test('division keeps exact halves', () {
      expect(valueOf(eval('10÷4')), Decimal.parse('2.5'));
      expect(valueOf(eval('9÷3')), Decimal.fromInt(3));
    });

    test('1÷3×3 displays as 1 after the documented 12-place rounding', () {
      // Exact value is 0.999…9 (32 threes); §8 Auto rounds to 12 places → 1.
      final Decimal value = valueOf(eval('1÷3×3'));
      expect(value.round(scale: 12), Decimal.one);
    });
  });

  group('divide by zero', () {
    test('5÷0 fails', () {
      expect(eval('5÷0'), const Failure(CalcError.divideByZero));
    });

    test('0÷0 fails', () {
      expect(eval('0÷0'), const Failure(CalcError.divideByZero));
    });

    test('the failure propagates through the tree', () {
      expect(eval('1+5÷0'), const Failure(CalcError.divideByZero));
    });
  });

  group('constants', () {
    test('π and e keep 20 decimal places', () {
      expect(valueOf(eval('π')), Decimal.parse('3.14159265358979323846'));
      expect(valueOf(eval('e')), Decimal.parse('2.71828182845904523536'));
    });

    test('constants take part in arithmetic', () {
      expect(valueOf(eval('2π')), Decimal.parse('6.28318530717958647692'));
    });
  });

  group('percent (§4)', () {
    test('50% alone is 0.5', () {
      expect(eval('50%'), Success(Decimal.parse('0.5')));
    });

    test('percent after + or − is taken of the left operand', () {
      expect(valueOf(eval('200+10%')), Decimal.fromInt(220));
      expect(valueOf(eval('200−10%')), Decimal.fromInt(180));
    });

    test('percent after × or ÷ is a plain fraction', () {
      expect(valueOf(eval('200×10%')), Decimal.fromInt(20));
      expect(valueOf(eval('200÷10%')), Decimal.fromInt(2000));
    });

    test('the left operand may itself be an expression', () {
      expect(valueOf(eval('(100+100)+10%')), Decimal.fromInt(220));
      expect(valueOf(eval('(100+100)−10%')), Decimal.fromInt(180));
    });

    test('the percent amount may itself be an expression', () {
      expect(valueOf(eval('200+(10+5)%')), Decimal.fromInt(230));
      expect(valueOf(eval('200−(10+5)%')), Decimal.fromInt(170));
    });

    test('only the right operand of + or − gets the special case', () {
      expect(valueOf(eval('10%+200')), Decimal.parse('200.1'));
      expect(valueOf(eval('10%×200')), Decimal.fromInt(20));
    });

    test('left-associative chains apply the rule per step', () {
      // (200 + 10%) + 5 = 220 + 5
      expect(valueOf(eval('200+10%+5')), Decimal.fromInt(225));
      // (200 − 10%) − 5 = 180 − 5
      expect(valueOf(eval('200−10%−5')), Decimal.fromInt(175));
    });

    test('repeated percent divides by 100 twice', () {
      expect(valueOf(eval('50%%')), Decimal.parse('0.005'));
    });

    test('a failing left operand still propagates', () {
      expect(eval('1÷0+10%'), const Failure(CalcError.divideByZero));
    });
  });

  group('overflow', () {
    test('values at or above 1e300 fail', () {
      expect(
        evaluate(NumberNode(Decimal.parse('1e300'))),
        const Failure(CalcError.overflow),
      );
      expect(
        evaluate(NumberNode(Decimal.parse('1e301'))),
        const Failure(CalcError.overflow),
      );
      expect(evaluate(NumberNode(Decimal.parse('1e299'))), isA<Success>());
    });
  });
}
