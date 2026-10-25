import 'package:calculator/core/engine/ast.dart';
import 'package:calculator/core/engine/parser.dart';
import 'package:calculator/core/engine/token.dart';
import 'package:calculator/core/engine/tokenizer.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

NumberNode num(int value) => NumberNode(Decimal.fromInt(value));

Node add(Node left, Node right) => BinaryNode(OperatorType.add, left, right);
Node mul(Node left, Node right) =>
    BinaryNode(OperatorType.multiply, left, right);
Node div(Node left, Node right) => BinaryNode(OperatorType.divide, left, right);
Node sub(Node left, Node right) =>
    BinaryNode(OperatorType.subtract, left, right);
Node pow(Node left, Node right) => BinaryNode(OperatorType.power, left, right);

Node parse(String source) => Parser(tokenize(source)).parse();

void main() {
  group('precedence', () {
    test('multiplication binds before addition', () {
      expect(parse('2+3×4'), add(num(2), mul(num(3), num(4))));
      expect(parse('2×3+4'), add(mul(num(2), num(3)), num(4)));
    });

    test('power binds before multiplication', () {
      expect(parse('2^3×4'), mul(pow(num(2), num(3)), num(4)));
    });

    test('brackets override precedence', () {
      expect(parse('(2+3)×4'), mul(add(num(2), num(3)), num(4)));
      expect(parse('2×(3+4)'), mul(num(2), add(num(3), num(4))));
      expect(parse('((2))'), num(2));
    });
  });

  group('associativity', () {
    test('power is right-associative', () {
      expect(parse('2^3^2'), pow(num(2), pow(num(3), num(2))));
    });

    test('subtraction, division and multiplication are left-associative', () {
      expect(parse('1−2−3'), sub(sub(num(1), num(2)), num(3)));
      expect(parse('8÷4÷2'), div(div(num(8), num(4)), num(2)));
      expect(parse('2×3×4'), mul(mul(num(2), num(3)), num(4)));
    });
  });

  group('unary signs', () {
    test('−2^2 is −(2^2), not (−2)^2', () {
      expect(
        parse('−2^2'),
        UnaryNode(negative: true, operand: pow(num(2), num(2))),
      );
    });

    test('an exponent may be signed', () {
      expect(
        parse('2^−3'),
        pow(num(2), UnaryNode(negative: true, operand: num(3))),
      );
    });

    test('unary binds tighter than multiplication', () {
      expect(
        parse('−2×3'),
        mul(UnaryNode(negative: true, operand: num(2)), num(3)),
      );
    });

    test('unary plus and repeated signs', () {
      expect(parse('+5'), UnaryNode(negative: false, operand: num(5)));
      expect(
        parse('−−2'),
        UnaryNode(
          negative: true,
          operand: UnaryNode(negative: true, operand: num(2)),
        ),
      );
    });
  });

  group('implicit multiplication', () {
    test('number × constant', () {
      expect(parse('2π'), mul(num(2), const ConstNode(MathConstant.pi)));
    });

    test('implicit × binds tighter than ÷', () {
      expect(
        parse('1÷2π'),
        div(num(1), mul(num(2), const ConstNode(MathConstant.pi))),
      );
    });

    test('power inside implicit ×', () {
      expect(
        parse('2π^2'),
        mul(num(2), pow(const ConstNode(MathConstant.pi), num(2))),
      );
    });

    test('implicit × is left-associative', () {
      expect(
        parse('2π×3'),
        mul(mul(num(2), const ConstNode(MathConstant.pi)), num(3)),
      );
    });

    test('adjacent brackets multiply', () {
      expect(parse('(2+3)(4)'), mul(add(num(2), num(3)), num(4)));
    });
  });

  group('numbers and constants', () {
    test('keeps exact decimals', () {
      expect(
        parse('0.1+0.2'),
        add(NumberNode(Decimal.parse('0.1')), NumberNode(Decimal.parse('0.2'))),
      );
    });

    test('accepts a trailing dot from the tokenizer', () {
      expect(parse('12.'), num(12));
    });

    test('parses e as a constant', () {
      expect(parse('e'), const ConstNode(MathConstant.e));
    });
  });

  group('syntax errors', () {
    test('throws on incomplete or unbalanced input', () {
      expect(() => parse(''), throwsFormatException);
      expect(() => parse('2+'), throwsFormatException);
      expect(() => parse('(2+3'), throwsFormatException);
      expect(() => parse('2+3)'), throwsFormatException);
      expect(() => parse('×3'), throwsFormatException);
      expect(() => parse('2+×3'), throwsFormatException);
    });
  });
}
