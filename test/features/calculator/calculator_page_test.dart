import 'package:calculator/core/engine/calc_result.dart';
import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/features/calculator/calculator_page.dart';
import 'package:calculator/features/calculator/widgets/display.dart';
import 'package:calculator/features/calculator/widgets/calc_key_button.dart';
import 'package:calculator/features/calculator/widgets/keypad.dart';
import 'package:calculator/shared/widgets/blue_header.dart';
import 'package:calculator/shared/widgets/segmented.dart';
import 'package:calculator/shared/widgets/white_sheet.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:calculator/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app() => ProviderScope(
    overrides: [kvStoreProvider.overrideWithValue(MemoryKvStore())],
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
        matching: find.text('Calculator'),
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
    await tester.pump();
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
}
