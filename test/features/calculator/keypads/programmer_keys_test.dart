import 'package:calculator/core/programmer/base_format.dart';
import 'package:calculator/core/programmer/prog_key.dart';
import 'package:calculator/features/calculator/keypads/programmer_keys.dart';
import 'package:calculator/features/calculator/widgets/calc_key_button.dart';
import 'package:calculator/features/calculator/widgets/keypad.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<KeypadEntry> spec({
    NumberBase base = NumberBase.dec,
    void Function(ProgKey)? onKey,
  }) => programmerKeys(onKey: onKey ?? (ProgKey key) {}, base: base);

  KeypadEntry byLabel(List<KeypadEntry> keys, String label) =>
      keys.firstWhere((KeypadEntry entry) => entry.label == label);

  test('lists the 35 Programmer keys in the design order', () {
    final List<KeypadEntry> keys = spec();

    expect(keys, hasLength(35));
    expect(keys.map((KeypadEntry entry) => entry.label).toList(), <String>[
      'AND',
      'OR',
      'XOR',
      'NOT',
      'NAND',
      'A',
      '<<',
      '>>',
      'AC',
      '⌫',
      'B',
      '(',
      ')',
      'mod',
      '÷',
      'C',
      '7',
      '8',
      '9',
      '×',
      'D',
      '4',
      '5',
      '6',
      '−',
      'E',
      '1',
      '2',
      '3',
      '+',
      'F',
      '±',
      '0',
      '.',
      '=',
    ]);
  });

  test('uses the sci, fn, number, operator and equals kinds', () {
    final List<KeypadEntry> keys = spec(base: NumberBase.hex);

    for (final String label in <String>[
      'AND',
      'OR',
      'XOR',
      'NOT',
      'NAND',
      '<<',
      '>>',
      '(',
      ')',
      'mod',
    ]) {
      expect(byLabel(keys, label).kind, CalcKeyKind.function, reason: label);
    }
    for (final String label in <String>['AC', '⌫', '±']) {
      expect(
        byLabel(keys, label).kind,
        CalcKeyKind.functionStrong,
        reason: label,
      );
    }
    for (final String label in <String>[
      '0',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
    ]) {
      expect(byLabel(keys, label).kind, CalcKeyKind.number, reason: label);
    }
    for (final String label in <String>['÷', '×', '−', '+']) {
      expect(byLabel(keys, label).kind, CalcKeyKind.operator, reason: label);
    }
    expect(byLabel(keys, '=').kind, CalcKeyKind.equals);
  });

  test('disables the digits the base cannot read', () {
    final List<KeypadEntry> dec = spec(base: NumberBase.dec);
    final List<KeypadEntry> oct = spec(base: NumberBase.oct);
    final List<KeypadEntry> bin = spec(base: NumberBase.bin);

    // DEC reads 0–9 and not A–F.
    for (final String label in <String>['0', '5', '9']) {
      expect(byLabel(dec, label).kind, CalcKeyKind.number, reason: label);
    }
    for (final String label in <String>['A', 'B', 'C', 'D', 'E', 'F']) {
      expect(byLabel(dec, label).kind, CalcKeyKind.disabled, reason: label);
    }

    // OCT reads 0–7 only.
    expect(byLabel(oct, '7').kind, CalcKeyKind.number);
    for (final String label in <String>[
      '8',
      '9',
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
    ]) {
      expect(byLabel(oct, label).kind, CalcKeyKind.disabled, reason: label);
    }

    // BIN reads 0 and 1 only.
    expect(byLabel(bin, '0').kind, CalcKeyKind.number);
    expect(byLabel(bin, '1').kind, CalcKeyKind.number);
    for (final String label in <String>[
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
    ]) {
      expect(byLabel(bin, label).kind, CalcKeyKind.disabled, reason: label);
    }
  });

  test('the decimal point is always disabled', () {
    for (final NumberBase base in NumberBase.values) {
      final KeypadEntry point = byLabel(spec(base: base), '.');
      expect(point.kind, CalcKeyKind.disabled, reason: base.label);
      expect(point.onTap, isNull);
    }
  });

  test('a disabled digit has no tap action', () {
    final KeypadEntry a = byLabel(spec(base: NumberBase.dec), 'A');

    expect(a.onTap, isNull);
    expect(a.semanticLabel, 'A (not available in this base)');
  });

  test('sends the ProgKey for each key', () {
    final List<ProgKey> pressed = <ProgKey>[];
    final List<KeypadEntry> keys = spec(
      base: NumberBase.hex,
      onKey: pressed.add,
    );

    for (final KeypadEntry entry in keys) {
      entry.onTap?.call();
    }

    expect(pressed, <ProgKey>[
      ProgKey.and,
      ProgKey.or,
      ProgKey.xor,
      ProgKey.not,
      ProgKey.nand,
      ProgKey.digitA,
      ProgKey.shiftLeft,
      ProgKey.shiftRight,
      ProgKey.clear,
      ProgKey.backspace,
      ProgKey.digitB,
      ProgKey.leftParen,
      ProgKey.rightParen,
      ProgKey.mod,
      ProgKey.divide,
      ProgKey.digitC,
      ProgKey.digit7,
      ProgKey.digit8,
      ProgKey.digit9,
      ProgKey.multiply,
      ProgKey.digitD,
      ProgKey.digit4,
      ProgKey.digit5,
      ProgKey.digit6,
      ProgKey.subtract,
      ProgKey.digitE,
      ProgKey.digit1,
      ProgKey.digit2,
      ProgKey.digit3,
      ProgKey.add,
      ProgKey.digitF,
      ProgKey.toggleSign,
      ProgKey.digit0,
      ProgKey.equals,
    ]);
  });

  test('long-pressing ⌫ clears the whole expression', () {
    final List<ProgKey> pressed = <ProgKey>[];
    final KeypadEntry backspace = byLabel(spec(onKey: pressed.add), '⌫');

    expect(backspace.onLongPress, isNotNull);
    backspace.onLongPress!();

    expect(pressed, <ProgKey>[ProgKey.clear]);
  });

  test('names glyph and keyword keys for screen readers', () {
    final List<KeypadEntry> keys = spec(base: NumberBase.hex);

    expect(byLabel(keys, 'AND').semanticLabel, 'Bitwise AND');
    expect(byLabel(keys, 'OR').semanticLabel, 'Bitwise OR');
    expect(byLabel(keys, 'XOR').semanticLabel, 'Bitwise XOR');
    expect(byLabel(keys, 'NOT').semanticLabel, 'Bitwise NOT');
    expect(byLabel(keys, 'NAND').semanticLabel, 'Bitwise NAND');
    expect(byLabel(keys, '<<').semanticLabel, 'Shift left');
    expect(byLabel(keys, '>>').semanticLabel, 'Shift right');
    expect(byLabel(keys, 'AC').semanticLabel, 'Clear all');
    expect(byLabel(keys, '⌫').semanticLabel, 'Backspace');
    expect(byLabel(keys, '(').semanticLabel, 'Open bracket');
    expect(byLabel(keys, ')').semanticLabel, 'Close bracket');
    expect(byLabel(keys, 'mod').semanticLabel, 'Modulo');
    expect(byLabel(keys, '÷').semanticLabel, 'Divide');
    expect(byLabel(keys, '×').semanticLabel, 'Multiply');
    expect(byLabel(keys, '−').semanticLabel, 'Subtract');
    expect(byLabel(keys, '+').semanticLabel, 'Add');
    expect(byLabel(keys, '±').semanticLabel, 'Toggle sign');
    expect(byLabel(keys, '=').semanticLabel, 'Equals');
    expect(byLabel(keys, '.').semanticLabel, isNotNull);
    // Digits are read as their label.
    expect(byLabel(keys, '7').semanticLabel, isNull);
  });
}
