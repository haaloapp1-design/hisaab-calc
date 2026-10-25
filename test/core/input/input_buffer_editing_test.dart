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
  group('± sign', () {
    test('wraps the current number and unwraps it again', () {
      final InputBuffer wrapped = typeDigits(empty, '5').toggleSign();
      expect(
        wrapped,
        const InputBuffer(<Token>[
          LeftParenToken(),
          UnaryToken(negative: true),
          NumberToken('5'),
          RightParenToken(),
        ]),
      );
      expect(wrapped.toggleSign(), typeDigits(empty, '5'));
    });

    test('wraps only the last number', () {
      final InputBuffer buffer = typeDigits(
        empty,
        '2',
      ).appendOperator(OperatorType.add);
      final InputBuffer sum = buffer.appendDigit(5);
      expect(
        sum.toggleSign(),
        const InputBuffer(<Token>[
          NumberToken('2'),
          OperatorToken(OperatorType.add),
          LeftParenToken(),
          UnaryToken(negative: true),
          NumberToken('5'),
          RightParenToken(),
        ]),
      );
      expect(sum.toggleSign().toggleSign(), sum);
    });

    test('keeps the typed decimals', () {
      expect(
        typeDigits(empty, '0').appendDecimalPoint().appendDigit(5).toggleSign(),
        const InputBuffer(<Token>[
          LeftParenToken(),
          UnaryToken(negative: true),
          NumberToken('0.5'),
          RightParenToken(),
        ]),
      );
    });

    test('toggles an existing unary sign instead of double-wrapping', () {
      final InputBuffer negative = typeDigits(empty, '5')
          .appendOperator(OperatorType.multiply)
          .appendOperator(OperatorType.subtract)
          .appendDigit(5);
      expect(
        negative,
        const InputBuffer(<Token>[
          NumberToken('5'),
          OperatorToken(OperatorType.multiply),
          UnaryToken(negative: true),
          NumberToken('5'),
        ]),
      );
      expect(
        negative.toggleSign(),
        const InputBuffer(<Token>[
          NumberToken('5'),
          OperatorToken(OperatorType.multiply),
          NumberToken('5'),
        ]),
      );
      expect(
        negative.toggleSign().toggleSign(),
        const InputBuffer(<Token>[
          NumberToken('5'),
          OperatorToken(OperatorType.multiply),
          LeftParenToken(),
          UnaryToken(negative: true),
          NumberToken('5'),
          RightParenToken(),
        ]),
      );
    });

    test('does nothing without a current number', () {
      expect(empty.toggleSign(), empty);

      final InputBuffer operator = typeDigits(
        empty,
        '5',
      ).appendOperator(OperatorType.add);
      expect(operator.toggleSign(), operator);

      const InputBuffer constant = InputBuffer(<Token>[
        ConstantToken(MathConstant.pi),
      ]);
      expect(constant.toggleSign(), constant);

      const InputBuffer group = InputBuffer(<Token>[
        LeftParenToken(),
        NumberToken('2'),
        RightParenToken(),
      ]);
      expect(group.toggleSign(), group);
    });
  });

  group('backspace', () {
    test('removes one digit at a time', () {
      final InputBuffer number = typeDigits(empty, '123');
      expect(number.backspace(), const InputBuffer(<Token>[NumberToken('12')]));
      expect(
        number.backspace().backspace(),
        const InputBuffer(<Token>[NumberToken('1')]),
      );
      expect(number.backspace().backspace().backspace(), empty);
    });

    test('removes the decimal point and leading zero too', () {
      final InputBuffer decimal = typeDigits(
        empty,
        '1',
      ).appendDecimalPoint().appendDigit(5);
      expect(
        decimal.backspace(),
        const InputBuffer(<Token>[NumberToken('1.')]),
      );
      expect(
        decimal.backspace().backspace(),
        const InputBuffer(<Token>[NumberToken('1')]),
      );

      final InputBuffer leading = empty.appendDecimalPoint();
      expect(leading.backspace(), const InputBuffer(<Token>[NumberToken('0')]));
      expect(leading.backspace().backspace(), empty);
    });

    test('removes a function token in one step', () {
      const InputBuffer function = InputBuffer(<Token>[FunctionToken('sin')]);
      expect(function.backspace(), empty);
    });

    test('removes digits before the function token', () {
      final InputBuffer typed = const InputBuffer(<Token>[FunctionToken('sin')])
          .appendDigit(3)
          .appendDigit(0);
      expect(
        typed.backspace(),
        const InputBuffer(<Token>[FunctionToken('sin'), NumberToken('3')]),
      );
      expect(
        typed.backspace().backspace(),
        const InputBuffer(<Token>[FunctionToken('sin')]),
      );
      expect(typed.backspace().backspace().backspace(), empty);
    });

    test('removes operators, brackets and signs as whole tokens', () {
      final InputBuffer buffer = typeDigits(empty, '5')
          .appendOperator(OperatorType.add)
          .appendLeftParen()
          .appendDigit(5)
          .toggleSign();
      expect(
        buffer,
        const InputBuffer(<Token>[
          NumberToken('5'),
          OperatorToken(OperatorType.add),
          LeftParenToken(),
          LeftParenToken(),
          UnaryToken(negative: true),
          NumberToken('5'),
          RightParenToken(),
        ]),
      );
      expect(
        buffer.backspace(),
        const InputBuffer(<Token>[
          NumberToken('5'),
          OperatorToken(OperatorType.add),
          LeftParenToken(),
          LeftParenToken(),
          UnaryToken(negative: true),
          NumberToken('5'),
        ]),
      );
      expect(
        buffer.backspace().backspace(),
        const InputBuffer(<Token>[
          NumberToken('5'),
          OperatorToken(OperatorType.add),
          LeftParenToken(),
          LeftParenToken(),
          UnaryToken(negative: true),
        ]),
      );
      expect(
        buffer.backspace().backspace().backspace(),
        const InputBuffer(<Token>[
          NumberToken('5'),
          OperatorToken(OperatorType.add),
          LeftParenToken(),
          LeftParenToken(),
        ]),
      );
    });
  });

  test('C clears the whole buffer', () {
    final InputBuffer buffer = typeDigits(
      empty,
      '5',
    ).appendOperator(OperatorType.add).appendLeftParen();
    expect(buffer.clear(), empty);
    expect(empty.clear(), empty);
  });
}
