import 'package:flutter/foundation.dart';

import '../../../core/input/calc_key.dart';
import '../widgets/calc_key_button.dart';
import '../widgets/keypad.dart';

/// The Basic 4×5 spec from SPEC §1.2 and `01-basic.html`:
/// `C ⌫ % ÷ / 7 8 9 × / 4 5 6 − / 1 2 3 + / ± 0 . =`.
///
/// Every entry sends its [CalcKey] to [onKey], so the page stays free of key
/// behaviour and the same spec can be tested without a controller.
List<KeypadEntry> basicKeys(ValueChanged<CalcKey> onKey) {
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

  return <KeypadEntry>[
    entry('C', CalcKey.clear, CalcKeyKind.function, semanticLabel: 'Clear'),
    entry(
      '⌫',
      CalcKey.backspace,
      CalcKeyKind.function,
      semanticLabel: 'Backspace',
      // SPEC §1.2: long-press ⌫ clears all.
      onLongPress: () => onKey(CalcKey.clear),
    ),
    entry('%', CalcKey.percent, CalcKeyKind.function, semanticLabel: 'Percent'),
    entry('÷', CalcKey.divide, CalcKeyKind.operator, semanticLabel: 'Divide'),

    entry('7', CalcKey.digit7, CalcKeyKind.number),
    entry('8', CalcKey.digit8, CalcKeyKind.number),
    entry('9', CalcKey.digit9, CalcKeyKind.number),
    entry(
      '×',
      CalcKey.multiply,
      CalcKeyKind.operator,
      semanticLabel: 'Multiply',
    ),

    entry('4', CalcKey.digit4, CalcKeyKind.number),
    entry('5', CalcKey.digit5, CalcKeyKind.number),
    entry('6', CalcKey.digit6, CalcKeyKind.number),
    entry(
      '−',
      CalcKey.subtract,
      CalcKeyKind.operator,
      semanticLabel: 'Subtract',
    ),

    entry('1', CalcKey.digit1, CalcKeyKind.number),
    entry('2', CalcKey.digit2, CalcKeyKind.number),
    entry('3', CalcKey.digit3, CalcKeyKind.number),
    entry('+', CalcKey.add, CalcKeyKind.operator, semanticLabel: 'Add'),

    entry(
      '±',
      CalcKey.toggleSign,
      CalcKeyKind.function,
      semanticLabel: 'Toggle sign',
    ),
    entry('0', CalcKey.digit0, CalcKeyKind.number),
    entry(
      '.',
      CalcKey.decimalPoint,
      CalcKeyKind.number,
      semanticLabel: 'Decimal point',
    ),
    entry('=', CalcKey.equals, CalcKeyKind.equals, semanticLabel: 'Equals'),
  ];
}
