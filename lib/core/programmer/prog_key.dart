/// Every key the Programmer keypad can emit (SPEC §1.4).
///
/// Programmer mode has its own key set (`AND`, `NAND`, `<<`, hex digits) that
/// the decimal [CalcKey] enum does not model, and its state is a typed source
/// string rather than an `InputBuffer`, so the keys live here.
enum ProgKey {
  digit0,
  digit1,
  digit2,
  digit3,
  digit4,
  digit5,
  digit6,
  digit7,
  digit8,
  digit9,
  digitA,
  digitB,
  digitC,
  digitD,
  digitE,
  digitF,

  and,
  or,
  xor,
  not,
  nand,

  shiftLeft,
  shiftRight,

  mod,
  add,
  subtract,
  multiply,
  divide,

  leftParen,
  rightParen,

  /// `±`
  toggleSign,

  /// `AC`
  clear,

  /// `⌫`
  backspace,

  /// `=`
  equals;

  /// The digit character this key types, or null for a non-digit key.
  String? get digit => switch (this) {
    ProgKey.digit0 => '0',
    ProgKey.digit1 => '1',
    ProgKey.digit2 => '2',
    ProgKey.digit3 => '3',
    ProgKey.digit4 => '4',
    ProgKey.digit5 => '5',
    ProgKey.digit6 => '6',
    ProgKey.digit7 => '7',
    ProgKey.digit8 => '8',
    ProgKey.digit9 => '9',
    ProgKey.digitA => 'A',
    ProgKey.digitB => 'B',
    ProgKey.digitC => 'C',
    ProgKey.digitD => 'D',
    ProgKey.digitE => 'E',
    ProgKey.digitF => 'F',
    _ => null,
  };

  /// The source spelling of a binary operator, or null.
  ///
  /// The glyphs match what `ProgEngine` reads (`AND`, `mod`, `×`, `÷`, `−`);
  /// [ProgKey.not] is a prefix and is inserted by `ProgSource.appendNot`.
  String? get operator => switch (this) {
    ProgKey.and => 'AND',
    ProgKey.or => 'OR',
    ProgKey.xor => 'XOR',
    ProgKey.nand => 'NAND',
    ProgKey.mod => 'mod',
    ProgKey.shiftLeft => '<<',
    ProgKey.shiftRight => '>>',
    ProgKey.add => '+',
    ProgKey.subtract => '−',
    ProgKey.multiply => '×',
    ProgKey.divide => '÷',
    _ => null,
  };
}
