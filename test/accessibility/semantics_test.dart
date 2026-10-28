import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/core/units/unit.dart';
import 'package:calculator/features/calculator/calculator_page.dart';
import 'package:calculator/features/calculator/widgets/calc_key_button.dart';
import 'package:calculator/features/converter/converter_hub_page.dart';
import 'package:calculator/features/converter/converter_page.dart';
import 'package:calculator/features/currency/currency_page.dart';
import 'package:calculator/features/history/history_page.dart';
import 'package:calculator/features/settings/settings_page.dart';
import 'package:calculator/features/shell/shell_page.dart';
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
import 'package:calculator/features/tools/tools_hub_page.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// SPEC §7: every key and icon button announces what it does (T48).
///
/// Three rules are checked: an `IconButton` always carries a tooltip (Flutter
/// uses it as the label), every calculator key exposes a non-empty label, and
/// the icon-only controls that have no visible text carry an explicit label
/// with a tap action, so a screen reader can both name and press them.
void main() {
  Widget app(Widget home) => ProviderScope(
    overrides: [kvStoreProvider.overrideWithValue(MemoryKvStore())],
    child: MaterialApp(theme: AppTheme.light(), home: home),
  );

  void designSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pump(WidgetTester tester, Widget home) async {
    await tester.pumpWidget(app(home));
    await tester.pumpAndSettle();
  }

  testWidgets('every icon button carries a tooltip', (tester) async {
    designSurface(tester);

    final Map<String, Widget> pages = <String, Widget>{
      'shell': const ShellPage(),
      'calculator': const CalculatorPage(),
      'converter hub': const ConverterHubPage(),
      'unit converter': const ConverterPage(category: UnitCategory.length),
      'currency': const CurrencyPage(),
      'history': const HistoryPage(),
      'settings': const SettingsPage(),
      'tools hub': const ToolsHubPage(),
      'loan': const LoanPage(),
      'percentage': const PercentagePage(),
      'discount': const DiscountPage(),
      'tip': const TipPage(),
      'age': AgePage(today: DateTime.utc(2026, 10, 28)),
      'date difference': DateDifferencePage(today: DateTime.utc(2026, 10, 28)),
      'BMI': const BmiPage(),
      'GPA': const GpaPage(),
      'equation': const EquationPage(),
      'statistics': const StatisticsPage(),
    };

    for (final MapEntry<String, Widget> page in pages.entries) {
      await pump(tester, page.value);
      final Finder buttons = find.byType(IconButton);
      for (int i = 0; i < buttons.evaluate().length; i++) {
        final IconButton button = tester.widget<IconButton>(buttons.at(i));
        final String where = '${page.key} icon button #$i';
        expect(button.tooltip, isNotNull, reason: where);
        expect(button.tooltip!.trim(), isNotEmpty, reason: where);
      }
    }
  });

  testWidgets('every calculator key has a semantic label', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    designSurface(tester);
    try {
      await pump(tester, const CalculatorPage());

      for (final String mode in <String>['Basic', 'Scientific', 'Programmer']) {
        if (mode != 'Basic') {
          await tester.tap(find.text(mode));
          await tester.pumpAndSettle();
        }

        final Finder keys = find.byType(CalcKeyButton);
        expect(keys, findsWidgets, reason: mode);
        for (int i = 0; i < keys.evaluate().length; i++) {
          final CalcKeyButton key = tester.widget<CalcKeyButton>(keys.at(i));
          final SemanticsNode node = tester.getSemantics(keys.at(i));
          expect(node.label.trim(), isNotEmpty, reason: '$mode key #$i');

          // A key the mode cannot use is still announced, just not pressable.
          if (key.kind != CalcKeyKind.disabled) {
            expect(
              node.getSemanticsData().hasAction(SemanticsAction.tap),
              isTrue,
              reason: '$mode key #$i (${node.label})',
            );
          }
        }
      }
    } finally {
      handle.dispose();
    }
  });

  testWidgets('icon-only controls announce their action', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    designSurface(tester);

    Future<void> expectControl(Widget home, String label) async {
      await pump(tester, home);
      final Finder finder = find.bySemanticsLabel(label);
      expect(finder, findsWidgets, reason: label);
      final SemanticsNode node = tester.getSemantics(finder.first);
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
        reason: label,
      );
    }

    try {
      await expectControl(const CurrencyPage(), 'Change base currency, PKR');
      await expectControl(const CurrencyPage(), 'Add currency');
      await expectControl(
        const ConverterPage(category: UnitCategory.length),
        'Swap units',
      );
      await expectControl(
        const ConverterPage(category: UnitCategory.length),
        'Change from unit, Kilometre (km)',
      );
      await expectControl(
        const ConverterPage(category: UnitCategory.length),
        'Copy result',
      );
      await expectControl(const GpaPage(), 'Add course');
      await expectControl(const SettingsPage(), 'Dark theme');
    } finally {
      handle.dispose();
    }
  });
}
