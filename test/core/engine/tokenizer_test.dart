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

  test('rejects characters it cannot tokenize', () {
    expect(() => tokenize('2#3'), throwsFormatException);
    expect(() => tokenize('2.5.1'), throwsFormatException);
  });
}
