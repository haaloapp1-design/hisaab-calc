import 'package:calculator/core/programmer/word.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WordSize', () {
    test('offers 8, 16, 32 and 64 bits with 32-bit as the default', () {
      expect(WordSize.values.map((WordSize size) => size.bits), <int>[
        8,
        16,
        32,
        64,
      ]);
      expect(WordSize.standard, WordSize.bits32);
      expect(WordSize.bits8.label, '8-bit');
      expect(WordSize.bits64.label, '64-bit');
    });

    test('exposes the §11 mask, modulus and signed range of each width', () {
      expect(WordSize.bits8.mask, BigInt.from(0xFF));
      expect(WordSize.bits16.mask, BigInt.parse('FFFF', radix: 16));
      expect(WordSize.bits32.mask, BigInt.parse('FFFFFFFF', radix: 16));
      expect(WordSize.bits64.mask, BigInt.parse('FFFFFFFFFFFFFFFF', radix: 16));
      expect(WordSize.bits8.modulus, BigInt.from(0x100));
      expect(WordSize.bits32.signBit, BigInt.from(0x80000000));
      expect(WordSize.bits8.minSigned, BigInt.from(-128));
      expect(WordSize.bits8.maxSigned, BigInt.from(127));
      expect(WordSize.bits64.minSigned, BigInt.parse('-9223372036854775808'));
      expect(WordSize.bits64.maxSigned, BigInt.parse('9223372036854775807'));
    });
  });

  group('Word', () {
    test('defaults to 32-bit and keeps a value that fits', () {
      final Word word = Word(BigInt.from(2021));

      expect(word.size, WordSize.bits32);
      expect(word.raw, BigInt.from(2021));
      expect(word.signed, BigInt.from(2021));
      expect(word.isNegative, isFalse);
    });

    test('stores the two\'s-complement pattern of a negative value', () {
      expect(Word(BigInt.from(-1), size: WordSize.bits8).raw, BigInt.from(255));
      expect(
        Word(BigInt.from(-1), size: WordSize.bits16).raw,
        BigInt.from(65535),
      );
      expect(
        Word(BigInt.from(-1), size: WordSize.bits32).raw,
        BigInt.from(4294967295),
      );
      expect(
        Word(BigInt.from(-1), size: WordSize.bits64).raw,
        BigInt.parse('18446744073709551615'),
      );
      expect(Word(BigInt.from(-5), size: WordSize.bits8).raw, BigInt.from(251));
    });

    test('reads the signed view from the top bit', () {
      expect(
        Word(BigInt.from(0x7F), size: WordSize.bits8).signed,
        BigInt.from(127),
      );
      expect(
        Word(BigInt.from(0x80), size: WordSize.bits8).signed,
        BigInt.from(-128),
      );
      expect(
        Word(BigInt.from(0xFF), size: WordSize.bits8).signed,
        BigInt.from(-1),
      );
      expect(
        Word(BigInt.from(0x80000000), size: WordSize.bits32).signed,
        BigInt.from(-2147483648),
      );
      expect(
        Word(
          BigInt.parse('8000000000000000', radix: 16),
          size: WordSize.bits64,
        ).signed,
        BigInt.parse('-9223372036854775808'),
      );
      expect(
        Word(BigInt.from(0xC8), size: WordSize.bits8).signed,
        BigInt.from(-56),
      );
    });

    test('re-masks values that do not fit, wrapping two\'s complement', () {
      expect(
        Word(BigInt.from(128), size: WordSize.bits8).signed,
        BigInt.from(-128),
      );
      expect(Word(BigInt.from(300), size: WordSize.bits8).raw, BigInt.from(44));
      expect(
        Word(BigInt.from(300), size: WordSize.bits8).signed,
        BigInt.from(44),
      );
      expect(
        Word(BigInt.from(-129), size: WordSize.bits8).signed,
        BigInt.from(127),
      );
      expect(
        Word(BigInt.parse('1FFFFFFFF', radix: 16), size: WordSize.bits32).raw,
        BigInt.parse('FFFFFFFF', radix: 16),
      );
    });

    test('withSize re-masks the current signed value', () {
      final Word minusOne = Word(BigInt.from(-1), size: WordSize.bits32);
      final Word wide = minusOne.withSize(WordSize.bits64);

      expect(wide.size, WordSize.bits64);
      expect(wide.signed, BigInt.from(-1));
      expect(wide.raw, BigInt.parse('FFFFFFFFFFFFFFFF', radix: 16));

      final Word truncated = Word(
        BigInt.from(300),
        size: WordSize.bits32,
      ).withSize(WordSize.bits8);
      expect(truncated.size, WordSize.bits8);
      expect(truncated.signed, BigInt.from(44));

      final Word signExtended = Word(
        BigInt.from(200),
        size: WordSize.bits8,
      ).withSize(WordSize.bits16);
      expect(signExtended.signed, BigInt.from(-56));
      expect(signExtended.raw, BigInt.from(65480));
    });

    test('withValue keeps the width and re-masks the new value', () {
      final Word word = Word(
        BigInt.from(5),
        size: WordSize.bits8,
      ).withValue(BigInt.from(300));

      expect(word.size, WordSize.bits8);
      expect(word.signed, BigInt.from(44));
    });

    test('zero is zero in every width', () {
      for (final WordSize size in WordSize.values) {
        final Word zero = Word.zero(size: size);

        expect(zero.raw, BigInt.zero);
        expect(zero.signed, BigInt.zero);
        expect(zero.isNegative, isFalse);
        expect(zero.size, size);
      }
    });

    test('equality covers the value and the width', () {
      final Word value = Word(BigInt.from(7));

      expect(value, Word(BigInt.from(7)));
      expect(value.hashCode, Word(BigInt.from(7)).hashCode);
      expect(value, isNot(Word(BigInt.from(7), size: WordSize.bits8)));
      expect(value, isNot(Word(BigInt.from(8))));
      expect(
        Word(BigInt.from(-1), size: WordSize.bits8),
        Word(BigInt.from(255), size: WordSize.bits8),
      );
    });

    test('toString shows the signed value and the width', () {
      expect(
        Word(BigInt.from(-1), size: WordSize.bits8).toString(),
        'Word(-1, 8-bit)',
      );
    });
  });
}
