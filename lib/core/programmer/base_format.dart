import 'word.dart';

/// The four bases programmer mode shows, in the row order of SPEC §1.4.
enum NumberBase {
  hex(16, 'HEX'),
  dec(10, 'DEC'),
  oct(8, 'OCT'),
  bin(2, 'BIN');

  const NumberBase(this.radix, this.label);

  /// The base's radix, used when the current value is read or typed in it.
  final int radix;

  /// The row name, e.g. `HEX`.
  final String label;
}

/// The display string for [word] in [base] (BUSINESS_LOGIC §11).
///
/// HEX/OCT/BIN show the unsigned bit pattern with no fixed width, like the
/// design (`2021` → `7E5`, `3745`, `0111 1110 0101`); DEC shows the signed
/// value with the app's typographic minus. BIN is padded to a multiple of four
/// bits and grouped by four.
String formatInBase(Word word, NumberBase base) => switch (base) {
  NumberBase.hex => word.raw.toRadixString(16).toUpperCase(),
  NumberBase.dec => _signedDecimal(word.signed),
  NumberBase.oct => word.raw.toRadixString(8),
  NumberBase.bin => _groupBinary(word.raw.toRadixString(2)),
};

/// The four row strings, keyed by base in HEX/DEC/OCT/BIN order.
Map<NumberBase, String> formatBases(Word word) => <NumberBase, String>{
  for (final NumberBase base in NumberBase.values)
    base: formatInBase(word, base),
};

/// §11: pad to a multiple of 4 bits, then group by 4 (`0111 1110 0101`).
String _groupBinary(String digits) {
  final int padding = (4 - digits.length % 4) % 4;
  final String padded = '${'0' * padding}$digits';
  final StringBuffer buffer = StringBuffer();
  for (int index = 0; index < padded.length; index += 4) {
    if (index > 0) {
      buffer.write(' ');
    }
    buffer.write(padded.substring(index, index + 4));
  }
  return buffer.toString();
}

/// `−` for the display, like `formatNumber` (§8.5 uses ASCII for copying).
String _signedDecimal(BigInt value) =>
    value.isNegative ? '−${value.abs()}' : value.toString();
