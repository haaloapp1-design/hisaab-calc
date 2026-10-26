import 'package:calculator/core/engine/calc_result.dart';
import 'package:calculator/core/programmer/base_format.dart';
import 'package:calculator/core/programmer/prog_parser.dart';
import 'package:calculator/core/programmer/word.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProgSuccess ok(
    String source, {
    NumberBase base = NumberBase.dec,
    WordSize size = WordSize.bits32,
  }) {
    final ProgResult result = ProgEngine.evaluate(
      source,
      base: base,
      size: size,
    );
    expect(result, isA<ProgSuccess>(), reason: '"$source" → $result');
    return result as ProgSuccess;
  }

  BigInt dec(
    String source, {
    NumberBase base = NumberBase.dec,
    WordSize size = WordSize.bits32,
  }) => ok(source, base: base, size: size).value.signed;

  String text(
    String source,
    NumberBase base, {
    NumberBase? inputBase,
    WordSize size = WordSize.bits32,
  }) =>
      formatInBase(ok(source, base: inputBase ?? base, size: size).value, base);

  CalcError? error(
    String source, {
    NumberBase base = NumberBase.dec,
    WordSize size = WordSize.bits32,
  }) {
    final ProgResult result = ProgEngine.evaluate(
      source,
      base: base,
      size: size,
    );
    return result is ProgFailure ? result.error : null;
  }

  group('arithmetic and precedence', () {
    test('applies the §11 C precedence', () {
      expect(dec('2 + 3 × 4'), BigInt.from(14));
      expect(dec('(2 + 3) × 4'), BigInt.from(20));
      expect(dec('2 + 3 × 4 − 5'), BigInt.from(9));
      expect(dec('1 + 2 << 3'), BigInt.from(24));
      expect(dec('16 >> 1 + 1'), BigInt.from(4));
      expect(dec('1 OR 2 XOR 3 AND 4'), BigInt.from(3));
      expect(dec('NOT 5 AND 3'), BigInt.from(2));
      expect(dec('2 × NOT 0'), BigInt.from(-2));
      expect(dec('6 AND 3 NAND 2'), BigInt.from(-3));
    });

    test('accepts unary signs and brackets', () {
      expect(dec('−2 × 3'), BigInt.from(-6));
      expect(dec('5 × −2'), BigInt.from(-10));
      expect(dec('−(−5)'), BigInt.from(5));
      expect(dec('+(2 + 3)'), BigInt.from(5));
      expect(dec('((2))'), BigInt.from(2));
    });

    test('ignores whitespace and ASCII operator aliases', () {
      expect(dec('5AND3'), BigInt.from(1));
      expect(dec('  5   AND   3  '), BigInt.from(1));
      expect(dec('5 * 3'), BigInt.from(15));
      expect(dec('8 / 2'), BigInt.from(4));
      expect(dec('5 - 3'), BigInt.from(2));
      expect(dec('5 MOD 3'), BigInt.from(2));
      expect(dec('5 & 3'), BigInt.from(1));
      expect(dec('5 | 3'), BigInt.from(7));
      expect(dec('5 ^ 3'), BigInt.from(6));
      expect(dec('~5'), BigInt.from(-6));
    });
  });

  group('division and mod', () {
    test('divides by truncating toward zero', () {
      expect(dec('7 ÷ 2'), BigInt.from(3));
      expect(dec('−7 ÷ 2'), BigInt.from(-3));
      expect(dec('7 ÷ −2'), BigInt.from(-3));
      expect(dec('−7 ÷ −2'), BigInt.from(3));
      expect(dec('−1 ÷ 2'), BigInt.zero);
    });

    test('mod keeps the sign of the dividend', () {
      expect(dec('−5 mod 3'), BigInt.from(-2));
      expect(dec('5 mod −3'), BigInt.from(2));
      expect(dec('−5 mod −3'), BigInt.from(-2));
      expect(dec('5 mod 3'), BigInt.from(2));
    });

    test('dividing or taking mod by zero is the §7 error', () {
      expect(error('1 ÷ 0'), CalcError.divideByZero);
      expect(error('1 / 0'), CalcError.divideByZero);
      expect(error('5 mod 0'), CalcError.divideByZero);
      expect(error('5 mod (2 − 2)'), CalcError.divideByZero);
    });
  });

  group('bitwise ops', () {
    test('AND, OR, XOR and NOT', () {
      expect(dec('5 AND 3'), BigInt.from(1));
      expect(dec('5 OR 3'), BigInt.from(7));
      expect(dec('5 XOR 3'), BigInt.from(6));
      expect(dec('NOT 0'), BigInt.from(-1));
      expect(dec('NOT 5'), BigInt.from(-6));
      expect(dec('NOT (0 AND 0)'), BigInt.from(-1));
      expect(dec('NOT NOT 5'), BigInt.from(5));
      expect(dec('−6 AND 3'), BigInt.from(2));
    });

    test('NAND is ~(a AND b) & mask', () {
      expect(dec('5 NAND 3'), BigInt.from(-2));
      expect(text('5 NAND 3', NumberBase.hex), 'FFFFFFFE');
      expect(text('NOT 0', NumberBase.bin, size: WordSize.bits8), '1111 1111');
    });
  });

  group('shifts', () {
    test('left shifts mask and right shifts keep the sign', () {
      expect(dec('1 << 3'), BigInt.from(8));
      expect(dec('8 >> 1'), BigInt.from(4));
      expect(dec('−8 >> 1'), BigInt.from(-4));
      expect(dec('−1 >> 1'), BigInt.from(-1));
      expect(dec('−1 << 1'), BigInt.from(-2));
      expect(dec('8 >> 1 + 1'), BigInt.from(2));
    });

    test('a shift by the word size or more is well defined', () {
      expect(dec('1 << 31'), BigInt.from(-2147483648));
      expect(dec('1 << 32'), BigInt.zero);
      expect(dec('1 << 40'), BigInt.zero);
      expect(dec('1 >> 40'), BigInt.zero);
      expect(dec('−1 >> 40'), BigInt.from(-1));
      expect(dec('1 << 7', size: WordSize.bits8), BigInt.from(-128));
      expect(dec('1 << 8', size: WordSize.bits8), BigInt.zero);
      expect(dec('−8 >> 4', size: WordSize.bits8), BigInt.from(-1));
    });

    test('a negative shift count is undefined', () {
      expect(error('1 << −1'), CalcError.domain);
      expect(error('1 >> −1'), CalcError.domain);
      expect(error('1 << (0 − 1)'), CalcError.domain);
    });
  });

  group('word size and wrap-around', () {
    test('every width wraps its results', () {
      expect(dec('127 + 1', size: WordSize.bits8), BigInt.from(-128));
      expect(dec('200 + 100', size: WordSize.bits8), BigInt.from(44));
      expect(dec('100 × 3', size: WordSize.bits8), BigInt.from(44));
      expect(dec('255 + 1', size: WordSize.bits8), BigInt.zero);
      expect(dec('−128 − 1', size: WordSize.bits8), BigInt.from(127));
      expect(dec('−128 ÷ −1', size: WordSize.bits8), BigInt.from(-128));
      expect(dec('32767 + 1', size: WordSize.bits16), BigInt.from(-32768));
      expect(dec('2147483647 + 1'), BigInt.from(-2147483648));
      expect(
        dec('9223372036854775807 + 1', size: WordSize.bits64),
        BigInt.parse('-9223372036854775808'),
      );
    });

    test('intermediate results wrap, not only the final one', () {
      expect(dec('(200 + 100) ÷ 2', size: WordSize.bits8), BigInt.from(22));
      expect(dec('(255 + 1) ÷ 2', size: WordSize.bits8), BigInt.zero);
    });

    test('the chosen width applies to every base row', () {
      expect(text('NOT 0', NumberBase.hex, size: WordSize.bits8), 'FF');
      expect(text('NOT 0', NumberBase.hex, size: WordSize.bits16), 'FFFF');
      expect(text('NOT 0', NumberBase.hex, size: WordSize.bits32), 'FFFFFFFF');
      expect(
        text('NOT 0', NumberBase.hex, size: WordSize.bits64),
        'FFFFFFFFFFFFFFFF',
      );
      expect(
        text(
          '255 + 1',
          NumberBase.bin,
          inputBase: NumberBase.dec,
          size: WordSize.bits8,
        ),
        '0000',
      );
    });

    test('255 + 1 is 0 in 8-bit and 256 in 32-bit', () {
      expect(dec('255 + 1', size: WordSize.bits8), BigInt.zero);
      expect(dec('255 + 1', size: WordSize.bits16), BigInt.from(256));
    });
  });

  group('input bases', () {
    test('reads digits in the selected base', () {
      expect(dec('FF AND 0F', base: NumberBase.hex), BigInt.from(15));
      expect(dec('A + 1', base: NumberBase.hex), BigInt.from(11));
      expect(dec('B AND 3', base: NumberBase.hex), BigInt.from(3));
      expect(dec('ff and 0f', base: NumberBase.hex), BigInt.from(15));
      expect(dec('1010 AND 0110', base: NumberBase.bin), BigInt.from(2));
      expect(dec('101 + 1', base: NumberBase.bin), BigInt.from(6));
      expect(dec('17 + 1', base: NumberBase.oct), BigInt.from(16));
      expect(text('FF', NumberBase.hex), 'FF');
    });

    test('rejects digits that are not valid in the base', () {
      expect(error('A'), CalcError.syntax);
      expect(error('8', base: NumberBase.oct), CalcError.syntax);
      expect(error('2', base: NumberBase.bin), CalcError.syntax);
      expect(error('12G'), CalcError.syntax);
    });
  });

  group('syntax errors', () {
    test('reports §7 syntax for malformed input', () {
      for (final String source in <String>[
        '',
        '   ',
        '2 +',
        '(2 + 3',
        '2 3',
        ')',
        'AND 5',
        '5 AND',
        '5 NOT 3',
        '1.5',
        '5 \$ 3',
        '× 5',
        '5 × × 3',
        '5 << ',
      ]) {
        expect(error(source), CalcError.syntax, reason: '"$source"');
      }
    });

    test('a failed evaluation carries the §7 display text', () {
      expect(
        const ProgFailure(CalcError.divideByZero).error.displayText,
        "Can't divide by zero",
      );
    });
  });

  group('result type', () {
    test('defaults to DEC 32-bit', () {
      final ProgSuccess result = ok('10');

      expect(result.value.size, WordSize.bits32);
      expect(result.value.signed, BigInt.from(10));
      expect(result.value.raw, BigInt.from(10));
    });

    test('success and failure compare by value', () {
      expect(ProgEngine.evaluate('5'), ProgSuccess(Word(BigInt.from(5))));
      expect(
        ProgEngine.evaluate('1 ÷ 0'),
        const ProgFailure(CalcError.divideByZero),
      );
      expect(ProgEngine.evaluate(''), const ProgFailure(CalcError.syntax));
      expect(
        ProgEngine.evaluate('5').toString(),
        'ProgSuccess(Word(5, 32-bit))',
      );
      expect(
        const ProgFailure(CalcError.syntax).toString(),
        'ProgFailure(syntax)',
      );
    });
  });
}
