/// The word widths programmer mode offers (BUSINESS_LOGIC §11, SPEC §1.4).
enum WordSize {
  bits8(8),
  bits16(16),
  bits32(32),
  bits64(64);

  const WordSize(this.bits);

  /// SPEC §1.4: 32-bit is the default.
  static const WordSize standard = bits32;

  /// The width in bits.
  final int bits;

  /// `mask = (1 << wordSize) − 1`, the bits a value keeps.
  BigInt get mask => (BigInt.one << bits) - BigInt.one;

  /// `1 << wordSize`: adding it to a negative signed value gives its raw
  /// bit pattern (§11 two's complement).
  BigInt get modulus => BigInt.one << bits;

  /// `1 << (wordSize − 1)`: set means the signed view is negative.
  BigInt get signBit => BigInt.one << (bits - 1);

  /// The lowest signed value this width holds.
  BigInt get minSigned => -signBit;

  /// The highest signed value this width holds.
  BigInt get maxSigned => signBit - BigInt.one;

  /// The chip label, e.g. `32-bit`.
  String get label => '$bits-bit';
}

/// A fixed-width integer: the raw unsigned bit pattern plus its word size
/// (BUSINESS_LOGIC §11).
///
/// The raw pattern is canonical, so HEX/OCT/BIN print the bits the CPU would
/// hold; [signed] is the DEC view and the value every programmer operation
/// works on. Constructing a [Word] masks the input, which is the §11
/// "every result is re-masked" rule in one place.
final class Word {
  /// Stores `value & mask` as the raw bit pattern in [size] bits.
  Word(BigInt value, {this.size = WordSize.standard}) : raw = value & size.mask;

  /// Zero in [size].
  Word.zero({WordSize size = WordSize.standard})
    : this(BigInt.zero, size: size);

  /// `u = value & mask`, the unsigned pattern HEX/OCT/BIN display.
  final BigInt raw;

  /// The word width this value lives in.
  final WordSize size;

  /// The DEC value: a set top bit means `raw − (1 << wordSize)` (§11).
  BigInt get signed => raw >= size.signBit ? raw - size.modulus : raw;

  /// Whether the signed view is negative.
  bool get isNegative => signed.isNegative;

  /// The same value re-masked into [size] (§11: changing the word size may
  /// truncate, and keeps the sign, so `−1` stays `−1` in every width).
  Word withSize(WordSize size) => Word(signed, size: size);

  /// The same width with a new value, re-masked (§11 wrap-around).
  Word withValue(BigInt value) => Word(value, size: size);

  // Operations on the signed values, every result re-masked (§11).

  /// `a + b`, wrapping two's complement.
  Word add(Word other) => _withOther(other, signed + other.signed);

  /// `a − b`, wrapping two's complement.
  Word subtract(Word other) => _withOther(other, signed - other.signed);

  /// `a × b`, wrapping two's complement.
  Word multiply(Word other) => _withOther(other, signed * other.signed);

  /// `a ÷ b`, truncated toward zero. The caller rejects `b = 0`.
  Word divide(Word other) => _withOther(other, signed ~/ other.signed);

  /// `a mod b`, remainder with the sign of the dividend (unlike `%`).
  Word modulo(Word other) => _withOther(other, signed.remainder(other.signed));

  /// `a AND b`.
  Word bitAnd(Word other) => _withOther(other, signed & other.signed);

  /// `a OR b`.
  Word bitOr(Word other) => _withOther(other, signed | other.signed);

  /// `a XOR b`.
  Word bitXor(Word other) => _withOther(other, signed ^ other.signed);

  /// `NOT a = ~a & mask`.
  Word bitNot() => Word(~signed, size: size);

  /// `NAND = ~(a & b) & mask`.
  Word nand(Word other) => bitAnd(other).bitNot();

  /// `a << n` then mask; every bit is gone once `n` reaches the word size.
  Word shiftLeft(BigInt count) {
    _checkCount(count);
    if (count >= BigInt.from(size.bits)) {
      return Word.zero(size: size);
    }
    return withValue(signed << count.toInt());
  }

  /// `a >> n`, arithmetic (keeps the sign); a large `n` leaves only the sign.
  Word shiftRight(BigInt count) {
    _checkCount(count);
    if (count >= BigInt.from(size.bits)) {
      return Word(
        signed.isNegative ? BigInt.from(-1) : BigInt.zero,
        size: size,
      );
    }
    return withValue(signed >> count.toInt());
  }

  /// `±`: the same value with the opposite sign, re-masked.
  Word negate() => withValue(-signed);

  /// Re-masks [value] in this width after checking [other]'s width.
  Word _withOther(Word other, BigInt value) {
    assert(other.size == size, 'both operands must use the same word size');
    return withValue(value);
  }

  /// Shift distances are non-negative; the parser reports a domain error.
  static void _checkCount(BigInt count) {
    if (count.isNegative) {
      throw ArgumentError.value(count, 'count', 'must not be negative');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Word && other.size == size && other.raw == raw;

  @override
  int get hashCode => Object.hash(size, raw);

  @override
  String toString() => 'Word($signed, ${size.label})';
}
