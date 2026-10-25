import 'package:calculator/features/shell/shell_page.dart';
import 'package:calculator/shared/widgets/blue_header.dart';
import 'package:calculator/shared/widgets/bottom_nav.dart';
import 'package:calculator/shared/widgets/segmented.dart';
import 'package:calculator/shared/widgets/white_sheet.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:calculator/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app() =>
      MaterialApp(theme: AppTheme.light(), home: const ShellPage());

  Finder inNav(String label) => find.descendant(
    of: find.byType(BottomNav),
    matching: find.text(label),
  );

  IndexedStack stack(WidgetTester tester) =>
      tester.widget<IndexedStack>(find.byType(IndexedStack));

  testWidgets('starts on Calculator with four tabs kept in an IndexedStack', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    expect(stack(tester).index, 0);
    expect(stack(tester).children.length, 4);
    expect(find.byType(BlueHeader), findsOneWidget);
    expect(find.byType(Segmented), findsOneWidget);
    expect(find.byType(WhiteSheet), findsOneWidget);
    expect(find.text('Basic mode'), findsOneWidget);
    expect(find.byType(BottomNav), findsOneWidget);
  });

  testWidgets('the placeholder segmented control switches the shown mode', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    expect(find.text('Basic mode'), findsOneWidget);

    await tester.tap(find.text('Scientific'));
    await tester.pump();
    expect(find.text('Scientific mode'), findsOneWidget);

    await tester.tap(find.text('Programmer'));
    await tester.pump();
    expect(find.text('Programmer mode'), findsOneWidget);
  });

  testWidgets('picking a nav item switches the IndexedStack', (tester) async {
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

  testWidgets('the active pill follows the selected tab', (tester) async {
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
