import 'package:calculator/core/engine/token.dart';
import 'package:calculator/core/input/input_buffer.dart';
import 'package:calculator/features/calculator/calc_state.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CalcState state(List<Token> tokens, {Decimal? preview, Decimal? result}) =>
      CalcState(buffer: InputBuffer(tokens), preview: preview, result: result);

  group('displayValue', () {
    test('an empty calculator shows 0', () {
      expect(state(const <Token>[]).displayValue, Decimal.zero);
    });

    test('shows the number being typed, including a trailing dot', () {
      expect(
        state(<Token>[const NumberToken('1800')]).displayValue,
        Decimal.parse('1800'),
      );
      expect(
        state(<Token>[const NumberToken('12.')]).displayValue,
        Decimal.parse('12'),
      );
    });

    test('prefers the live preview over the typed number', () {
      expect(
        state(<Token>[
          const NumberToken('5'),
          const OperatorToken(OperatorType.add),
          const NumberToken('3'),
        ], preview: Decimal.parse('8')).displayValue,
        Decimal.parse('8'),
      );
    });

    test('prefers the committed result over the preview', () {
      expect(
        state(
          <Token>[
            const NumberToken('5'),
            const OperatorToken(OperatorType.add),
            const NumberToken('3'),
          ],
          preview: Decimal.parse('1'),
          result: Decimal.parse('8'),
        ).displayValue,
        Decimal.parse('8'),
      );
    });

    test('evaluates a signed number and a constant with no operator', () {
      expect(
        state(<Token>[
          const LeftParenToken(),
          const UnaryToken(negative: true),
          const NumberToken('5'),
          const RightParenToken(),
        ]).displayValue,
        Decimal.parse('-5'),
      );

      expect(
        state(<Token>[const ConstantToken(MathConstant.pi)]).displayValue
            .toDouble(),
        closeTo(3.14159265358979, 1e-9),
      );
    });

    test('keeps the value of the finished part of an expression', () {
      expect(
        state(<Token>[
          const NumberToken('5'),
          const OperatorToken(OperatorType.add),
        ]).displayValue,
        Decimal.parse('5'),
      );

      expect(
        state(<Token>[
          const NumberToken('5'),
          const OperatorToken(OperatorType.add),
          const NumberToken('3'),
          const OperatorToken(OperatorType.add),
        ]).displayValue,
        Decimal.parse('8'),
      );
    });
  });
}
