import 'package:flutter/foundation.dart';

import '../../../core/input/calc_key.dart';
import '../widgets/calc_key_button.dart';
import '../widgets/keypad.dart';

/// The Scientific 5×7 spec from SPEC §1.3 and `02-scientific.html`:
/// `2nd sin cos tan π / x² xʸ √x ln log / ( ) n! 1/x e /
///  7 8 9 C ⌫ / 4 5 6 × ÷ / 1 2 3 + − / ± 0 . Ans =`.
///
/// With [second] on, the eight alternate labels replace their keys and the
/// `2nd` key is highlighted. Every entry still sends the base [CalcKey]; the
/// controller swaps it for the alternate function, inserts it, then turns
/// `2nd` off (BUSINESS_LOGIC §5).
List<KeypadEntry> scientificKeys({
  required ValueChanged<CalcKey> onKey,
  required bool second,
  required VoidCallback onSecond,
}) {
  KeypadEntry entry(
    String label,
    CalcKey key,
    CalcKeyKind kind, {
    String? semanticLabel,
    VoidCallback? onLongPress,
  }) => KeypadEntry(
    label: label,
    kind: kind,
    semanticLabel: semanticLabel,
    onTap: () => onKey(key),
    onLongPress: onLongPress,
  );

  String label(String normal, String alternate) =>
      second ? alternate : normal;

  return <KeypadEntry>[
    KeypadEntry(
      label: '2nd',
      kind: second ? CalcKeyKind.active : CalcKeyKind.function,
      semanticLabel: 'Second functions',
      onTap: onSecond,
    ),
    entry(
      label('sin', 'sin⁻¹'),
      CalcKey.sin,
      CalcKeyKind.function,
      semanticLabel: second ? 'Inverse sine' : 'Sine',
    ),
    entry(
      label('cos', 'cos⁻¹'),
      CalcKey.cos,
      CalcKeyKind.function,
      semanticLabel: second ? 'Inverse cosine' : 'Cosine',
    ),
    entry(
      label('tan', 'tan⁻¹'),
      CalcKey.tan,
      CalcKeyKind.function,
      semanticLabel: second ? 'Inverse tangent' : 'Tangent',
    ),
    entry('π', CalcKey.pi, CalcKeyKind.function, semanticLabel: 'Pi'),

    entry(
      label('x²', 'x³'),
      CalcKey.square,
      CalcKeyKind.function,
      semanticLabel: second ? 'Cube' : 'Square',
    ),
    entry(
      label('xʸ', 'ʸ√x'),
      CalcKey.power,
      CalcKeyKind.function,
      semanticLabel: second ? 'Y-th root' : 'Power',
    ),
    entry(
      label('√x', '∛x'),
      CalcKey.sqrt,
      CalcKeyKind.function,
      semanticLabel: second ? 'Cube root' : 'Square root',
    ),
    entry(
      label('ln', 'eˣ'),
      CalcKey.ln,
      CalcKeyKind.function,
      semanticLabel: second ? 'e to the x' : 'Natural log',
    ),
    entry(
      label('log', '10ˣ'),
      CalcKey.log,
      CalcKeyKind.function,
      semanticLabel: second ? '10 to the x' : 'Log base 10',
    ),

    entry(
      '(',
      CalcKey.leftParen,
      CalcKeyKind.function,
      semanticLabel: 'Open bracket',
    ),
    entry(
      ')',
      CalcKey.rightParen,
      CalcKeyKind.function,
      semanticLabel: 'Close bracket',
    ),
    entry(
      'n!',
      CalcKey.factorial,
      CalcKeyKind.function,
      semanticLabel: 'Factorial',
    ),
    entry(
      '1/x',
      CalcKey.reciprocal,
      CalcKeyKind.function,
      semanticLabel: 'Reciprocal',
    ),
    entry('e', CalcKey.e, CalcKeyKind.function, semanticLabel: 'Euler number'),

    entry('7', CalcKey.digit7, CalcKeyKind.number),
    entry('8', CalcKey.digit8, CalcKeyKind.number),
    entry('9', CalcKey.digit9, CalcKeyKind.number),
    entry('C', CalcKey.clear, CalcKeyKind.functionStrong, semanticLabel: 'Clear'),
    entry(
      '⌫',
      CalcKey.backspace,
      CalcKeyKind.functionStrong,
      semanticLabel: 'Backspace',
      // SPEC §1.3 keeps Basic's long-press ⌫ = clear.
      onLongPress: () => onKey(CalcKey.clear),
    ),

    entry('4', CalcKey.digit4, CalcKeyKind.number),
    entry('5', CalcKey.digit5, CalcKeyKind.number),
    entry('6', CalcKey.digit6, CalcKeyKind.number),
    entry(
      '×',
      CalcKey.multiply,
      CalcKeyKind.operator,
      semanticLabel: 'Multiply',
    ),
    entry('÷', CalcKey.divide, CalcKeyKind.operator, semanticLabel: 'Divide'),

    entry('1', CalcKey.digit1, CalcKeyKind.number),
    entry('2', CalcKey.digit2, CalcKeyKind.number),
    entry('3', CalcKey.digit3, CalcKeyKind.number),
    entry('+', CalcKey.add, CalcKeyKind.operator, semanticLabel: 'Add'),
    entry(
      '−',
      CalcKey.subtract,
      CalcKeyKind.operator,
      semanticLabel: 'Subtract',
    ),

    entry(
      '±',
      CalcKey.toggleSign,
      CalcKeyKind.functionStrong,
      semanticLabel: 'Toggle sign',
    ),
    entry('0', CalcKey.digit0, CalcKeyKind.number),
    entry(
      '.',
      CalcKey.decimalPoint,
      CalcKeyKind.number,
      semanticLabel: 'Decimal point',
    ),
    entry('Ans', CalcKey.ans, CalcKeyKind.function, semanticLabel: 'Last answer'),
    entry('=', CalcKey.equals, CalcKeyKind.equals, semanticLabel: 'Equals'),
  ];
}
