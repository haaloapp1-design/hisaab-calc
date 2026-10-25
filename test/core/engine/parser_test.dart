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

  group('postfix operators', () {
    test('factorial and percent', () {
      expect(parse('5!'), PostfixNode(PostfixType.factorial, num(5)));
      expect(parse('50%'), PostfixNode(PostfixType.percent, num(50)));
    });

    test('square and cube', () {
      expect(parse('5²'), PostfixNode(PostfixType.square, num(5)));
      expect(parse('5³'), PostfixNode(PostfixType.cube, num(5)));
    });

    test('postfix binds tighter than power and unary', () {
      expect(
        parse('2^3!'),
        pow(num(2), PostfixNode(PostfixType.factorial, num(3))),
      );
      expect(
        parse('2!^3'),
        pow(PostfixNode(PostfixType.factorial, num(2)), num(3)),
      );
      expect(
        parse('−5!'),
        UnaryNode(
          negative: true,
          operand: PostfixNode(PostfixType.factorial, num(5)),
        ),
      );
    });

    test('repeated postfix is left-associative', () {
      expect(
        parse('5!!'),
        PostfixNode(
          PostfixType.factorial,
          PostfixNode(PostfixType.factorial, num(5)),
        ),
      );
      expect(
        parse('5!²'),
        PostfixNode(
          PostfixType.square,
          PostfixNode(PostfixType.factorial, num(5)),
        ),
      );
    });

    test('postfix applies to brackets and results', () {
      expect(
        parse('(2+3)!'),
        PostfixNode(PostfixType.factorial, add(num(2), num(3))),
      );
      expect(
        parse('5!2'),
        mul(PostfixNode(PostfixType.factorial, num(5)), num(2)),
      );
    });
  });

  group('functions', () {
    test('a function owns its argument', () {
      expect(parse('sin(30)'), FuncNode('sin', num(30)));
    });

    test('arguments can be full expressions', () {
      expect(
        parse('sin(2π)'),
        FuncNode('sin', mul(num(2), const ConstNode(MathConstant.pi))),
      );
      expect(parse('sin(30)+1'), add(FuncNode('sin', num(30)), num(1)));
    });

    test('functions nest and take part in implicit ×', () {
      expect(parse('sin(cos(0))'), FuncNode('sin', FuncNode('cos', num(0))));
      expect(parse('2sin(30)'), mul(num(2), FuncNode('sin', num(30))));
      expect(
        parse('sin(30)!'),
        PostfixNode(PostfixType.factorial, FuncNode('sin', num(30))),
      );
    });

    test('roots are functions too', () {
      expect(parse('√(144)'), FuncNode('√', num(144)));
    });
  });

  group('auto-closing brackets', () {
    test('a missing ")" at the end is auto-closed', () {
      expect(parse('(2+3'), add(num(2), num(3)));
      expect(parse('((2+3'), add(num(2), num(3)));
      expect(parse('2(3'), mul(num(2), num(3)));
      expect(parse('sin(30'), FuncNode('sin', num(30)));
      expect(parse('sin(30^2'), FuncNode('sin', pow(num(30), num(2))));
      expect(parse('sin((2+3'), FuncNode('sin', add(num(2), num(3))));
    });

    test('a missing ")" is not invented before another token', () {
      expect(() => parse('sin(30))'), throwsFormatException);
    });
  });

  group('syntax errors', () {
    test('throws on incomplete or unbalanced input', () {
      expect(() => parse(''), throwsFormatException);
      expect(() => parse('2+'), throwsFormatException);
      expect(() => parse('(2+'), throwsFormatException);
      expect(() => parse('2+3)'), throwsFormatException);
      expect(() => parse('×3'), throwsFormatException);
      expect(() => parse('2+×3'), throwsFormatException);
    });
  });
}
