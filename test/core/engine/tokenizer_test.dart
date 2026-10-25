import 'package:calculator/core/engine/token.dart';
import 'package:calculator/core/engine/tokenizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tokenize', () {
    test('tokenizes the §3 sample', () {
      expect(tokenize('12.5+3×(4−1)'), <Token>[
        const NumberToken('12.5'),
        const OperatorToken(OperatorType.add),
        const NumberToken('3'),
        const OperatorToken(OperatorType.multiply),
        const LeftParenToken(),
        const NumberToken('4'),
        const OperatorToken(OperatorType.subtract),
        const NumberToken('1'),
        const RightParenToken(),
      ]);
    });

    test('returns no tokens for empty or blank input', () {
      expect(tokenize(''), isEmpty);
      expect(tokenize('   \n\t'), isEmpty);
    });

    test('keeps decimals and leading zeros raw', () {
      expect(tokenize('0.5'), <Token>[const NumberToken('0.5')]);
      expect(tokenize('007'), <Token>[const NumberToken('007')]);
    });

    test('maps typed operator aliases to the same operators', () {
      expect(tokenize('2*3/4-5'), <Token>[
        const NumberToken('2'),
        const OperatorToken(OperatorType.multiply),
        const NumberToken('3'),
        const OperatorToken(OperatorType.divide),
        const NumberToken('4'),
        const OperatorToken(OperatorType.subtract),
        const NumberToken('5'),
      ]);
      expect(tokenize('2^3'), <Token>[
        const NumberToken('2'),
        const OperatorToken(OperatorType.power),
        const NumberToken('3'),
      ]);
    });

    test('tokenizes mod as a word operator', () {
      expect(tokenize('10 mod 3'), <Token>[
        const NumberToken('10'),
        const OperatorToken(OperatorType.mod),
        const NumberToken('3'),
      ]);
    });

    test('tokenizes postfix operators', () {
      expect(tokenize('5!'), <Token>[
        const NumberToken('5'),
        const PostfixToken(PostfixType.factorial),
      ]);
      expect(tokenize('50%'), <Token>[
        const NumberToken('50'),
        const PostfixToken(PostfixType.percent),
      ]);
      expect(tokenize('3²'), <Token>[
        const NumberToken('3'),
        const PostfixToken(PostfixType.square),
      ]);
      expect(tokenize('2³'), <Token>[
        const NumberToken('2'),
        const PostfixToken(PostfixType.cube),
      ]);
      expect(tokenize('4⁻¹'), <Token>[
        const NumberToken('4'),
        const PostfixToken(PostfixType.reciprocal),
      ]);
    });

    test('tokenizes the y-th root operator', () {
      expect(tokenize('8ʸ√3'), <Token>[
        const NumberToken('8'),
        const OperatorToken(OperatorType.root),
        const NumberToken('3'),
      ]);
      expect(tokenize('8 ʸ√ 3'), <Token>[
        const NumberToken('8'),
        const OperatorToken(OperatorType.root),
        const NumberToken('3'),
      ]);
    });

    test('ignores whitespace between tokens', () {
      expect(tokenize(' 1 +\n2 '), <Token>[
        const NumberToken('1'),
        const OperatorToken(OperatorType.add),
        const NumberToken('2'),
      ]);
    });
  });

  group('unary signs', () {
    test('a leading minus is unary', () {
      expect(tokenize('−2'), <Token>[
        const UnaryToken(negative: true),
        const NumberToken('2'),
      ]);
    });

    test('a leading plus is unary', () {
      expect(tokenize('+5'), <Token>[
        const UnaryToken(negative: false),
        const NumberToken('5'),
      ]);
    });

    test('minus after an operator is unary', () {
      expect(tokenize('5×−3'), <Token>[
        const NumberToken('5'),
        const OperatorToken(OperatorType.multiply),
        const UnaryToken(negative: true),
        const NumberToken('3'),
      ]);
    });

    test('minus after "(" is unary', () {
      expect(tokenize('(−3)'), <Token>[
        const LeftParenToken(),
        const UnaryToken(negative: true),
        const NumberToken('3'),
        const RightParenToken(),
      ]);
    });

    test('minus after another minus is unary', () {
      expect(tokenize('2−−3'), <Token>[
        const NumberToken('2'),
        const OperatorToken(OperatorType.subtract),
        const UnaryToken(negative: true),
        const NumberToken('3'),
      ]);
    });

    test('minus after a value or ")" stays binary', () {
      expect(tokenize('5−3'), <Token>[
        const NumberToken('5'),
        const OperatorToken(OperatorType.subtract),
        const NumberToken('3'),
      ]);
      expect(tokenize('(1)−3'), <Token>[
        const LeftParenToken(),
        const NumberToken('1'),
        const RightParenToken(),
        const OperatorToken(OperatorType.subtract),
        const NumberToken('3'),
      ]);
      expect(tokenize('5!−3'), <Token>[
        const NumberToken('5'),
        const PostfixToken(PostfixType.factorial),
        const OperatorToken(OperatorType.subtract),
        const NumberToken('3'),
      ]);
    });
  });

  group('functions and constants', () {
    test('a function owns its opening bracket', () {
      expect(tokenize('sin(30)'), <Token>[
        const FunctionToken('sin'),
        const NumberToken('30'),
        const RightParenToken(),
      ]);
      expect(tokenize('cos(0)'), <Token>[
        const FunctionToken('cos'),
        const NumberToken('0'),
        const RightParenToken(),
      ]);
      expect(tokenize('tan(45)'), <Token>[
        const FunctionToken('tan'),
        const NumberToken('45'),
        const RightParenToken(),
      ]);
    });

    test('understands logarithms, roots and inverse trig', () {
      expect(tokenize('ln(e)'), <Token>[
        const FunctionToken('ln'),
        const ConstantToken(MathConstant.e),
        const RightParenToken(),
      ]);
      expect(tokenize('log(100)'), <Token>[
        const FunctionToken('log'),
        const NumberToken('100'),
        const RightParenToken(),
      ]);
      expect(tokenize('√(144)'), <Token>[
        const FunctionToken('√'),
        const NumberToken('144'),
        const RightParenToken(),
      ]);
      expect(tokenize('∛(8)'), <Token>[
        const FunctionToken('∛'),
        const NumberToken('8'),
        const RightParenToken(),
      ]);
      expect(tokenize('sin⁻¹(0.5)'), <Token>[
        const FunctionToken('sin⁻¹'),
        const NumberToken('0.5'),
        const RightParenToken(),
      ]);
    });

    test('understands eˣ and 10ˣ', () {
      expect(tokenize('eˣ(2)'), <Token>[
        const FunctionToken('eˣ'),
        const NumberToken('2'),
        const RightParenToken(),
      ]);
      expect(tokenize('10ˣ(3)'), <Token>[
        const FunctionToken('10ˣ'),
        const NumberToken('3'),
        const RightParenToken(),
      ]);
    });

    test('tokenizes constants and Ans', () {
      expect(tokenize('π'), <Token>[const ConstantToken(MathConstant.pi)]);
      expect(tokenize('pi'), <Token>[const ConstantToken(MathConstant.pi)]);
      expect(tokenize('e'), <Token>[const ConstantToken(MathConstant.e)]);
      expect(tokenize('Ans'), <Token>[const AnsToken()]);
      expect(tokenize('ans+1'), <Token>[
        const AnsToken(),
        const OperatorToken(OperatorType.add),
        const NumberToken('1'),
      ]);
    });

    test('a sign inside a function bracket is unary', () {
      expect(tokenize('sin(−30)'), <Token>[
        const FunctionToken('sin'),
        const UnaryToken(negative: true),
        const NumberToken('30'),
        const RightParenToken(),
      ]);
    });
  });

  group('implicit multiplication', () {
    test('number × constant', () {
      expect(tokenize('2π'), <Token>[
        const NumberToken('2'),
        const OperatorToken(OperatorType.multiply, implicit: true),
        const ConstantToken(MathConstant.pi),
      ]);
    });

    test('number × bracket', () {
      expect(tokenize('3(4)'), <Token>[
        const NumberToken('3'),
        const OperatorToken(OperatorType.multiply, implicit: true),
        const LeftParenToken(),
        const NumberToken('4'),
        const RightParenToken(),
      ]);
    });

    test('bracket × bracket', () {
      expect(tokenize('(1)(2)'), <Token>[
        const LeftParenToken(),
        const NumberToken('1'),
        const RightParenToken(),
        const OperatorToken(OperatorType.multiply, implicit: true),
        const LeftParenToken(),
        const NumberToken('2'),
        const RightParenToken(),
      ]);
    });

    test('number × function', () {
      expect(tokenize('2sin(30)'), <Token>[
        const NumberToken('2'),
        const OperatorToken(OperatorType.multiply, implicit: true),
        const FunctionToken('sin'),
        const NumberToken('30'),
        const RightParenToken(),
      ]);
    });

    test('postfix × number', () {
      expect(tokenize('5!2'), <Token>[
        const NumberToken('5'),
        const PostfixToken(PostfixType.factorial),
        const OperatorToken(OperatorType.multiply, implicit: true),
        const NumberToken('2'),
      ]);
    });

    test('constant × constant, number × Ans and bracket × number', () {
      expect(tokenize('πe'), <Token>[
        const ConstantToken(MathConstant.pi),
        const OperatorToken(OperatorType.multiply, implicit: true),
        const ConstantToken(MathConstant.e),
      ]);
      expect(tokenize('2Ans'), <Token>[
        const NumberToken('2'),
        const OperatorToken(OperatorType.multiply, implicit: true),
        const AnsToken(),
      ]);
      expect(tokenize('(2)3'), <Token>[
        const LeftParenToken(),
        const NumberToken('2'),
        const RightParenToken(),
        const OperatorToken(OperatorType.multiply, implicit: true),
        const NumberToken('3'),
      ]);
    });

    test('does not insert × where it does not belong', () {
      expect(tokenize('2×3'), <Token>[
        const NumberToken('2'),
        const OperatorToken(OperatorType.multiply),
        const NumberToken('3'),
      ]);
      expect(
        tokenize('sin(30)'),
        isNot(
          contains(const OperatorToken(OperatorType.multiply, implicit: true)),
        ),
      );
      expect(tokenize('2^3(4)'), <Token>[
        const NumberToken('2'),
        const OperatorToken(OperatorType.power),
        const NumberToken('3'),
        const OperatorToken(OperatorType.multiply, implicit: true),
        const LeftParenToken(),
        const NumberToken('4'),
        const RightParenToken(),
      ]);
    });
  });

  test('rejects characters it cannot tokenize', () {
    expect(() => tokenize('2#3'), throwsFormatException);
    expect(() => tokenize('2.5.1'), throwsFormatException);
    expect(() => tokenize('sinx'), throwsFormatException);
  });
}
