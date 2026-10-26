import 'package:calculator/core/engine/angle_mode.dart';
import 'package:calculator/core/engine/calc_result.dart';
import 'package:calculator/core/memory/memory_slots.dart';
import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/features/calculator/calculator_page.dart';
import 'package:calculator/features/calculator/widgets/display.dart';
import 'package:calculator/features/calculator/widgets/calc_key_button.dart';
import 'package:calculator/features/calculator/widgets/keypad.dart';
import 'package:calculator/features/history/memory_controller.dart';
import 'package:calculator/features/settings/settings_controller.dart';
import 'package:calculator/features/settings/settings_model.dart';
import 'package:calculator/features/settings/settings_page.dart';
import 'package:calculator/shared/widgets/blue_header.dart';
import 'package:calculator/shared/widgets/segmented.dart';
import 'package:calculator/shared/widgets/white_sheet.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:calculator/theme/app_tokens.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app([MemoryKvStore? store]) => ProviderScope(
    overrides: [kvStoreProvider.overrideWithValue(store ?? MemoryKvStore())],
    child: MaterialApp(theme: AppTheme.light(), home: const CalculatorPage()),
  );

  /// The screens in `docs/screens/` are 390×844; the page overflows the
  /// 800×600 test default.
  void designSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Finder key(String label) =>
      find.descendant(of: find.byType(Keypad), matching: find.text(label));

  /// The whole key cell, for measuring the grid rather than the glyph.
  Finder keyButton(String label) =>
      find.ancestor(of: key(label), matching: find.byType(CalcKeyButton));

  String resultText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('display-result'))).data!;

  String expressionText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('display-expression'))).data!;

  TextStyle resultStyle(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('display-result'))).style!;

  Future<void> tapKeys(WidgetTester tester, List<String> labels) async {
    for (final String label in labels) {
      await tester.tap(key(label));
      await tester.pump();
    }
  }

  testWidgets('assembles the header, mode switcher, display and 4×5 keypad', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    expect(
      find.descendant(
        of: find.byType(BlueHeader),
        matching: find.text('Hisab'),
      ),
      findsOneWidget,
    );
    expect(find.byType(BlueHeader), findsOneWidget);
    expect(find.byType(Segmented), findsOneWidget);
    expect(find.text('Basic'), findsOneWidget);
    expect(find.text('Scientific'), findsOneWidget);
    expect(find.text('Programmer'), findsOneWidget);
    expect(find.byType(Display), findsOneWidget);
    expect(find.byType(WhiteSheet), findsOneWidget);
    expect(find.byType(CalcKeyButton), findsNWidgets(20));

    expect(expressionText(tester), '');
    expect(resultText(tester), '0');
    expect(resultStyle(tester).color, AppColors.onPrimary);
  });

  testWidgets('typing shows the expression and a lighter live preview', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    await tapKeys(tester, <String>['5', '+', '3']);

    expect(expressionText(tester), '5 + 3');
    expect(resultText(tester), '8');
    expect(resultStyle(tester).color, AppColors.onPrimaryMuted);
  });

  testWidgets('= commits the answer and clears the expression line', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    await tapKeys(tester, <String>['5', '+', '3', '=']);

    expect(expressionText(tester), '');
    expect(resultText(tester), '8');
    expect(resultStyle(tester).color, AppColors.onPrimary);
  });

  testWidgets('decimal arithmetic stays exact: 0.1 + 0.2 = 0.3', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    await tapKeys(tester, <String>['0', '.', '1', '+', '0', '.', '2', '=']);

    expect(resultText(tester), '0.3');
  });

  testWidgets('dividing by zero shows the plain-word error', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    await tapKeys(tester, <String>['5', '÷', '0', '=']);

    expect(resultText(tester), "Can't divide by zero");
    expect(resultStyle(tester).color, AppColors.warning);
    expect(expressionText(tester), '5 ÷ 0');
  });

  testWidgets('C clears the typed expression and returns to 0', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    await tapKeys(tester, <String>['1', '2', '+', 'C']);

    expect(expressionText(tester), '');
    expect(resultText(tester), '0');
  });

  testWidgets('long-pressing ⌫ clears the expression too', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    await tapKeys(tester, <String>['1', '2', '×', '3']);
    expect(expressionText(tester), '12 × 3');

    await tester.longPress(key('⌫'));
    await tester.pump();

    expect(expressionText(tester), '');
    expect(resultText(tester), '0');
  });

  testWidgets('a digit after = starts a new expression', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    await tapKeys(tester, <String>['5', '+', '3', '=', '7']);

    expect(expressionText(tester), '7');
    expect(resultText(tester), '7');
    expect(resultStyle(tester).color, AppColors.onPrimary);
  });

  testWidgets('± works end to end: (−5) + 3 = −2', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    await tapKeys(tester, <String>['5', '±', '+', '3']);
    expect(expressionText(tester), '(−5) + 3');
    expect(resultText(tester), '−2');

    await tapKeys(tester, <String>['=']);
    expect(expressionText(tester), '');
    expect(resultText(tester), '−2');
  });

  testWidgets('the mode switcher updates the selected segment', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    await tester.tap(find.text('Scientific'));
    await tester.pump();

    expect(tester.widget<Segmented>(find.byType(Segmented)).selectedIndex, 1);

    await tester.tap(find.text('Programmer'));
    await tester.pumpAndSettle();
    expect(tester.widget<Segmented>(find.byType(Segmented)).selectedIndex, 2);
  });

  testWidgets('errors keep their message after another key is pressed', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    await tapKeys(tester, <String>['5', '÷', '0', '=']);
    expect(resultText(tester), CalcError.divideByZero.displayText);

    await tapKeys(tester, <String>['⌫']);
    expect(expressionText(tester), '5 ÷');
    expect(resultStyle(tester).color, AppColors.onPrimary);
  });

  testWidgets(
    'Scientific mode shows the 5×7 keypad, chips and compact metrics',
    (tester) async {
      designSurface(tester);
      await tester.pumpWidget(app());

      await tester.tap(find.text('Scientific'));
      await tester.pumpAndSettle();

      expect(find.byType(CalcKeyButton), findsNWidgets(35));
      final Keypad keypad = tester.widget<Keypad>(find.byType(Keypad));
      expect(keypad.columns, 5);
      expect(keypad.density, CalcKeyDensity.scientific);

      expect(find.byKey(const Key('angle-controls')), findsOneWidget);
      expect(find.text('DEG'), findsOneWidget);
      expect(find.text('RAD'), findsOneWidget);
      expect(find.byKey(const Key('bracket-badge')), findsNothing);

      expect(resultStyle(tester).fontSize, 52);
      final Finder seven = find
          .ancestor(of: key('7'), matching: find.byType(CalcKeyButton))
          .first;
      expect(tester.getSize(seven).height, 46);
      expect(tester.getRect(seven).left, AppSizes.sheetScientificPaddingSide);

      final WhiteSheet sheet = tester.widget<WhiteSheet>(
        find.byType(WhiteSheet),
      );
      expect(
        (sheet.padding! as EdgeInsets).left,
        AppSizes.sheetScientificPaddingSide,
      );
      expect(sheet.contentGap, AppSizes.sheetScientificContentGap);
    },
  );

  testWidgets('the DEG/RAD chip changes how trig evaluates', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    await tester.tap(find.text('Scientific'));
    await tester.pump();
    await tapKeys(tester, <String>['sin', '3', '0']);
    expect(resultText(tester), '0.5');

    await tester.tap(find.byKey(const Key('angle-rad')));
    await tester.pump();
    expect(resultText(tester), '−0.988031624093');

    await tester.tap(find.byKey(const Key('angle-deg')));
    await tester.pump();
    expect(resultText(tester), '0.5');
  });

  testWidgets('2nd swaps the labels, highlights itself and resets after use', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    await tester.tap(find.text('Scientific'));
    await tester.pump();
    await tester.tap(key('2nd'));
    await tester.pump();

    for (final String label in <String>[
      'sin⁻¹',
      'cos⁻¹',
      'tan⁻¹',
      'x³',
      'ʸ√x',
      '∛x',
      'eˣ',
      '10ˣ',
    ]) {
      expect(key(label), findsOneWidget, reason: label);
    }
    expect(
      tester
          .widget<CalcKeyButton>(find.widgetWithText(CalcKeyButton, '2nd'))
          .kind,
      CalcKeyKind.active,
    );

    await tapKeys(tester, <String>['sin⁻¹', '0', '.', '5', '=']);

    expect(resultText(tester), '30');
    expect(key('sin'), findsOneWidget);
    expect(
      tester
          .widget<CalcKeyButton>(find.widgetWithText(CalcKeyButton, '2nd'))
          .kind,
      CalcKeyKind.function,
    );
  });

  testWidgets('the bracket badge counts open brackets and disappears at zero', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    await tester.tap(find.text('Scientific'));
    await tester.pump();

    await tapKeys(tester, <String>['(', '(']);
    expect(find.byKey(const Key('bracket-badge')), findsOneWidget);
    expect(find.text('(2'), findsOneWidget);

    await tapKeys(tester, <String>['1', ')']);
    expect(find.text('(1'), findsOneWidget);

    await tapKeys(tester, <String>[')']);
    expect(find.byKey(const Key('bracket-badge')), findsNothing);
  });

  testWidgets('the scientific keypad evaluates roots and reciprocals', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    await tester.tap(find.text('Scientific'));
    await tester.pump();

    await tapKeys(tester, <String>['8', 'xʸ', '3', '=']);
    expect(resultText(tester), '512');

    await tapKeys(tester, <String>['C', '4', '1/x', '=']);
    expect(resultText(tester), '0.25');
  });

  testWidgets('the chosen mode is remembered on the next launch', (
    tester,
  ) async {
    designSurface(tester);
    final MemoryKvStore store = MemoryKvStore();
    Widget page() => ProviderScope(
      overrides: [kvStoreProvider.overrideWithValue(store)],
      child: MaterialApp(theme: AppTheme.light(), home: const CalculatorPage()),
    );

    await tester.pumpWidget(page());
    await tester.pump();
    await tester.tap(find.text('Scientific'));
    await tester.pumpAndSettle();
    expect(tester.widget<Segmented>(find.byType(Segmented)).selectedIndex, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();

    expect(tester.widget<Segmented>(find.byType(Segmented)).selectedIndex, 1);
    expect(find.byType(CalcKeyButton), findsNWidgets(35));
  });

  testWidgets('Programmer mode shows the 5×7 keypad and the base rows', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    await tester.tap(find.text('Programmer'));
    await tester.pumpAndSettle();

    expect(find.byType(CalcKeyButton), findsNWidgets(35));
    expect(find.byKey(const Key('angle-controls')), findsNothing);
    expect(find.byKey(const Key('programmer-display')), findsOneWidget);
    expect(find.text('32-bit'), findsOneWidget);

    for (final String label in <String>[
      'AND',
      'OR',
      'XOR',
      'NOT',
      'NAND',
      '<<',
      '>>',
      'AC',
      '⌫',
      'mod',
      'A',
      'F',
      '=',
    ]) {
      expect(key(label), findsOneWidget, reason: label);
    }

    // Scientific density: 46 px keys on the 8 px grid, five per row.
    final Rect and = tester.getRect(keyButton('AND'));
    expect(and.height, AppSizes.keyHeightScientific);
    expect(
      tester.getRect(keyButton('OR')).left - and.right,
      AppSizes.keyGapScientific,
    );
    expect(
      tester.getRect(keyButton('A')).top - and.bottom,
      AppSizes.keyGapScientific,
    );
    expect(tester.getRect(keyButton('B')).left, and.left);
  });

  testWidgets('typing a bitwise expression previews then commits it', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app());
    await tester.tap(find.text('Programmer'));
    await tester.pumpAndSettle();

    await tapKeys(tester, <String>['5', 'AND', '3']);

    expect(
      tester.widget<Text>(find.byKey(const Key('programmer-expression'))).data,
      '5 AND 3',
    );
    final Text preview = tester.widget<Text>(
      find.byKey(const Key('programmer-value')),
    );
    expect(preview.data, '1');
    expect(preview.style?.color, AppColors.onPrimaryMuted);

    await tapKeys(tester, <String>['=']);

    expect(
      tester.widget<Text>(find.byKey(const Key('programmer-expression'))).data,
      '',
    );
    final Text committed = tester.widget<Text>(
      find.byKey(const Key('programmer-value')),
    );
    expect(committed.data, '1');
    expect(committed.style?.color, AppColors.onPrimary);
  });

  testWidgets('a base row converts the value and disables unreadable digits', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app());
    await tester.tap(find.text('Programmer'));
    await tester.pumpAndSettle();

    await tapKeys(tester, <String>['2', '0', '2', '1']);
    expect(
      tester.widget<Text>(find.byKey(const Key('base-value-dec'))).data,
      '2,021',
    );

    await tester.tap(find.byKey(const Key('base-hex')));
    await tester.pump();

    expect(
      tester.widget<Text>(find.byKey(const Key('programmer-value'))).data,
      '7E5',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('programmer-expression'))).data,
      '7E5',
    );
    expect(
      tester.widget<CalcKeyButton>(keyButton('A')).kind,
      CalcKeyKind.number,
    );
    expect(
      tester.widget<CalcKeyButton>(keyButton('9')).kind,
      CalcKeyKind.number,
    );

    await tester.tap(find.byKey(const Key('base-oct')));
    await tester.pump();

    expect(
      tester.widget<Text>(find.byKey(const Key('base-value-oct'))).data,
      '3745',
    );
    expect(
      tester.widget<CalcKeyButton>(keyButton('8')).kind,
      CalcKeyKind.disabled,
    );
    expect(
      tester.widget<CalcKeyButton>(keyButton('7')).kind,
      CalcKeyKind.number,
    );

    // Tapping a disabled key does not type it.
    await tester.tap(key('8'), warnIfMissed: false);
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('programmer-value'))).data,
      '3745',
    );

    await tester.tap(find.byKey(const Key('base-bin')));
    await tester.pump();

    expect(
      tester.widget<CalcKeyButton>(keyButton('1')).kind,
      CalcKeyKind.number,
    );
    expect(
      tester.widget<CalcKeyButton>(keyButton('2')).kind,
      CalcKeyKind.disabled,
    );
  });

  testWidgets('the word-size chip changes the width and toasts a truncation', (
    tester,
  ) async {
    designSurface(tester);
    // The shell supplies the Scaffold in production; this page-level test needs
    // one for the truncation toast.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [kvStoreProvider.overrideWithValue(MemoryKvStore())],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: CalculatorPage()),
        ),
      ),
    );
    await tester.tap(find.text('Programmer'));
    await tester.pumpAndSettle();

    await tapKeys(tester, <String>['2', '5', '5']);

    await tester.tap(find.byKey(const Key('word-size-chip')));
    await tester.pumpAndSettle();

    for (final int bits in <int>[8, 16, 32, 64]) {
      expect(find.byKey(Key('word-size-$bits')), findsOneWidget);
    }

    await tester.tap(find.byKey(const Key('word-size-8')));
    await tester.pumpAndSettle();

    expect(find.text('8-bit'), findsOneWidget);
    expect(find.text('Value truncated to 8-bit'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('programmer-value'))).data,
      '−1',
    );

    await tester.tap(find.byKey(const Key('word-size-chip')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('word-size-16')));
    await tester.pumpAndSettle();

    expect(find.text('16-bit'), findsOneWidget);
    expect(find.text('Value truncated to 16-bit'), findsNothing);
  });

  testWidgets('the Settings header action opens the Settings page', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BlueHeader),
        matching: find.text('Settings'),
      ),
      findsOneWidget,
    );
    expect(find.byType(CalcKeyButton), findsNothing);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsNothing);
    expect(find.byType(CalcKeyButton), findsNWidgets(20));
  });

  testWidgets('stored formatter and feedback settings reach the page', (
    tester,
  ) async {
    designSurface(tester);
    final MemoryKvStore store = MemoryKvStore(<String, String>{
      SettingsController.key: const Settings(
        decimalPlaces: 2,
        thousandsSeparator: true,
        haptics: false,
        keySounds: true,
      ).encode(),
    });
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();

    expect(tester.widget<Keypad>(find.byType(Keypad)).haptics, isFalse);
    expect(tester.widget<Keypad>(find.byType(Keypad)).sounds, isTrue);

    await tapKeys(tester, <String>['1', '8', '0', '0']);
    expect(expressionText(tester), '1,800');

    await tapKeys(tester, <String>['÷', '3']);
    expect(expressionText(tester), '1,800 ÷ 3');
    expect(resultText(tester), '600.00');

    await tester.tap(key('='));
    await tester.pump();
    expect(expressionText(tester), '');
    expect(resultText(tester), '600.00');
  });

  testWidgets('the stored angle unit is used until the chip changes it', (
    tester,
  ) async {
    designSurface(tester);
    final MemoryKvStore store = MemoryKvStore(<String, String>{
      SettingsController.key: const Settings(angleMode: AngleMode.rad).encode(),
    });
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Scientific'));
    await tester.pumpAndSettle();
    await tapKeys(tester, <String>['sin', '3', '0']);
    expect(resultText(tester), '−0.988031624093');

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(CalculatorPage)),
    );
    await tester.tap(find.byKey(const Key('angle-deg')));
    await tester.pumpAndSettle();

    expect(container.read(settingsProvider).angleMode, AngleMode.deg);
    expect(resultText(tester), '0.5');
  });

  testWidgets('changing Settings updates the display live', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tapKeys(tester, <String>['1', '8', '0', '0', '+', '2', '0', '0']);
    expect(expressionText(tester), '1,800 + 200');

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(CalculatorPage)),
    );
    container.read(settingsProvider.notifier).setThousandsSeparator(false);
    await tester.pumpAndSettle();

    expect(expressionText(tester), '1800 + 200');
    expect(resultText(tester), '2000');
  });

  testWidgets('a stored memory value shows in the display chip', (
    tester,
  ) async {
    designSurface(tester);
    final MemoryKvStore store = MemoryKvStore(<String, String>{
      MemoryController.key: MemorySlots.encode(<Decimal?>[
        Decimal.fromInt(128),
      ]),
    });
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('display-memory')), findsOneWidget);
    expect(find.text('M = 128'), findsOneWidget);
  });

  testWidgets('the chip long-press stores and clears the main memory', (
    tester,
  ) async {
    designSurface(tester);
    final MemoryKvStore store = MemoryKvStore(<String, String>{
      MemoryController.key: MemorySlots.encode(<Decimal?>[
        Decimal.fromInt(128),
      ]),
    });
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();

    await tapKeys(tester, <String>['5']);
    expect(find.text('M = 128'), findsOneWidget);

    await tester.longPress(find.byKey(const Key('display-memory')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memory-store')), findsOneWidget);
    expect(find.byKey(const Key('memory-clear')), findsOneWidget);

    await tester.tap(find.byKey(const Key('memory-store')));
    await tester.pumpAndSettle();

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(CalculatorPage)),
    );
    expect(container.read(memoryProvider)[0], Decimal.fromInt(128));
    expect(container.read(memoryProvider)[1], Decimal.fromInt(5));
    expect(find.text('M = 128'), findsOneWidget);
    expect(
      MemorySlots.decode(await store.getString(MemoryController.key))[1],
      Decimal.fromInt(5),
    );

    await tester.longPress(find.byKey(const Key('display-memory')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('memory-clear')));
    await tester.pumpAndSettle();

    // M2 moved up into the main slot, so the chip follows it.
    expect(container.read(memoryProvider)[0], Decimal.fromInt(5));
    expect(find.text('M = 5'), findsOneWidget);

    await tester.longPress(find.byKey(const Key('display-memory')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('memory-clear')));
    await tester.pumpAndSettle();

    expect(container.read(memoryProvider)[0], isNull);
    expect(find.byKey(const Key('display-memory')), findsNothing);
  });
}
