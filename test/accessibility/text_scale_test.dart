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
import 'package:calculator/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// SPEC §7: "supports text scale up to 1.3 without overflow."
///
/// Every screen is pumped at 1.3× on the 390×844 design surface and the test
/// fails on any Flutter error, which includes a RenderFlex overflow. The pages
/// that use a scrolling sheet build all their children, so an overflow below
/// the fold is caught too. The bundled Ubuntu fonts are loaded first so the
/// widths match a real phone instead of the test-only Ahem glyphs.
void main() {
  setUpAll(() async {
    final FontLoader loader = FontLoader('Ubuntu');
    for (final String weight in <String>['Regular', 'Medium', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/Ubuntu-$weight.ttf'));
    }
    await loader.load();
  });

  Widget app(Widget home) => ProviderScope(
    overrides: [kvStoreProvider.overrideWithValue(MemoryKvStore())],
    child: MaterialApp(
      theme: AppTheme.light(),
      builder: (BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.3)),
        child: child!,
      ),
      home: home,
    ),
  );

  Future<void> pumpAt13(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(home));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets('the shell with the basic calculator fits 1.3x', (tester) async {
    await pumpAt13(tester, const ShellPage());
  });

  testWidgets('the scientific calculator fits 1.3x', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(const CalculatorPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scientific'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the programmer calculator fits 1.3x', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(const CalculatorPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Programmer'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the converter hub fits 1.3x', (tester) async {
    await pumpAt13(tester, const ConverterHubPage());
  });

  testWidgets('the tools hub fits 1.3x', (tester) async {
    await pumpAt13(tester, const ToolsHubPage());
  });

  testWidgets('history and memory fit 1.3x', (tester) async {
    await pumpAt13(tester, const HistoryPage());
    await tester.tap(find.text('Memory'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings fits 1.3x', (tester) async {
    await pumpAt13(tester, const SettingsPage());
  });

  testWidgets('currency fits 1.3x', (tester) async {
    await pumpAt13(tester, const CurrencyPage());
  });

  testWidgets('the unit converter fits 1.3x', (tester) async {
    await pumpAt13(tester, const ConverterPage(category: UnitCategory.length));
  });

  testWidgets('the loan page fits 1.3x', (tester) async {
    await pumpAt13(tester, const LoanPage());
  });

  testWidgets('the percentage page fits 1.3x', (tester) async {
    await pumpAt13(tester, const PercentagePage());
  });

  testWidgets('the discount page fits 1.3x', (tester) async {
    await pumpAt13(tester, const DiscountPage());
  });

  testWidgets('the tip page fits 1.3x', (tester) async {
    await pumpAt13(tester, const TipPage());
  });

  testWidgets('the age page fits 1.3x', (tester) async {
    await pumpAt13(tester, AgePage(today: DateTime.utc(2026, 10, 28)));
  });

  testWidgets('the date difference page fits 1.3x', (tester) async {
    await pumpAt13(
      tester,
      DateDifferencePage(today: DateTime.utc(2026, 10, 28)),
    );
  });

  testWidgets('the BMI page fits 1.3x', (tester) async {
    await pumpAt13(tester, const BmiPage());
  });

  testWidgets('the GPA page fits 1.3x', (tester) async {
    await pumpAt13(tester, const GpaPage());
  });

  testWidgets('the equation page fits 1.3x', (tester) async {
    await pumpAt13(tester, const EquationPage());
  });

  testWidgets('the statistics page fits 1.3x', (tester) async {
    await pumpAt13(tester, const StatisticsPage());
  });
}
