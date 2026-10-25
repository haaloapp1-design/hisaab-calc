import 'package:calculator/core/engine/token.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Token equality', () {
    test('numbers compare by raw value', () {
      expect(const NumberToken('12.5'), const NumberToken('12.5'));
      expect(const NumberToken('12.5'), isNot(const NumberToken('12.50')));
    });

    test('operators compare by type and hidden-× flag', () {
      expect(
        const OperatorToken(OperatorType.multiply),
        const OperatorToken(OperatorType.multiply),
      );
      expect(
        const OperatorToken(OperatorType.multiply, implicit: true),
        isNot(const OperatorToken(OperatorType.multiply)),
      );
      expect(
        const OperatorToken(OperatorType.add),
        isNot(const OperatorToken(OperatorType.subtract)),
      );
    });

    test('functions keep their name, including the bracket', () {
      expect(const FunctionToken('sin'), const FunctionToken('sin'));
      expect(const FunctionToken('sin'), isNot(const FunctionToken('cos')));
    });

    test('constants, postfix, parens and Ans are distinct tokens', () {
      expect(
        const ConstantToken(MathConstant.pi),
        const ConstantToken(MathConstant.pi),
      );
      expect(
        const ConstantToken(MathConstant.pi),
        isNot(const ConstantToken(MathConstant.e)),
      );
      expect(
        const PostfixToken(PostfixType.factorial),
        const PostfixToken(PostfixType.factorial),
      );
      expect(const LeftParenToken(), const LeftParenToken());
      expect(const LeftParenToken(), isNot(const RightParenToken()));
      expect(const AnsToken(), const AnsToken());
      expect(const AnsToken(), isNot(const NumberToken('0')));
    });

    test('unary signs compare by polarity', () {
      expect(
        const UnaryToken(negative: true),
        const UnaryToken(negative: true),
      );
      expect(
        const UnaryToken(negative: true),
        isNot(const UnaryToken(negative: false)),
      );
      expect(
        const UnaryToken(negative: false),
        isNot(const OperatorToken(OperatorType.add)),
      );
    });
  });
}
