import 'package:calculator/core/engine/formatter.dart';
import 'package:calculator/core/programmer/base_format.dart';
import 'package:calculator/core/programmer/word.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NumberBase', () {
    test('lists the four rows with their radix and label', () {
      expect(NumberBase.values.map((NumberBase base) => base.label), <String>[
        'HEX',
        'DEC',
        'OCT',
        'BIN',
      ]);
      expect(NumberBase.hex.radix, 16);
      expect(NumberBase.dec.radix, 10);
      expect(NumberBase.oct.radix, 8);
      expect(NumberBase.bin.radix, 2);
    });
  });

  group('formatInBase', () {
    test('matches the design sample for 2021', () {
      final Word word = Word(BigInt.from(2021));

      expect(formatInBase(word, NumberBase.hex), '7E5');
      expect(formatInBase(word, NumberBase.dec), '2021');
      expect(formatInBase(word, NumberBase.oct), '3745');
      expect(formatInBase(word, NumberBase.bin), '0111 1110 0101');
    });

    test('shows zero in every base', () {
      final Word zero = Word.zero();

      expect(formatInBase(zero, NumberBase.hex), '0');
      expect(formatInBase(zero, NumberBase.dec), '0');
      expect(formatInBase(zero, NumberBase.oct), '0');
      expect(formatInBase(zero, NumberBase.bin), '0000');
    });

    test('pads BIN to a multiple of four bits and groups by four', () {
      String bin(int value) =>
          formatInBase(Word(BigInt.from(value)), NumberBase.bin);

      expect(bin(1), '0001');
      expect(bin(5), '0101');
      expect(bin(16), '0001 0000');
      expect(bin(0xABC), '1010 1011 1100');
      expect(bin(0x1234), '0001 0010 0011 0100');
    });

    test('shows DEC signed and HEX/OCT/BIN unsigned (8-bit)', () {
      final Word minusOne = Word(BigInt.from(-1), size: WordSize.bits8);

      expect(formatInBase(minusOne, NumberBase.hex), 'FF');
      expect(formatInBase(minusOne, NumberBase.dec), '−1');
      expect(formatInBase(minusOne, NumberBase.oct), '377');
      expect(formatInBase(minusOne, NumberBase.bin), '1111 1111');

      final Word negative = Word(BigInt.from(-56), size: WordSize.bits8);
      expect(formatInBase(negative, NumberBase.dec), '−56');
      expect(formatInBase(negative, NumberBase.hex), 'C8');
      expect(formatInBase(negative, NumberBase.bin), '1100 1000');
    });

    test('shows the full 16-bit two\'s-complement pattern', () {
      final Word minusOne = Word(BigInt.from(-1), size: WordSize.bits16);

      expect(formatInBase(minusOne, NumberBase.hex), 'FFFF');
      expect(formatInBase(minusOne, NumberBase.oct), '177777');
      expect(formatInBase(minusOne, NumberBase.bin), '1111 1111 1111 1111');
    });

    test('shows the full 32-bit two\'s-complement pattern', () {
      final Word minusOne = Word(BigInt.from(-1), size: WordSize.bits32);

      expect(formatInBase(minusOne, NumberBase.hex), 'FFFFFFFF');
      expect(formatInBase(minusOne, NumberBase.oct), '37777777777');
      expect(
        formatInBase(minusOne, NumberBase.bin),
        '1111 1111 1111 1111 1111 1111 1111 1111',
      );
    });

    test('shows the full 64-bit two\'s-complement pattern', () {
      final Word minusOne = Word(BigInt.from(-1), size: WordSize.bits64);

      expect(formatInBase(minusOne, NumberBase.hex), 'FFFFFFFFFFFFFFFF');
      expect(formatInBase(minusOne, NumberBase.oct), '1777777777777777777777');
      expect(
        formatInBase(minusOne, NumberBase.bin),
        '1111 1111 1111 1111 1111 1111 1111 1111 '
        '1111 1111 1111 1111 1111 1111 1111 1111',
      );
    });

    test('handles the 64-bit signed minimum and maximum', () {
      final Word min = Word(
        BigInt.parse('8000000000000000', radix: 16),
        size: WordSize.bits64,
      );
      final Word max = Word(
        BigInt.parse('7FFFFFFFFFFFFFFF', radix: 16),
        size: WordSize.bits64,
      );

      expect(formatInBase(min, NumberBase.dec), '−9223372036854775808');
      expect(formatInBase(min, NumberBase.hex), '8000000000000000');
      expect(formatInBase(max, NumberBase.dec), '9223372036854775807');
      expect(formatInBase(max, NumberBase.hex), '7FFFFFFFFFFFFFFF');
    });

    test('uppercases HEX digits', () {
      final Word word = Word(BigInt.parse('abcdef', radix: 16));

      expect(formatInBase(word, NumberBase.hex), 'ABCDEF');
    });
  });

  group('formatBases', () {
    test('returns all four rows in HEX, DEC, OCT, BIN order', () {
      final Map<NumberBase, String> rows = formatBases(Word(BigInt.from(2021)));

      expect(rows.keys, NumberBase.values);
      expect(rows[NumberBase.hex], '7E5');
      expect(rows[NumberBase.dec], '2021');
      expect(rows[NumberBase.oct], '3745');
      expect(rows[NumberBase.bin], '0111 1110 0101');
    });

    test('re-masks a value that does not fit the word before formatting', () {
      final Map<NumberBase, String> rows = formatBases(
        Word(BigInt.from(-1), size: WordSize.bits8),
      );

      expect(rows[NumberBase.dec], '−1');
      expect(rows[NumberBase.hex], 'FF');
    });
  });

  group('formatBaseValue', () {
    test('groups the DEC row with the Settings separator', () {
      final Word word = Word(BigInt.from(2021));

      expect(formatBaseValue(word, NumberBase.dec), '2,021');
      expect(formatBaseValue(word, NumberBase.hex), '7E5');
      expect(formatBaseValue(word, NumberBase.oct), '3745');
      expect(formatBaseValue(word, NumberBase.bin), '0111 1110 0101');
    });

    test('groups a negative DEC value after the sign', () {
      final Word word = Word(BigInt.from(-2021));

      expect(formatBaseValue(word, NumberBase.dec), '−2,021');
    });

    test('honours the grouping switch and a locale separator', () {
      final Word word = Word(BigInt.from(1234567));

      expect(
        formatBaseValue(
          word,
          NumberBase.dec,
          options: const NumberFormatOptions(useGrouping: false),
        ),
        '1234567',
      );
      expect(
        formatBaseValue(
          word,
          NumberBase.dec,
          options: const NumberFormatOptions(groupSeparator: '.'),
        ),
        '1.234.567',
      );
    });

    test('never groups HEX/OCT/BIN', () {
      final Word word = Word(BigInt.from(1234567));

      expect(formatBaseValue(word, NumberBase.hex), '12D687');
      expect(
        formatBaseValue(word, NumberBase.bin),
        '0001 0010 1101 0110 1000 0111',
      );
    });

    test('keeps a 64-bit DEC value in plain digits', () {
      final Word word = Word(
        BigInt.parse('9223372036854775807'),
        size: WordSize.bits64,
      );

      expect(
        formatBaseValue(word, NumberBase.dec),
        '9,223,372,036,854,775,807',
      );
    });
  });
}
