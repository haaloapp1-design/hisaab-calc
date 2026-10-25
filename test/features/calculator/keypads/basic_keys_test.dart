import 'package:calculator/core/input/calc_key.dart';
import 'package:calculator/features/calculator/keypads/basic_keys.dart';
import 'package:calculator/features/calculator/widgets/calc_key_button.dart';
import 'package:calculator/features/calculator/widgets/keypad.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lists the 20 Basic keys in the design order', () {
    final List<KeypadEntry> keys = basicKeys((CalcKey key) {});

    expect(keys, hasLength(20));
    expect(keys.map((KeypadEntry entry) => entry.label).toList(), <String>[
      'C',
      '⌫',
      '%',
      '÷',
      '7',
      '8',
      '9',
      '×',
      '4',
      '5',
      '6',
      '−',
      '1',
      '2',
      '3',
      '+',
      '±',
      '0',
      '.',
      '=',
    ]);
  });

  test('uses the function, operator, number and equals kinds', () {
    final List<KeypadEntry> keys = basicKeys((CalcKey key) {});

    for (int index in <int>[0, 1, 2, 16]) {
      expect(keys[index].kind, CalcKeyKind.function, reason: keys[index].label);
    }
    for (int index in <int>[3, 7, 11, 15]) {
      expect(keys[index].kind, CalcKeyKind.operator, reason: keys[index].label);
    }
    for (int index in <int>[4, 5, 6, 8, 9, 10, 12, 13, 14, 17, 18]) {
      expect(keys[index].kind, CalcKeyKind.number, reason: keys[index].label);
    }
    expect(keys[19].kind, CalcKeyKind.equals);
  });

  test('sends the matching CalcKey when a key is tapped', () {
    final List<CalcKey> pressed = <CalcKey>[];
    final List<KeypadEntry> keys = basicKeys(pressed.add);

    for (final KeypadEntry entry in keys) {
      entry.onTap!();
    }

    expect(pressed, <CalcKey>[
      CalcKey.clear,
      CalcKey.backspace,
      CalcKey.percent,
      CalcKey.divide,
      CalcKey.digit7,
      CalcKey.digit8,
      CalcKey.digit9,
      CalcKey.multiply,
      CalcKey.digit4,
      CalcKey.digit5,
      CalcKey.digit6,
      CalcKey.subtract,
      CalcKey.digit1,
      CalcKey.digit2,
      CalcKey.digit3,
      CalcKey.add,
      CalcKey.toggleSign,
      CalcKey.digit0,
      CalcKey.decimalPoint,
      CalcKey.equals,
    ]);
  });

  test('names glyph keys for screen readers', () {
    final List<KeypadEntry> keys = basicKeys((CalcKey key) {});

    expect(keys[0].semanticLabel, 'Clear');
    expect(keys[1].semanticLabel, 'Backspace');
    expect(keys[2].semanticLabel, 'Percent');
    expect(keys[3].semanticLabel, 'Divide');
    expect(keys[7].semanticLabel, 'Multiply');
    expect(keys[11].semanticLabel, 'Subtract');
    expect(keys[15].semanticLabel, 'Add');
    expect(keys[16].semanticLabel, 'Toggle sign');
    expect(keys[18].semanticLabel, 'Decimal point');
    expect(keys[19].semanticLabel, 'Equals');

    // Digits are read as their label.
    expect(keys[4].semanticLabel, isNull);
    expect(keys[17].semanticLabel, isNull);
  });

  test('long-pressing ⌫ clears the whole expression', () {
    final List<CalcKey> pressed = <CalcKey>[];
    final List<KeypadEntry> keys = basicKeys(pressed.add);

    expect(keys[1].onLongPress, isNotNull);
    keys[1].onLongPress!();

    expect(pressed, <CalcKey>[CalcKey.clear]);
  });
}
