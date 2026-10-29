import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/core/units/unit.dart';
import 'package:calculator/features/calculator/calculator_page.dart';
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
import 'package:calculator/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// T52: the 390×844 design surface is taller than most phones. A 360×736 dp
/// device gives the calculator column only ~700 dp once the shell's bottom nav
/// and the status-bar inset are paid for, which overflows Scientific mode —
/// the layout tests before T52 pumped the pages *without* the shell, so they
/// never saw it.
///
/// This file pumps every screen on a 360×772 dp window with a 35.3 dp status
/// bar (measured on the affected phone) and fails on any Flutter error, which
/// includes a RenderFlex overflow. The bundled Ubuntu fonts are loaded so the
/// line boxes match a real phone's, and the design-surface sizes are asserted
/// to stay untouched.
void main() {
  setUpAll(() async {
    final FontLoader loader = FontLoader('Ubuntu');
    for (final String weight in <String>['Regular', 'Medium', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/Ubuntu-$weight.ttf'));
    }
    await loader.load();
  });

  Widget app(Widget home, {double topInset = 35.3}) => ProviderScope(
    overrides: [kvStoreProvider.overrideWithValue(MemoryKvStore())],
    child: MaterialApp(
      builder: (BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(padding: EdgeInsets.only(top: topInset)),
        child: child!,
      ),
      home: home,
    ),
  );

  Future<void> pumpPhone(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(360, 772);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(home));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Future<void> pumpDesign(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(home, topInset: 0));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  double keypadHeight(WidgetTester tester) =>
      tester.getSize(find.byKey(const Key('keypad'))).height;

  testWidgets('every calculator mode fits a 360x772 phone', (tester) async {
    await pumpPhone(tester, const ShellPage());

    // Basic keeps the design 60 px keys at the compact threshold.
    expect(
      keypadHeight(tester),
      5 * AppSizes.keyHeightBasic + 4 * AppSizes.keyGapBasic,
    );

    await tester.tap(find.text('Scientific'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      keypadHeight(tester),
      7 * AppSizes.keyHeightScientificCompact +
          6 * AppSizes.keyGapScientificCompact,
    );

    await tester.tap(find.text('Programmer'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      keypadHeight(tester),
      7 * AppSizes.keyHeightScientificCompact +
          6 * AppSizes.keyGapScientificCompact,
    );
  });

  testWidgets(
    'Programmer shows the chip and every base row on a 360x772 phone',
    (tester) async {
      // On the itel NOTE 24 the 232 dp full display got ~148 dp; the scroll view
      // hid the expression, the word-size chip and the big value above the
      // mode switcher.
      await pumpPhone(tester, const ShellPage());
      await tester.tap(find.text('Programmer'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final double switcherBottom = tester
          .getRect(find.text('Programmer').first)
          .bottom;
      final Rect chip = tester.getRect(find.byKey(const Key('word-size-chip')));
      expect(chip.top, greaterThan(switcherBottom));
      final double sheetTop = tester
          .getRect(find.byKey(const Key('keypad')))
          .top;
      for (final String base in <String>['hex', 'dec', 'oct', 'bin']) {
        final Rect row = tester.getRect(find.byKey(Key('base-$base')));
        expect(row.top, greaterThan(switcherBottom), reason: base);
        expect(row.bottom, lessThan(sheetTop), reason: base);
      }
    },
  );

  testWidgets('the design surface keeps the full key sizes', (tester) async {
    await pumpDesign(tester, const CalculatorPage());
    await tester.tap(find.text('Scientific'));
    await tester.pumpAndSettle();
    expect(
      keypadHeight(tester),
      7 * AppSizes.keyHeightScientific + 6 * AppSizes.keyGapScientific,
    );
  });

  testWidgets('the shell keeps the full key sizes on a design-height phone', (
    tester,
  ) async {
    // 844 dp window with a 35.3 dp status bar leaves ~808 dp, above the
    // compact threshold once the bottom nav is paid for.
    await pumpPhone(tester, const ShellPage());
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Scientific'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      keypadHeight(tester),
      7 * AppSizes.keyHeightScientific + 6 * AppSizes.keyGapScientific,
    );
  });

  testWidgets('the other shell tabs fit a 360x772 phone', (tester) async {
    await pumpPhone(tester, const ShellPage());

    for (final String tab in <String>['Convert', 'Tools', 'History']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Calculator'));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Memory'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  final Map<String, Widget> screens = <String, Widget>{
    'converter hub': const ConverterHubPage(),
    'tools hub': const ToolsHubPage(),
    'history': const HistoryPage(),
    'settings': const SettingsPage(),
    'currency': const CurrencyPage(),
    'unit converter': const ConverterPage(category: UnitCategory.length),
    'loan': const LoanPage(),
    'percentage': const PercentagePage(),
    'discount': const DiscountPage(),
    'tip': const TipPage(),
    'age': AgePage(today: DateTime.utc(2026, 10, 29)),
    'date difference': DateDifferencePage(today: DateTime.utc(2026, 10, 29)),
    'BMI': const BmiPage(),
    'GPA': const GpaPage(),
    'equation': const EquationPage(),
    'statistics': const StatisticsPage(),
  };

  for (final MapEntry<String, Widget> screen in screens.entries) {
    testWidgets('the ${screen.key} screen fits a 360x772 phone', (
      tester,
    ) async {
      await pumpPhone(tester, screen.value);
    });
  }
}
