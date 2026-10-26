import 'package:flutter/foundation.dart';

import '../../../core/programmer/base_format.dart';
import '../../../core/programmer/prog_key.dart';
import '../widgets/calc_key_button.dart';
import '../widgets/keypad.dart';

/// The Programmer 5×7 spec from SPEC §1.4 and `03-programmer.html`:
/// `AND OR XOR NOT NAND / A << >> AC ⌫ / B ( ) mod ÷ / C 7 8 9 × /
///  D 4 5 6 − / E 1 2 3 + / F ± 0 . =`.
///
/// Digits the active [base] cannot read are [CalcKeyKind.disabled] (SPEC §1.4:
/// `8` and `9` in OCT, `2`–`9` in BIN); `.` is always disabled because
/// programmer mode is integers only.
List<KeypadEntry> programmerKeys({
  required ValueChanged<ProgKey> onKey,
  required NumberBase base,
}) {
  KeypadEntry entry(
    String label,
    ProgKey key,
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

  KeypadEntry digit(String label, ProgKey key) {
    final bool enabled = int.parse(label, radix: 16) < base.radix;
    return KeypadEntry(
      label: label,
      kind: enabled ? CalcKeyKind.number : CalcKeyKind.disabled,
      semanticLabel: enabled ? null : '$label (not available in this base)',
      onTap: enabled ? () => onKey(key) : null,
    );
  }

  return <KeypadEntry>[
    entry(
      'AND',
      ProgKey.and,
      CalcKeyKind.function,
      semanticLabel: 'Bitwise AND',
    ),
    entry('OR', ProgKey.or, CalcKeyKind.function, semanticLabel: 'Bitwise OR'),
    entry(
      'XOR',
      ProgKey.xor,
      CalcKeyKind.function,
      semanticLabel: 'Bitwise XOR',
    ),
    entry(
      'NOT',
      ProgKey.not,
      CalcKeyKind.function,
      semanticLabel: 'Bitwise NOT',
    ),
    entry(
      'NAND',
      ProgKey.nand,
      CalcKeyKind.function,
      semanticLabel: 'Bitwise NAND',
    ),

    digit('A', ProgKey.digitA),
    entry(
      '<<',
      ProgKey.shiftLeft,
      CalcKeyKind.function,
      semanticLabel: 'Shift left',
    ),
    entry(
      '>>',
      ProgKey.shiftRight,
      CalcKeyKind.function,
      semanticLabel: 'Shift right',
    ),
    entry(
      'AC',
      ProgKey.clear,
      CalcKeyKind.functionStrong,
      semanticLabel: 'Clear all',
    ),
    entry(
      '⌫',
      ProgKey.backspace,
      CalcKeyKind.functionStrong,
      semanticLabel: 'Backspace',
      // SPEC §1.2 keeps Basic's long-press ⌫ = clear.
      onLongPress: () => onKey(ProgKey.clear),
    ),

    digit('B', ProgKey.digitB),
    entry(
      '(',
      ProgKey.leftParen,
      CalcKeyKind.function,
      semanticLabel: 'Open bracket',
    ),
    entry(
      ')',
      ProgKey.rightParen,
      CalcKeyKind.function,
      semanticLabel: 'Close bracket',
    ),
    entry('mod', ProgKey.mod, CalcKeyKind.function, semanticLabel: 'Modulo'),
    entry('÷', ProgKey.divide, CalcKeyKind.operator, semanticLabel: 'Divide'),

    digit('C', ProgKey.digitC),
    digit('7', ProgKey.digit7),
    digit('8', ProgKey.digit8),
    digit('9', ProgKey.digit9),
    entry(
      '×',
      ProgKey.multiply,
      CalcKeyKind.operator,
      semanticLabel: 'Multiply',
    ),

    digit('D', ProgKey.digitD),
    digit('4', ProgKey.digit4),
    digit('5', ProgKey.digit5),
    digit('6', ProgKey.digit6),
    entry(
      '−',
      ProgKey.subtract,
      CalcKeyKind.operator,
      semanticLabel: 'Subtract',
    ),

    digit('E', ProgKey.digitE),
    digit('1', ProgKey.digit1),
    digit('2', ProgKey.digit2),
    digit('3', ProgKey.digit3),
    entry('+', ProgKey.add, CalcKeyKind.operator, semanticLabel: 'Add'),

    digit('F', ProgKey.digitF),
    entry(
      '±',
      ProgKey.toggleSign,
      CalcKeyKind.functionStrong,
      semanticLabel: 'Toggle sign',
    ),
    digit('0', ProgKey.digit0),
    KeypadEntry(
      label: '.',
      kind: CalcKeyKind.disabled,
      semanticLabel: 'Decimal point (not available in programmer mode)',
    ),
    entry('=', ProgKey.equals, CalcKeyKind.equals, semanticLabel: 'Equals'),
  ];
}
