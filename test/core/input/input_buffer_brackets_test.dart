import 'package:calculator/core/engine/token.dart';
import 'package:calculator/core/input/input_buffer.dart';
import 'package:flutter_test/flutter_test.dart';

InputBuffer typeDigits(InputBuffer buffer, String digits) {
  InputBuffer result = buffer;
  for (final String digit in digits.split('')) {
    result = result.appendDigit(int.parse(digit));
  }
  return result;
}

const InputBuffer empty = InputBuffer.empty();

void main() {
  group('brackets', () {
    test('( is always allowed and inserts implicit × after a value', () {
      expect(
        empty.appendLeftParen(),
        const InputBuffer(<Token>[LeftParenToken()]),
      );
      expect(
        typeDigits(empty, '5').appendLeftParen(),
        const InputBuffer(<Token>[
          NumberToken('5'),
          OperatorToken(OperatorType.multiply, implicit: true),
          LeftParenToken(),
        ]),
      );
      expect(
        const InputBuffer(<Token>[ConstantToken(MathConstant.pi)])
            .appendLeftParen(),
        const InputBuffer(<Token>[
          ConstantToken(MathConstant.pi),
          OperatorToken(OperatorType.multiply, implicit: true),
          LeftParenToken(),
        ]),
      );
      expect(
        typeDigits(
          empty,
          '5',
        ).appendOperator(OperatorType.add).appendLeftParen(),
        const InputBuffer(<Token>[
          NumberToken('5'),
          OperatorToken(OperatorType.add),
          LeftParenToken(),
        ]),
      );
      expect(
        const InputBuffer(<Token>[FunctionToken('sin')]).appendLeftParen(),
        const InputBuffer(<Token>[FunctionToken('sin'), LeftParenToken()]),
      );
    });

    test(') is rejected without an open bracket', () {
      expect(empty.appendRightParen(), empty);
      final InputBuffer five = typeDigits(empty, '5');
      expect(five.appendRightParen(), five);
    });

    test(') is rejected when the last token is not a value', () {
      final InputBuffer openBracket = empty.appendLeftParen();
      expect(openBracket.appendRightParen(), openBracket);

      final InputBuffer openSum = typeDigits(
        empty,
        '2',
      ).appendLeftParen().appendDigit(2).appendOperator(OperatorType.add);
      expect(openSum.appendRightParen(), openSum);

      const InputBuffer function = InputBuffer(<Token>[FunctionToken('sin')]);
      expect(function.appendRightParen(), function);

      final InputBuffer negative = empty.appendLeftParen().appendOperator(
        OperatorType.subtract,
      );
      expect(negative.appendRightParen(), negative);
    });

    test(') closes a bracket after a value', () {
      expect(
        empty.appendLeftParen().appendDigit(2).appendRightParen(),
        const InputBuffer(<Token>[
          LeftParenToken(),
          NumberToken('2'),
          RightParenToken(),
        ]),
      );
      expect(
        const InputBuffer(<Token>[FunctionToken('sin')])
            .appendDigit(3)
            .appendDigit(0)
            .appendRightParen(),
        const InputBuffer(<Token>[
          FunctionToken('sin'),
          NumberToken('30'),
          RightParenToken(),
        ]),
      );
      expect(
        const InputBuffer(<Token>[
          LeftParenToken(),
          NumberToken('2'),
          PostfixToken(PostfixType.factorial),
        ]).appendRightParen(),
        const InputBuffer(<Token>[
          LeftParenToken(),
          NumberToken('2'),
          PostfixToken(PostfixType.factorial),
          RightParenToken(),
        ]),
      );
    });

    test(') can close nested brackets one at a time', () {
      final InputBuffer nested = empty
          .appendLeftParen()
          .appendLeftParen()
          .appendDigit(2);
      final InputBuffer once = nested.appendRightParen();
      final InputBuffer twice = once.appendRightParen();

      expect(
        twice,
        const InputBuffer(<Token>[
          LeftParenToken(),
          LeftParenToken(),
          NumberToken('2'),
          RightParenToken(),
          RightParenToken(),
        ]),
      );
      expect(twice.appendRightParen(), twice);
    });
  });
}
