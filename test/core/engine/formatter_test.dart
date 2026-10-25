import 'package:calculator/core/engine/formatter.dart';
import 'package:calculator/core/engine/token.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

Decimal d(String source) => Decimal.parse(source);

String auto(Decimal value) => formatNumber(value);

void main() {
  group('Auto: 12 significant digits', () {
    test('keeps exact decimals and strips trailing zeros', () {
      expect(auto(d('0.3')), '0.3');
      expect(auto(d('1.2300')), '1.23');
      expect(auto(d('2.000')), '2');
      expect(auto(Decimal.zero), '0');
    });

    test('rounds to 12 significant digits', () {
      expect(auto(d('1.234567890123456')), '1.23456789012');
      expect(auto(d('0.0001234567890123456')), '0.000123456789012');
      expect(auto(d('0.99999999999999999999999999999999')), '1');
    });

    test('groups the integer part', () {
      expect(auto(d('1234567.891')), '1,234,567.891');
      expect(auto(d('1000')), '1,000');
      expect(auto(d('999')), '999');
    });
  });

  group('fixed decimal places', () {
    test('rounds half-up and keeps trailing zeros', () {
      const NumberFormatOptions two = NumberFormatOptions(decimalPlaces: 2);
      expect(formatNumber(d('1.005'), options: two), '1.01');
      expect(formatNumber(d('1.5'), options: two), '1.50');
      expect(formatNumber(d('2'), options: two), '2.00');
      expect(formatNumber(d('0.999'), options: two), '1.00');
      expect(formatNumber(d('1'), options: two), '1.00');
    });

    test('zero and ten places', () {
      expect(
        formatNumber(
          d('2.5'),
          options: const NumberFormatOptions(decimalPlaces: 0),
        ),
        '3',
      );
      expect(
        formatNumber(
          d('2.4'),
          options: const NumberFormatOptions(decimalPlaces: 0),
        ),
        '2',
      );
      expect(
        formatNumber(
          d('1'),
          options: const NumberFormatOptions(decimalPlaces: 10),
        ),
        '1.0000000000',
      );
    });

    test('groups with fixed places', () {
      const NumberFormatOptions two = NumberFormatOptions(decimalPlaces: 2);
      expect(formatNumber(d('1234.5'), options: two), '1,234.50');
      expect(formatNumber(d('-1234.5'), options: two), '−1,234.50');
      expect(formatNumberForCopy(d('-1234.5'), options: two), '-1,234.50');
    });
  });

  group('separators', () {
    test('grouping can be switched off', () {
      const NumberFormatOptions off = NumberFormatOptions(useGrouping: false);
      expect(formatNumber(d('1234567.891'), options: off), '1234567.891');
    });

    test('locale decimal and group marks are used', () {
      const NumberFormatOptions de = NumberFormatOptions(
        decimalSeparator: ',',
        groupSeparator: '.',
      );
      expect(formatNumber(d('1234567.891'), options: de), '1.234.567,891');
    });

    test('options can be read from intl for a locale', () {
      final NumberFormatOptions us = numberFormatOptionsFor('en_US');
      expect(us.decimalSeparator, '.');
      expect(us.groupSeparator, ',');
      expect(formatNumber(d('1234567.891'), options: us), '1,234,567.891');

      final NumberFormatOptions de = numberFormatOptionsFor('de_DE');
      expect(de.decimalSeparator, ',');
      expect(de.groupSeparator, '.');
      expect(formatNumber(d('1234567.891'), options: de), '1.234.567,891');
    });
  });

  group('scientific notation', () {
    test('thresholds are 1e15 and 1e-9', () {
      expect(auto(d('1e14')), '100,000,000,000,000');
      expect(auto(d('1e15')), '1E+15');
      expect(auto(d('1e-9')), '0.000000001');
      expect(auto(d('1e-10')), '1E-10');
      expect(auto(Decimal.zero), '0');
    });

    test('mantissa has at most 10 digits and no trailing zeros', () {
      expect(auto(d('1.234567890123e18')), '1.23456789E+18');
      expect(auto(d('1.234567890123e-12')), '1.23456789E-12');
      expect(auto(d('2.5e-11')), '2.5E-11');
    });

    test('fixed places keep their trailing zeros in the mantissa', () {
      const NumberFormatOptions two = NumberFormatOptions(decimalPlaces: 2);
      expect(formatNumber(d('1e18'), options: two), '1.00E+18');
    });

    test('negative sign follows the display/copy rule', () {
      expect(auto(d('-1.5e18')), '−1.5E+18');
      expect(formatNumberForCopy(d('-1.5e18')), '-1.5E+18');
      expect(formatNumberForCopy(d('-0.5')), '-0.5');
    });
  });

  group('typed numbers in the expression line', () {
    test('keeps every typed digit and only groups', () {
      expect(formatTypedNumber('1234567.891'), '1,234,567.891');
      expect(formatTypedNumber('12.50'), '12.50');
      expect(formatTypedNumber('0.5'), '0.5');
      expect(formatTypedNumber('12.'), '12.');
      expect(formatTypedNumber('1234'), '1,234');
    });

    test('honours grouping and locale marks', () {
      expect(
        formatTypedNumber(
          '1234567.891',
          options: const NumberFormatOptions(useGrouping: false),
        ),
        '1234567.891',
      );
      expect(
        formatTypedNumber(
          '1234567.891',
          options: const NumberFormatOptions(
            decimalSeparator: ',',
            groupSeparator: '.',
          ),
        ),
        '1.234.567,891',
      );
    });
  });

  group('expression line', () {
    test('joins typed tokens with a space around operators', () {
      expect(
        formatExpression(<Token>[
          const NumberToken('1800'),
          const OperatorToken(OperatorType.add),
          const NumberToken('21'),
          const OperatorToken(OperatorType.add),
          const NumberToken('88'),
        ]),
        '1,800 + 21 + 88',
      );

      expect(
        formatExpression(<Token>[
          const NumberToken('1234'),
          const OperatorToken(OperatorType.multiply),
          const NumberToken('56.5'),
        ]),
        '1,234 × 56.5',
      );
    });

    test('uses the typographic signs of the keypad', () {
      const Map<OperatorType, String> signs = <OperatorType, String>{
        OperatorType.subtract: '−',
        OperatorType.divide: '÷',
        OperatorType.power: '^',
        OperatorType.mod: 'mod',
      };

      for (final MapEntry<OperatorType, String> entry in signs.entries) {
        expect(
          formatExpression(<Token>[
            const NumberToken('6'),
            OperatorToken(entry.key),
            const NumberToken('2'),
          ]),
          '6 ${entry.value} 2',
        );
      }
    });

    test('hides the implicit multiply', () {
      expect(
        formatExpression(<Token>[
          const NumberToken('2'),
          const OperatorToken(OperatorType.multiply, implicit: true),
          const ConstantToken(MathConstant.pi),
        ]),
        '2π',
      );

      expect(
        formatExpression(<Token>[
          const NumberToken('3'),
          const OperatorToken(OperatorType.multiply, implicit: true),
          const LeftParenToken(),
          const NumberToken('4'),
          const OperatorToken(OperatorType.add),
          const NumberToken('1'),
          const RightParenToken(),
        ]),
        '3(4 + 1)',
      );
    });

    test('attaches unary signs to their number', () {
      expect(
        formatExpression(<Token>[
          const LeftParenToken(),
          const UnaryToken(negative: true),
          const NumberToken('5'),
          const RightParenToken(),
        ]),
        '(−5)',
      );

      expect(
        formatExpression(<Token>[
          const NumberToken('5'),
          const OperatorToken(OperatorType.multiply),
          const UnaryToken(negative: true),
          const NumberToken('5'),
        ]),
        '5 × −5',
      );

      expect(
        formatExpression(<Token>[
          const FunctionToken('sin'),
          const UnaryToken(negative: true),
          const NumberToken('30'),
          const RightParenToken(),
        ]),
        'sin(−30)',
      );
    });

    test('functions carry their bracket and constants use their glyph', () {
      expect(
        formatExpression(<Token>[
          const FunctionToken('sin'),
          const NumberToken('30'),
          const RightParenToken(),
        ]),
        'sin(30)',
      );
      expect(
        formatExpression(<Token>[const ConstantToken(MathConstant.e)]),
        'e',
      );
    });

    test('postfix keys hug the value they apply to', () {
      expect(
        formatExpression(<Token>[
          const NumberToken('5'),
          const PostfixToken(PostfixType.factorial),
        ]),
        '5!',
      );
      expect(
        formatExpression(<Token>[
          const NumberToken('50'),
          const PostfixToken(PostfixType.percent),
        ]),
        '50%',
      );
      expect(
        formatExpression(<Token>[
          const NumberToken('5'),
          const PostfixToken(PostfixType.square),
        ]),
        '5²',
      );
      expect(
        formatExpression(<Token>[
          const NumberToken('5'),
          const PostfixToken(PostfixType.cube),
        ]),
        '5³',
      );
      expect(
        formatExpression(<Token>[
          const NumberToken('4'),
          const PostfixToken(PostfixType.reciprocal),
        ]),
        '4⁻¹',
      );
    });

    test('spaces the y-th root operator', () {
      expect(
        formatExpression(<Token>[
          const NumberToken('8'),
          const OperatorToken(OperatorType.root),
          const NumberToken('3'),
        ]),
        '8 ʸ√ 3',
      );
    });

    test('renders Ans and an empty buffer', () {
      expect(
        formatExpression(<Token>[
          const AnsToken(),
          const OperatorToken(OperatorType.add),
          const NumberToken('2'),
        ]),
        'Ans + 2',
      );
      expect(formatExpression(<Token>[]), '');
    });

    test('honours number options, including a trailing dot', () {
      expect(
        formatExpression(<Token>[
          const NumberToken('1234.50'),
        ], options: const NumberFormatOptions(useGrouping: false)),
        '1234.50',
      );
      expect(formatExpression(<Token>[const NumberToken('12.')]), '12.');
      expect(
        formatExpression(
          <Token>[const NumberToken('1234.5')],
          options: const NumberFormatOptions(
            decimalSeparator: ',',
            groupSeparator: '.',
          ),
        ),
        '1.234,5',
      );
    });
  });

  group('localized options (SPEC §3)', () {
    test('an en_US locale keeps the dot/comma pair', () {
      final NumberFormatOptions options = NumberFormatOptions.localized(
        locale: 'en_US',
      );

      expect(options.decimalSeparator, '.');
      expect(options.groupSeparator, ',');
      expect(options.useGrouping, isTrue);
      expect(options.decimalPlaces, isNull);
      expect(formatNumber(d('1234.5'), options: options), '1,234.5');
    });

    test('a de_DE locale swaps the separators', () {
      final NumberFormatOptions options = NumberFormatOptions.localized(
        locale: 'de_DE',
      );

      expect(options.decimalSeparator, ',');
      expect(options.groupSeparator, '.');
      expect(formatNumber(d('1234.5'), options: options), '1.234,5');
    });

    test('the Settings values become fixed decimals and grouping', () {
      final NumberFormatOptions options = NumberFormatOptions.localized(
        decimalPlaces: 2,
        useGrouping: false,
        locale: 'en_US',
      );

      expect(formatNumber(d('600'), options: options), '600.00');
      expect(formatExpression(
        <Token>[const NumberToken('1800')],
        options: options,
      ), '1800');
    });

    test('an unknown locale falls back to the dot/comma pair', () {
      final NumberFormatOptions options = NumberFormatOptions.localized(
        locale: 'zz_ZZ',
      );

      expect(options.decimalSeparator, '.');
      expect(options.groupSeparator, ',');
    });
  });
}
