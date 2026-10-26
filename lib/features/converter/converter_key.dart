/// The 16 keys of the unit converter (screen 07).
///
/// The order is the design's 4×4 grid: `7 8 9 ⌫ / 4 5 6 C / 1 2 3 ± /
/// 00 0 . Copy`. Number keys use the light number style, function keys the
/// tinted blue style.
enum ConverterKey {
  seven('7'),
  eight('8'),
  nine('9'),
  backspace('⌫', isFunction: true),
  four('4'),
  five('5'),
  six('6'),
  clear('C', isFunction: true),
  one('1'),
  two('2'),
  three('3'),
  toggleSign('±', isFunction: true),
  doubleZero('00'),
  zero('0'),
  dot('.'),
  copy('Copy', isFunction: true);

  const ConverterKey(this.label, {this.isFunction = false});

  /// What the key shows.
  final String label;

  /// Function keys are blue on the tinted background.
  final bool isFunction;

  /// The screen-reader name when the glyph is not readable (`⌫`, `±`, `.`).
  String get semanticLabel => switch (this) {
    ConverterKey.backspace => 'Backspace',
    ConverterKey.clear => 'Clear',
    ConverterKey.toggleSign => 'Toggle sign',
    ConverterKey.doubleZero => 'Double zero',
    ConverterKey.dot => 'Decimal point',
    ConverterKey.copy => 'Copy result',
    _ => label,
  };
}
