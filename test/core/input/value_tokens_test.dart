import 'package:calculator/core/engine/token.dart';
import 'package:calculator/core/input/value_tokens.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('valueTokens', () {
    test('keeps a positive number as one unsigned token', () {
      expect(
        valueTokens(Decimal.parse('12.5')),
        <Token>[const NumberToken('12.5')],
      );
    });

    test('zero is a plain number', () {
      expect(valueTokens(Decimal.zero), <Token>[const NumberToken('0')]);
    });

    test('wraps a negative value in a signed bracket', () {
      expect(valueTokens(Decimal.parse('-8')), <Token>[
        const LeftParenToken(),
        const UnaryToken(negative: true),
        const NumberToken('8'),
        const RightParenToken(),
      ]);
    });

    test('the wrapper keeps the decimals of a negative value', () {
      expect(valueTokens(Decimal.parse('-0.5')), <Token>[
        const LeftParenToken(),
        const UnaryToken(negative: true),
        const NumberToken('0.5'),
        const RightParenToken(),
      ]);
    });
  });
}
