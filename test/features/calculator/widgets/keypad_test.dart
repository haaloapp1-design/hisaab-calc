import 'package:calculator/features/calculator/widgets/calc_key_button.dart';
import 'package:calculator/features/calculator/widgets/keypad.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:calculator/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<KeypadEntry> basicSpec(List<String> taps) => <KeypadEntry>[
    KeypadEntry(
      label: 'C',
      kind: CalcKeyKind.function,
      semanticLabel: 'Clear',
      onTap: () => taps.add('C'),
    ),
    KeypadEntry(
      label: '⌫',
      kind: CalcKeyKind.function,
      semanticLabel: 'Backspace',
      onTap: () => taps.add('⌫'),
    ),
    KeypadEntry(
      label: '%',
      kind: CalcKeyKind.function,
      semanticLabel: 'Percent',
      onTap: () => taps.add('%'),
    ),
    KeypadEntry(
      label: '÷',
      kind: CalcKeyKind.operator,
      semanticLabel: 'Divide',
      onTap: () => taps.add('÷'),
    ),
    KeypadEntry(label: '7', onTap: () => taps.add('7')),
    KeypadEntry(label: '8', onTap: () => taps.add('8')),
    KeypadEntry(label: '9', onTap: () => taps.add('9')),
    KeypadEntry(
      label: '×',
      kind: CalcKeyKind.operator,
      semanticLabel: 'Multiply',
      onTap: () => taps.add('×'),
    ),
    KeypadEntry(label: '4', onTap: () => taps.add('4')),
    KeypadEntry(label: '5', onTap: () => taps.add('5')),
    KeypadEntry(label: '6', onTap: () => taps.add('6')),
    KeypadEntry(
      label: '−',
      kind: CalcKeyKind.operator,
      semanticLabel: 'Subtract',
      onTap: () => taps.add('−'),
    ),
    KeypadEntry(label: '1', onTap: () => taps.add('1')),
    KeypadEntry(label: '2', onTap: () => taps.add('2')),
    KeypadEntry(label: '3', onTap: () => taps.add('3')),
    KeypadEntry(
      label: '+',
      kind: CalcKeyKind.operator,
      semanticLabel: 'Add',
      onTap: () => taps.add('+'),
    ),
    KeypadEntry(
      label: '±',
      kind: CalcKeyKind.function,
      semanticLabel: 'Toggle sign',
      onTap: () => taps.add('±'),
    ),
    KeypadEntry(label: '0', onTap: () => taps.add('0')),
    KeypadEntry(
      label: '.',
      semanticLabel: 'Decimal point',
      onTap: () => taps.add('.'),
    ),
    KeypadEntry(
      label: '=',
      kind: CalcKeyKind.equals,
      onTap: () => taps.add('='),
    ),
  ];

  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: Center(child: SizedBox(width: 350, child: child)),
    ),
  );

  testWidgets('renders a 4×5 Basic keypad on the design grid', (tester) async {
    final List<String> taps = <String>[];

    await tester.pumpWidget(wrap(Keypad(spec: basicSpec(taps), columns: 4)));

    expect(find.byType(CalcKeyButton), findsNWidgets(20));

    final List<Rect> keys = <Rect>[
      for (int index = 0; index < 20; index++)
        tester.getRect(find.byType(CalcKeyButton).at(index)),
    ];

    // 350 px wide sheet content, 3 × 12 px gaps → 78.5 px keys.
    expect(keys.first.width, closeTo((350 - 36) / 4, 0.01));
    expect(keys.first.height, AppSizes.keyHeightBasic);
    expect(keys[1].left - keys[0].right, AppSizes.keyGapBasic);
    expect(
      keys[4].top - keys[0].top,
      AppSizes.keyHeightBasic + AppSizes.keyGapBasic,
    );

    for (int row = 0; row < 5; row++) {
      for (int column = 1; column < 4; column++) {
        final Rect previous = keys[row * 4 + column - 1];
        final Rect current = keys[row * 4 + column];
        expect(current.top, previous.top);
        expect(current.left, greaterThan(previous.left));
      }
    }

    // Column 1 of every row lines up.
    expect(keys[1].left, keys[5].left);
    expect(keys[1].left, keys[9].left);

    await tester.tap(find.text('+'));
    await tester.pump();
    expect(taps, <String>['+']);
  });

  testWidgets('renders a 5-column Scientific keypad with compact keys', (
    tester,
  ) async {
    final List<String> taps = <String>[];

    await tester.pumpWidget(
      wrap(
        Keypad(
          spec: basicSpec(taps),
          columns: 5,
          density: CalcKeyDensity.scientific,
        ),
      ),
    );

    expect(find.byType(CalcKeyButton), findsNWidgets(20));
    expect(
      tester.widget<CalcKeyButton>(find.byType(CalcKeyButton).first).density,
      CalcKeyDensity.scientific,
    );

    final Rect first = tester.getRect(find.byType(CalcKeyButton).first);
    final Rect sixth = tester.getRect(find.byType(CalcKeyButton).at(5));
    expect(first.height, AppSizes.keyHeightScientific);
    expect(first.width, closeTo((350 - 32) / 5, 0.01));
    expect(
      sixth.top - first.top,
      AppSizes.keyHeightScientific + AppSizes.keyGapScientific,
    );
  });

  testWidgets('a short last row keeps the shared column widths', (
    tester,
  ) async {
    final List<String> taps = <String>[];

    await tester.pumpWidget(
      wrap(Keypad(spec: basicSpec(taps).take(6).toList(), columns: 4)),
    );

    expect(find.byType(CalcKeyButton), findsNWidgets(6));

    final Rect first = tester.getRect(find.byType(CalcKeyButton).first);
    final Rect fifth = tester.getRect(find.byType(CalcKeyButton).at(4));
    final Rect sixth = tester.getRect(find.byType(CalcKeyButton).at(5));

    expect(fifth.left, first.left);
    expect(sixth.left, tester.getRect(find.byType(CalcKeyButton).at(1)).left);
    expect(sixth.width, closeTo(first.width, 0.01));
  });

  testWidgets('passes labels, kinds and semantic names to each key', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(Keypad(spec: basicSpec(<String>[]), columns: 4)),
    );

    final CalcKeyButton divide = tester.widget<CalcKeyButton>(
      find.byType(CalcKeyButton).at(3),
    );
    expect(divide.label, '÷');
    expect(divide.kind, CalcKeyKind.operator);
    expect(divide.semanticLabel, 'Divide');

    final CalcKeyButton equals = tester.widget<CalcKeyButton>(
      find.byType(CalcKeyButton).at(19),
    );
    expect(equals.kind, CalcKeyKind.equals);
    expect(equals.density, CalcKeyDensity.basic);
    expect(equals.haptics, isTrue);
  });

  testWidgets('passes a secondary action to its key', (tester) async {
    int holds = 0;

    await tester.pumpWidget(
      wrap(
        Keypad(
          spec: <KeypadEntry>[
            KeypadEntry(
              label: '⌫',
              kind: CalcKeyKind.function,
              onTap: () {},
              onLongPress: () => holds++,
            ),
          ],
          columns: 4,
        ),
      ),
    );

    await tester.longPress(find.byType(CalcKeyButton));
    await tester.pump();

    expect(holds, 1);
  });
}
