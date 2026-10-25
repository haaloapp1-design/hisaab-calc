import 'package:calculator/core/engine/token.dart';
import 'package:calculator/core/input/input_buffer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('appendFunction', () {
    test('adds the function as one token that owns its bracket', () {
      final InputBuffer buffer = const InputBuffer.empty().appendFunction(
        'sin',
      );

      expect(buffer.tokens, <Token>[const FunctionToken('sin')]);
    });

    test('inserts the hidden × after a value', () {
      final InputBuffer buffer = const InputBuffer.empty()
          .appendDigit(2)
          .appendFunction('sin')
          .appendDigit(3)
          .appendDigit(0);

      expect(buffer.tokens, <Token>[
        const NumberToken('2'),
        const OperatorToken(OperatorType.multiply, implicit: true),
        const FunctionToken('sin'),
        const NumberToken('30'),
      ]);
    });

    test('does not insert × after an operator', () {
      final InputBuffer buffer = const InputBuffer.empty()
          .appendDigit(2)
          .appendOperator(OperatorType.add)
          .appendFunction('√');

      expect(buffer.tokens, <Token>[
        const NumberToken('2'),
        const OperatorToken(OperatorType.add),
        const FunctionToken('√'),
      ]);
    });
  });

  group('appendConstant', () {
    test('starts an expression with the constant', () {
      final InputBuffer buffer = const InputBuffer.empty().appendConstant(
        MathConstant.pi,
      );

      expect(buffer.tokens, <Token>[const ConstantToken(MathConstant.pi)]);
    });

    test('inserts the hidden × after a value', () {
      final InputBuffer buffer = const InputBuffer.empty()
          .appendDigit(2)
          .appendConstant(MathConstant.pi);

      expect(buffer.tokens, <Token>[
        const NumberToken('2'),
        const OperatorToken(OperatorType.multiply, implicit: true),
        const ConstantToken(MathConstant.pi),
      ]);
    });

    test('keeps a typed number untouched after a constant', () {
      final InputBuffer buffer = const InputBuffer.empty()
          .appendConstant(MathConstant.e)
          .appendDigit(3);

      expect(buffer.tokens, <Token>[
        const ConstantToken(MathConstant.e),
        const OperatorToken(OperatorType.multiply, implicit: true),
        const NumberToken('3'),
      ]);
    });
  });

  group('appendPostfix', () {
    test('appends after a number, a constant and a closed bracket', () {
      expect(
        const InputBuffer.empty().appendDigit(5).appendPostfix(
          PostfixType.factorial,
        ).tokens,
        <Token>[const NumberToken('5'), const PostfixToken(PostfixType.factorial)],
      );
      expect(
        const InputBuffer.empty()
            .appendConstant(MathConstant.pi)
            .appendPostfix(PostfixType.square)
            .tokens,
        <Token>[
          const ConstantToken(MathConstant.pi),
          const PostfixToken(PostfixType.square),
        ],
      );
      final InputBuffer closed = const InputBuffer.empty()
          .appendLeftParen()
          .appendDigit(3)
          .appendRightParen()
          .appendPostfix(PostfixType.percent);
      expect(closed.tokens.last, const PostfixToken(PostfixType.percent));
    });

    test('is ignored when there is no value on the left', () {
      expect(
        const InputBuffer.empty().appendPostfix(PostfixType.factorial),
        const InputBuffer.empty(),
      );
      expect(
        const InputBuffer.empty()
            .appendDigit(2)
            .appendOperator(OperatorType.add)
            .appendPostfix(PostfixType.percent),
        InputBuffer(<Token>[
          const NumberToken('2'),
          const OperatorToken(OperatorType.add),
        ]),
      );
      expect(
        const InputBuffer.empty()
            .appendFunction('sin')
            .appendPostfix(PostfixType.square),
        InputBuffer(<Token>[const FunctionToken('sin')]),
      );
    });
  });

  group('appendValueTokens', () {
    test('inserts a plain answer value', () {
      expect(
        const InputBuffer.empty().appendValueTokens(<Token>[
          const NumberToken('8'),
        ]).tokens,
        <Token>[const NumberToken('8')],
      );
    });

    test('inserts the hidden × after a value', () {
      expect(
        const InputBuffer.empty()
            .appendDigit(2)
            .appendValueTokens(<Token>[const NumberToken('8')]).tokens,
        <Token>[
          const NumberToken('2'),
          const OperatorToken(OperatorType.multiply, implicit: true),
          const NumberToken('8'),
        ],
      );
    });

    test('keeps a bracketed negative answer together', () {
      expect(
        const InputBuffer.empty()
            .appendValueTokens(<Token>[
              const LeftParenToken(),
              const UnaryToken(negative: true),
              const NumberToken('8'),
              const RightParenToken(),
            ])
            .tokens,
        <Token>[
          const LeftParenToken(),
          const UnaryToken(negative: true),
          const NumberToken('8'),
          const RightParenToken(),
        ],
      );
    });
  });
}
