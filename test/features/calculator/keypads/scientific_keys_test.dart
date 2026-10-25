import 'package:calculator/core/input/calc_key.dart';
import 'package:calculator/features/calculator/keypads/scientific_keys.dart';
import 'package:calculator/features/calculator/widgets/calc_key_button.dart';
import 'package:calculator/features/calculator/widgets/keypad.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<KeypadEntry> spec({
    bool second = false,
    void Function(CalcKey)? onKey,
    void Function()? onSecond,
  }) => scientificKeys(
    onKey: onKey ?? (CalcKey key) {},
    second: second,
    onSecond: onSecond ?? () {},
  );

  test('lists the 35 Scientific keys in the design order', () {
    final List<KeypadEntry> keys = spec();

    expect(keys, hasLength(35));
    expect(keys.map((KeypadEntry entry) => entry.label).toList(), <String>[
      '2nd',
      'sin',
      'cos',
      'tan',
      'π',
      'x²',
      'xʸ',
      '√x',
      'ln',
      'log',
      '(',
      ')',
      'n!',
      '1/x',
      'e',
      '7',
      '8',
      '9',
      'C',
      '⌫',
      '4',
      '5',
      '6',
      '×',
      '÷',
      '1',
      '2',
      '3',
      '+',
      '−',
      '±',
      '0',
      '.',
      'Ans',
      '=',
    ]);
  });

  test('2nd swaps the eight alternate labels', () {
    final List<KeypadEntry> keys = spec(second: true);

    expect(keys[1].label, 'sin⁻¹');
    expect(keys[2].label, 'cos⁻¹');
    expect(keys[3].label, 'tan⁻¹');
    expect(keys[5].label, 'x³');
    expect(keys[6].label, 'ʸ√x');
    expect(keys[7].label, '∛x');
    expect(keys[8].label, 'eˣ');
    expect(keys[9].label, '10ˣ');
    // Keys without an alternate keep their label.
    expect(keys[0].label, '2nd');
    expect(keys[4].label, 'π');
    expect(keys[13].label, '1/x');
  });

  test('highlighting the 2nd key marks the alternate set as active', () {
    expect(spec()[0].kind, CalcKeyKind.function);
    expect(spec(second: true)[0].kind, CalcKeyKind.active);
  });

  test('uses the sci, fn, number, operator and equals kinds', () {
    final List<KeypadEntry> keys = spec();

    for (int index in <int>[
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 33, //
    ]) {
      expect(keys[index].kind, CalcKeyKind.function, reason: keys[index].label);
    }
    for (int index in <int>[18, 19, 30]) {
      expect(
        keys[index].kind,
        CalcKeyKind.functionStrong,
        reason: keys[index].label,
      );
    }
    for (int index in <int>[15, 16, 17, 20, 21, 22, 25, 26, 27, 31, 32]) {
      expect(keys[index].kind, CalcKeyKind.number, reason: keys[index].label);
    }
    for (int index in <int>[23, 24, 28, 29]) {
      expect(keys[index].kind, CalcKeyKind.operator, reason: keys[index].label);
    }
    expect(keys[34].kind, CalcKeyKind.equals);
  });

  test('sends the base CalcKey when a key is tapped', () {
    final List<CalcKey> pressed = <CalcKey>[];
    final List<KeypadEntry> keys = spec(onKey: pressed.add);

    // 2nd is a UI toggle, not a buffer key.
    for (int index = 1; index < keys.length; index++) {
      keys[index].onTap!();
    }

    expect(pressed, <CalcKey>[
      CalcKey.sin,
      CalcKey.cos,
      CalcKey.tan,
      CalcKey.pi,
      CalcKey.square,
      CalcKey.power,
      CalcKey.sqrt,
      CalcKey.ln,
      CalcKey.log,
      CalcKey.leftParen,
      CalcKey.rightParen,
      CalcKey.factorial,
      CalcKey.reciprocal,
      CalcKey.e,
      CalcKey.digit7,
      CalcKey.digit8,
      CalcKey.digit9,
      CalcKey.clear,
      CalcKey.backspace,
      CalcKey.digit4,
      CalcKey.digit5,
      CalcKey.digit6,
      CalcKey.multiply,
      CalcKey.divide,
      CalcKey.digit1,
      CalcKey.digit2,
      CalcKey.digit3,
      CalcKey.add,
      CalcKey.subtract,
      CalcKey.toggleSign,
      CalcKey.digit0,
      CalcKey.decimalPoint,
      CalcKey.ans,
      CalcKey.equals,
    ]);
  });

  test('the 2nd key toggles the alternate set', () {
    int toggles = 0;
    final List<KeypadEntry> keys = spec(onSecond: () => toggles++);

    keys[0].onTap!();

    expect(toggles, 1);
  });

  test('names glyph keys for screen readers, following the alternate set', () {
    final List<KeypadEntry> keys = spec();
    final List<KeypadEntry> second = spec(second: true);

    expect(keys[0].semanticLabel, 'Second functions');
    expect(keys[1].semanticLabel, 'Sine');
    expect(keys[2].semanticLabel, 'Cosine');
    expect(keys[3].semanticLabel, 'Tangent');
    expect(keys[4].semanticLabel, 'Pi');
    expect(keys[5].semanticLabel, 'Square');
    expect(keys[6].semanticLabel, 'Power');
    expect(keys[7].semanticLabel, 'Square root');
    expect(keys[8].semanticLabel, 'Natural log');
    expect(keys[9].semanticLabel, 'Log base 10');
    expect(keys[10].semanticLabel, 'Open bracket');
    expect(keys[11].semanticLabel, 'Close bracket');
    expect(keys[12].semanticLabel, 'Factorial');
    expect(keys[13].semanticLabel, 'Reciprocal');
    expect(keys[14].semanticLabel, 'Euler number');
    expect(keys[18].semanticLabel, 'Clear');
    expect(keys[19].semanticLabel, 'Backspace');
    expect(keys[23].semanticLabel, 'Multiply');
    expect(keys[24].semanticLabel, 'Divide');
    expect(keys[28].semanticLabel, 'Add');
    expect(keys[29].semanticLabel, 'Subtract');
    expect(keys[30].semanticLabel, 'Toggle sign');
    expect(keys[32].semanticLabel, 'Decimal point');
    expect(keys[33].semanticLabel, 'Last answer');
    expect(keys[34].semanticLabel, 'Equals');

    expect(second[1].semanticLabel, 'Inverse sine');
    expect(second[2].semanticLabel, 'Inverse cosine');
    expect(second[3].semanticLabel, 'Inverse tangent');
    expect(second[5].semanticLabel, 'Cube');
    expect(second[6].semanticLabel, 'Y-th root');
    expect(second[7].semanticLabel, 'Cube root');
    expect(second[8].semanticLabel, 'e to the x');
    expect(second[9].semanticLabel, '10 to the x');

    // Digits are read as their label.
    expect(keys[15].semanticLabel, isNull);
  });

  test('long-pressing ⌫ clears the whole expression', () {
    final List<CalcKey> pressed = <CalcKey>[];
    final List<KeypadEntry> keys = spec(onKey: pressed.add);

    expect(keys[19].onLongPress, isNotNull);
    keys[19].onLongPress!();

    expect(pressed, <CalcKey>[CalcKey.clear]);
  });
}
