import 'package:calculator/core/engine/calc_result.dart';
import 'package:calculator/core/engine/token.dart';
import 'package:calculator/core/input/last_operation.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LastOperation.of', () {
    test('finds the only operator and the tokens after it', () {
      final LastOperation? operation = LastOperation.of(<Token>[
        const NumberToken('5'),
        const OperatorToken(OperatorType.add),
        const NumberToken('3'),
      ]);

      expect(
        operation,
        const LastOperation(
          operator: OperatorType.add,
          rightTokens: <Token>[NumberToken('3')],
        ),
      );
    });

    test('takes the rightmost top-level operator', () {
      final LastOperation operation = LastOperation.of(<Token>[
        const NumberToken('2'),
        const OperatorToken(OperatorType.add),
        const NumberToken('3'),
        const OperatorToken(OperatorType.multiply),
        const NumberToken('4'),
      ])!;

      expect(operation.operator, OperatorType.multiply);
      expect(operation.rightTokens, <Token>[const NumberToken('4')]);
    });

    test('ignores operators inside brackets', () {
      final LastOperation outside = LastOperation.of(<Token>[
        const LeftParenToken(),
        const NumberToken('2'),
        const OperatorToken(OperatorType.add),
        const NumberToken('3'),
        const RightParenToken(),
        const OperatorToken(OperatorType.multiply),
        const NumberToken('4'),
      ])!;
      expect(outside.operator, OperatorType.multiply);
      expect(outside.rightTokens, <Token>[const NumberToken('4')]);

      final LastOperation inside = LastOperation.of(<Token>[
        const NumberToken('2'),
        const OperatorToken(OperatorType.add),
        const LeftParenToken(),
        const NumberToken('3'),
        const OperatorToken(OperatorType.multiply),
        const NumberToken('4'),
        const RightParenToken(),
      ])!;
      expect(inside.operator, OperatorType.add);
      expect(inside.rightTokens, <Token>[
        const LeftParenToken(),
        const NumberToken('3'),
        const OperatorToken(OperatorType.multiply),
        const NumberToken('4'),
        const RightParenToken(),
      ]);
    });

    test('keeps a whole right operand, including functions and brackets', () {
      final LastOperation operation = LastOperation.of(<Token>[
        const NumberToken('5'),
        const OperatorToken(OperatorType.add),
        const FunctionToken('sin'),
        const NumberToken('30'),
      ])!;

      expect(operation.operator, OperatorType.add);
      expect(operation.rightTokens, <Token>[
        const FunctionToken('sin'),
        const NumberToken('30'),
      ]);
    });

    test('counts the implicit × as an operator', () {
      final LastOperation operation = LastOperation.of(<Token>[
        const NumberToken('2'),
        const OperatorToken(OperatorType.multiply, implicit: true),
        const ConstantToken(MathConstant.pi),
      ])!;

      expect(operation.operator, OperatorType.multiply);
      expect(operation.rightTokens, <Token>[
        const ConstantToken(MathConstant.pi),
      ]);
    });

    test('returns null when there is nothing to repeat', () {
      expect(LastOperation.of(const <Token>[]), isNull);
      expect(
        LastOperation.of(<Token>[const NumberToken('5')]),
        isNull,
      );
      expect(
        LastOperation.of(<Token>[
          const NumberToken('2'),
          const OperatorToken(OperatorType.add),
        ]),
        isNull,
      );
      expect(
        LastOperation.of(<Token>[
          const NumberToken('2'),
          const UnaryToken(negative: true),
          const NumberToken('3'),
        ]),
        isNull,
      );
    });
  });

  group('LastOperation.apply', () {
    test('applies the operation to a plain value', () {
      const LastOperation operation = LastOperation(
        operator: OperatorType.add,
        rightTokens: <Token>[NumberToken('3')],
      );

      expect(operation.apply(Decimal.parse('8')), Success(Decimal.parse('11')));
    });

    test('brackets a negative left value', () {
      const LastOperation operation = LastOperation(
        operator: OperatorType.add,
        rightTokens: <Token>[NumberToken('3')],
      );

      expect(
        operation.apply(Decimal.parse('-10')),
        Success(Decimal.parse('-7')),
      );
    });

    test('evaluates a compound right operand', () {
      const LastOperation operation = LastOperation(
        operator: OperatorType.add,
        rightTokens: <Token>[FunctionToken('sin'), NumberToken('30')],
      );

      expect(
        operation.apply(Decimal.parse('10')),
        Success(Decimal.parse('10.5')),
      );
    });
  });
}
