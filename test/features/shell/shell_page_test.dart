import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/features/calculator/calculator_page.dart';
import 'package:calculator/features/calculator/widgets/display.dart';
import 'package:calculator/features/calculator/widgets/keypad.dart';
import 'package:calculator/features/shell/shell_page.dart';
import 'package:calculator/shared/widgets/blue_header.dart';
import 'package:calculator/shared/widgets/bottom_nav.dart';
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
    child: MaterialApp(theme: AppTheme.light(), home: const ShellPage()),
  );

  /// The calculator page needs the 390×844 design height inside the shell.
  void designSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Finder inNav(String label) =>
      find.descendant(of: find.byType(BottomNav), matching: find.text(label));

  Finder key(String label) =>
      find.descendant(of: find.byType(Keypad), matching: find.text(label));

  IndexedStack stack(WidgetTester tester) =>
      tester.widget<IndexedStack>(find.byType(IndexedStack));

  testWidgets('starts on Calculator with four tabs kept in an IndexedStack', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    expect(stack(tester).index, 0);
    expect(stack(tester).children.length, 4);
    expect(find.byType(CalculatorPage), findsOneWidget);
    expect(find.byType(BlueHeader), findsOneWidget);
    expect(find.byType(Segmented), findsOneWidget);
    expect(find.byType(Display), findsOneWidget);
    expect(find.byType(WhiteSheet), findsOneWidget);
    expect(find.byType(Keypad), findsOneWidget);
    expect(find.byType(BottomNav), findsOneWidget);
  });

  testWidgets('picking a nav item switches the IndexedStack', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    await tester.tap(inNav('Convert'));
    await tester.pump();
    expect(stack(tester).index, 1);

    await tester.tap(inNav('Tools'));
    await tester.pump();
    expect(stack(tester).index, 2);

    await tester.tap(inNav('History'));
    await tester.pump();
    expect(stack(tester).index, 3);

    await tester.tap(inNav('Calculator'));
    await tester.pump();
    expect(stack(tester).index, 0);
  });

  testWidgets('the Calculator tab keeps its work while another tab is open', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    await tester.tap(key('5'));
    await tester.pump();
    await tester.tap(key('+'));
    await tester.pump();
    await tester.tap(key('3'));
    await tester.pump();

    expect(
      tester.widget<Text>(find.byKey(const Key('display-result'))).data,
      '8',
    );

    await tester.tap(inNav('History'));
    await tester.pump();
    await tester.tap(inNav('Calculator'));
    await tester.pump();

    expect(
      tester.widget<Text>(find.byKey(const Key('display-expression'))).data,
      '5 + 3',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('display-result'))).data,
      '8',
    );
  });

  testWidgets('the active pill follows the selected tab', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    await tester.tap(inNav('History'));
    await tester.pump();

    final Material historyItem = tester.widget<Material>(
      find
          .ancestor(
            of: find.byIcon(Icons.schedule_rounded),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(historyItem.color, AppColors.keyOperator);

    final Material calculatorItem = tester.widget<Material>(
      find
          .ancestor(
            of: find.byIcon(Icons.calculate_outlined),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(calculatorItem.color, Colors.transparent);
  });
}
