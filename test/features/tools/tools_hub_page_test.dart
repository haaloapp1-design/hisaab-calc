import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/core/tools/tool_catalog.dart';
import 'package:calculator/features/tools/pages/age_page.dart';
import 'package:calculator/features/tools/pages/bmi_page.dart';
import 'package:calculator/features/tools/pages/date_difference_page.dart';
import 'package:calculator/features/tools/pages/discount_page.dart';
import 'package:calculator/features/tools/pages/equation_page.dart';
import 'package:calculator/features/tools/pages/gpa_page.dart';
import 'package:calculator/features/tools/pages/loan_page.dart';
import 'package:calculator/features/tools/pages/percentage_page.dart';
import 'package:calculator/features/tools/pages/statistics_page.dart';
import 'package:calculator/features/tools/pages/tip_page.dart';
import 'package:calculator/features/tools/pages/tool_placeholder_page.dart';
import 'package:calculator/features/tools/tools_hub_page.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:calculator/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app({ValueChanged<Tool>? onToolSelected}) => ProviderScope(
    overrides: [kvStoreProvider.overrideWithValue(MemoryKvStore())],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: ToolsHubPage(onToolSelected: onToolSelected),
    ),
  );

  /// The screens in `docs/screens/` are 390×844.
  void designSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('shows the Tools header and all ten tool cards', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Tools'), findsOneWidget);
    expect(
      find.text('Ready-made calculators for everyday sums'),
      findsOneWidget,
    );

    final Container header = tester.widget<Container>(
      find.byKey(const Key('blue-header')),
    );
    expect(
      header.padding,
      const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.hubHeaderPaddingTop,
        AppSizes.screenPadding,
        AppSizes.toolsHeaderPaddingBottom,
      ),
    );

    expect(find.byKey(const Key('tools-grid')), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('tools-grid'))).width, 350);

    for (final Tool tool in ToolCatalog.tools) {
      final Finder card = find.byKey(Key('tool-card-${tool.id}'));
      expect(card, findsOneWidget, reason: tool.id);
      for (final String text in <String>[
        tool.name,
        tool.subtitle,
        tool.symbol,
      ]) {
        expect(
          find.descendant(of: card, matching: find.text(text)),
          findsWidgets,
          reason: '${tool.id}: $text',
        );
      }
    }
  });

  testWidgets('uses the screen 09 card measurements', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    final Size card = tester.getSize(find.byKey(const Key('tool-card-loan')));
    expect(card.width, 170);
    expect(card.height, AppSizes.toolsCardHeight);

    final Offset first = tester.getTopLeft(
      find.byKey(const Key('tool-card-loan')),
    );
    final Offset second = tester.getTopLeft(
      find.byKey(const Key('tool-card-percentage')),
    );
    final Offset third = tester.getTopLeft(
      find.byKey(const Key('tool-card-discount')),
    );
    expect(first.dx, AppSizes.screenPadding);
    expect(second.dx - first.dx, 170 + AppSizes.toolsGridGap);
    expect(
      third.dy - first.dy,
      AppSizes.toolsCardHeight + AppSizes.toolsGridGap,
    );

    final Size chip = tester.getSize(find.byKey(const Key('tool-chip-loan')));
    expect(chip.height, AppSizes.toolsChipHeight);
    expect(chip.width, greaterThanOrEqualTo(AppSizes.toolsChipMinWidth));

    final Container chipBox = tester.widget<Container>(
      find.byKey(const Key('tool-chip-loan')),
    );
    final BoxDecoration chipDecoration = chipBox.decoration! as BoxDecoration;
    expect(chipDecoration.color, AppColors.keyOperator);

    final Text name = tester.widget<Text>(find.text('Loan / EMI'));
    expect(name.style?.fontSize, 15);
    expect(name.style?.fontWeight, AppTypography.medium);
    expect(name.style?.color, AppColors.ink);

    final Text subtitle = tester.widget<Text>(find.text('Monthly instalment'));
    expect(subtitle.style?.fontSize, 12);
    expect(subtitle.style?.color, AppColors.inkMuted);

    final Text symbol = tester.widget<Text>(find.text('EMI'));
    expect(symbol.style?.fontSize, 13);
    expect(symbol.style?.fontWeight, AppTypography.bold);
    expect(symbol.style?.color, AppColors.primary);
  });

  testWidgets('every card opens its own tool page', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    for (final Tool tool in ToolCatalog.tools) {
      await tester.tap(find.byKey(Key('tool-card-${tool.id}')));
      await tester.pumpAndSettle();

      if (tool.id == 'loan') {
        expect(find.byType(LoanPage), findsOneWidget);
        expect(find.text('Monthly instalment'), findsOneWidget);
      } else if (tool.id == 'percentage') {
        expect(find.byType(PercentagePage), findsOneWidget);
        expect(find.text('X% of Y'), findsOneWidget);
      } else if (tool.id == 'discount') {
        expect(find.byType(DiscountPage), findsOneWidget);
        expect(find.text('Final price'), findsWidgets);
      } else if (tool.id == 'tip') {
        expect(find.byType(TipPage), findsOneWidget);
        expect(find.text('Per person'), findsWidgets);
      } else if (tool.id == 'age') {
        expect(find.byType(AgePage), findsOneWidget);
        expect(find.text('Date of birth'), findsOneWidget);
      } else if (tool.id == 'date-diff') {
        expect(find.byType(DateDifferencePage), findsOneWidget);
        expect(find.text('Days between'), findsOneWidget);
      } else if (tool.id == 'bmi') {
        expect(find.byType(BmiPage), findsOneWidget);
        expect(find.text('Height (cm)'), findsOneWidget);
      } else if (tool.id == 'gpa') {
        expect(find.byType(GpaPage), findsOneWidget);
        expect(find.text('Grade points'), findsWidgets);
      } else if (tool.id == 'equation') {
        expect(find.byType(EquationPage), findsOneWidget);
        expect(find.text('Quadratic'), findsOneWidget);
      } else if (tool.id == 'statistics') {
        expect(find.byType(StatisticsPage), findsOneWidget);
        expect(find.text('Values (comma separated)'), findsOneWidget);
      } else {
        expect(
          find.byType(ToolPlaceholderPage),
          findsOneWidget,
          reason: tool.id,
        );
        expect(find.byKey(Key('tool-note-${tool.id}')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(Key('tool-note-${tool.id}')),
            matching: find.text(tool.name),
          ),
          findsWidgets,
          reason: tool.id,
        );
        expect(find.text('Coming soon'), findsOneWidget, reason: tool.id);
        expect(find.text('—'), findsOneWidget, reason: tool.id);
      }

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tools-grid')), findsOneWidget);
    }
  });

  testWidgets('a callback overrides the tool route', (tester) async {
    designSurface(tester);
    final List<String> picked = <String>[];
    await tester.pumpWidget(
      app(onToolSelected: (Tool tool) => picked.add(tool.id)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tool-card-statistics')));
    await tester.pumpAndSettle();

    expect(picked, <String>['statistics']);
    expect(find.byType(ToolPlaceholderPage), findsNothing);
  });
}
