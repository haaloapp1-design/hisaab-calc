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
  group('digits', () {
    test('append to the current number', () {
      expect(
        typeDigits(empty, '123'),
        const InputBuffer(<Token>[NumberToken('123')]),
      );
      expect(
        typeDigits(empty, '0').appendDigit(5),
        const InputBuffer(<Token>[NumberToken('5')]),
      );
    });

    test('leading zeros are replaced, never kept', () {
      expect(
        typeDigits(empty, '05'),
        const InputBuffer(<Token>[NumberToken('5')]),
      );
      expect(
        typeDigits(empty, '000'),
        const InputBuffer(<Token>[NumberToken('0')]),
      );
      expect(
        typeDigits(empty, '007'),
        const InputBuffer(<Token>[NumberToken('7')]),
      );
      expect(
        typeDigits(empty, '0').appendDecimalPoint().appendDigit(5),
        const InputBuffer(<Token>[NumberToken('0.5')]),
      );
    });

    test('a number holds at most 15 digits', () {
      final InputBuffer buffer = typeDigits(empty, '1234567890123456');
      expect(
        buffer,
        const InputBuffer(<Token>[NumberToken('123456789012345')]),
      );
      expect(
        buffer.appendDigit(9),
        const InputBuffer(<Token>[NumberToken('123456789012345')]),
      );
    });

    test('a digit after a value starts an implicit multiplication', () {
      expect(
        const InputBuffer(<Token>[ConstantToken(MathConstant.pi)])
            .appendDigit(2),
        const InputBuffer(<Token>[
          ConstantToken(MathConstant.pi),
          OperatorToken(OperatorType.multiply, implicit: true),
          NumberToken('2'),
        ]),
      );
      expect(
        const InputBuffer(<Token>[
          LeftParenToken(),
          NumberToken('2'),
          RightParenToken(),
        ]).appendDigit(3),
        const InputBuffer(<Token>[
          LeftParenToken(),
          NumberToken('2'),
          RightParenToken(),
          OperatorToken(OperatorType.multiply, implicit: true),
          NumberToken('3'),
        ]),
      );
    });

    test('a digit after an operator starts a new number', () {
      expect(
        typeDigits(empty, '5').appendOperator(OperatorType.add).appendDigit(2),
        const InputBuffer(<Token>[
          NumberToken('5'),
          OperatorToken(OperatorType.add),
          NumberToken('2'),
        ]),
      );
    });
  });

  group('decimal point', () {
    test('a leading dot inserts 0.', () {
      expect(
        empty.appendDecimalPoint(),
        const InputBuffer(<Token>[NumberToken('0.')]),
      );
      expect(
        empty.appendDecimalPoint().appendDigit(5),
        const InputBuffer(<Token>[NumberToken('0.5')]),
      );
    });

    test('only one dot per number', () {
      final InputBuffer buffer = typeDigits(
        empty,
        '1',
      ).appendDecimalPoint().appendDigit(2).appendDecimalPoint().appendDigit(3);
      expect(buffer, const InputBuffer(<Token>[NumberToken('1.23')]));
      expect(
        typeDigits(empty, '5').appendDecimalPoint(),
        const InputBuffer(<Token>[NumberToken('5.')]),
      );
    });

    test('a dot after an operator starts a new number', () {
      expect(
        typeDigits(
          empty,
          '5',
        ).appendOperator(OperatorType.add).appendDecimalPoint(),
        const InputBuffer(<Token>[
          NumberToken('5'),
          OperatorToken(OperatorType.add),
          NumberToken('0.'),
        ]),
      );
    });

    test('a dot after a value starts an implicit multiplication', () {
      expect(
        const InputBuffer(<Token>[ConstantToken(MathConstant.pi)])
            .appendDecimalPoint(),
        const InputBuffer(<Token>[
          ConstantToken(MathConstant.pi),
          OperatorToken(OperatorType.multiply, implicit: true),
          NumberToken('0.'),
        ]),
      );
    });
  });

  group('operators', () {
    test('append after a number', () {
      expect(
        typeDigits(empty, '5').appendOperator(OperatorType.add),
        const InputBuffer(<Token>[
          NumberToken('5'),
          OperatorToken(OperatorType.add),
        ]),
      );
    });

    test('a trailing operator is replaced', () {
      expect(
        typeDigits(empty, '5')
            .appendOperator(OperatorType.add)
            .appendOperator(OperatorType.multiply),
        const InputBuffer(<Token>[
          NumberToken('5'),
          OperatorToken(OperatorType.multiply),
        ]),
      );
      expect(
        typeDigits(empty, '5')
            .appendOperator(OperatorType.add)
            .appendOperator(OperatorType.subtract),
        const InputBuffer(<Token>[
          NumberToken('5'),
          OperatorToken(OperatorType.subtract),
        ]),
      );
      expect(
        typeDigits(empty, '5')
            .appendOperator(OperatorType.multiply)
            .appendOperator(OperatorType.divide),
        const InputBuffer(<Token>[
          NumberToken('5'),
          OperatorToken(OperatorType.divide),
        ]),
      );
    });

    test('− after × or ÷ starts a negative number', () {
      expect(
        typeDigits(empty, '5')
            .appendOperator(OperatorType.multiply)
            .appendOperator(OperatorType.subtract),
        const InputBuffer(<Token>[
          NumberToken('5'),
          OperatorToken(OperatorType.multiply),
          UnaryToken(negative: true),
        ]),
      );
      expect(
        typeDigits(empty, '5')
            .appendOperator(OperatorType.divide)
            .appendOperator(OperatorType.subtract),
        const InputBuffer(<Token>[
          NumberToken('5'),
          OperatorToken(OperatorType.divide),
          UnaryToken(negative: true),
        ]),
      );
    });

    test('an empty buffer starts from the start value (0 by default)', () {
      expect(
        empty.appendOperator(OperatorType.add),
        const InputBuffer(<Token>[
          NumberToken('0'),
          OperatorToken(OperatorType.add),
        ]),
      );
      expect(
        empty.appendOperator(OperatorType.subtract),
        const InputBuffer(<Token>[
          NumberToken('0'),
          OperatorToken(OperatorType.subtract),
        ]),
      );
      expect(
        empty.appendOperator(
          OperatorType.multiply,
          startValue: const NumberToken('7'),
        ),
        const InputBuffer(<Token>[
          NumberToken('7'),
          OperatorToken(OperatorType.multiply),
        ]),
      );
    });

    test('an operator after a dangling sign replaces the operator', () {
      expect(
        typeDigits(empty, '5')
            .appendOperator(OperatorType.multiply)
            .appendOperator(OperatorType.subtract)
            .appendOperator(OperatorType.add),
        const InputBuffer(<Token>[
          NumberToken('5'),
          OperatorToken(OperatorType.add),
        ]),
      );
      expect(
        typeDigits(empty, '5')
            .appendOperator(OperatorType.multiply)
            .appendOperator(OperatorType.subtract)
            .appendOperator(OperatorType.subtract),
        const InputBuffer(<Token>[
          NumberToken('5'),
          OperatorToken(OperatorType.multiply),
          UnaryToken(negative: true),
        ]),
      );
    });

    test('an operator after a value is appended', () {
      expect(
        const InputBuffer(<Token>[ConstantToken(MathConstant.pi)])
            .appendOperator(OperatorType.add),
        const InputBuffer(<Token>[
          ConstantToken(MathConstant.pi),
          OperatorToken(OperatorType.add),
        ]),
      );
      expect(
        const InputBuffer(<Token>[
          LeftParenToken(),
          NumberToken('2'),
          RightParenToken(),
        ]).appendOperator(OperatorType.multiply),
        const InputBuffer(<Token>[
          LeftParenToken(),
          NumberToken('2'),
          RightParenToken(),
          OperatorToken(OperatorType.multiply),
        ]),
      );
    });

    test('an operator cannot open a function or bracket', () {
      const InputBuffer function = InputBuffer(<Token>[FunctionToken('sin')]);
      expect(function.appendOperator(OperatorType.add), function);
      expect(
        function.appendOperator(OperatorType.subtract),
        const InputBuffer(<Token>[
          FunctionToken('sin'),
          UnaryToken(negative: true),
        ]),
      );
    });
  });

  test('buffers compare by their tokens', () {
    expect(
      typeDigits(empty, '12'),
      const InputBuffer(<Token>[NumberToken('12')]),
    );
    expect(
      typeDigits(empty, '12'),
      isNot(const InputBuffer(<Token>[NumberToken('13')])),
    );
    expect(
      typeDigits(empty, '12').hashCode,
      const InputBuffer(<Token>[NumberToken('12')]).hashCode,
    );
  });
}
