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
import 'package:calculator/theme/app_palette.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:calculator/theme/contrast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// T49 "every screen readable in dark".
///
/// Each screen is pumped on the 390×844 design surface with [AppTheme.dark].
/// The test then walks every painted [RichText] and checks its colour against
/// the nearest painted background, using the same WCAG AA thresholds as
/// `contrast_test.dart`: 4.5:1 for normal text and 3:1 for large text (24 px,
/// or 18.66 px bold). Disabled text is exempt, as in WCAG.
///
/// This is what catches an accent used as a foreground on a dark surface: the
/// raw cobalt accent is only 2.11:1 on the dark sheet, so any leftover
/// `palette.primary` text fails here.
void main() {
  final AppPalette palette = AppPalette.darkCobalt;

  Widget app(Widget home) => ProviderScope(
    overrides: [kvStoreProvider.overrideWithValue(MemoryKvStore())],
    child: MaterialApp(theme: AppTheme.dark(), home: home),
  );

  Future<void> pumpDark(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(home));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  /// The first opaque colour painted behind [element], or null when the tree
  /// only shows a transparent/unknown surface (those texts are skipped).
  Color? paintedBackground(Element element) {
    Color? found;
    element.visitAncestorElements((Element ancestor) {
      final Widget widget = ancestor.widget;
      Color? colour;
      if (widget is ColoredBox) {
        colour = widget.color;
      } else if (widget is DecoratedBox) {
        final Decoration decoration = widget.decoration;
        colour = decoration is BoxDecoration ? decoration.color : null;
      } else if (widget is Material) {
        colour =
            widget.color ??
            (widget.type == MaterialType.canvas
                ? Theme.of(ancestor).canvasColor
                : null);
      } else if (widget is Card) {
        colour = widget.color ?? Theme.of(ancestor).cardColor;
      } else if (widget is Ink) {
        final Decoration? decoration = widget.decoration;
        colour = decoration is BoxDecoration ? decoration.color : null;
      } else if (widget is Scaffold) {
        colour =
            widget.backgroundColor ??
            Theme.of(ancestor).scaffoldBackgroundColor;
      }
      if (colour != null && colour.a > 0.01) {
        found = colour;
        return false;
      }
      return true;
    });
    return found;
  }

  void expectReadableText(WidgetTester tester, String screen) {
    final List<String> problems = <String>[];

    for (final Element element in find.byType(RichText).evaluate()) {
      final RichText rich = element.widget as RichText;
      final TextStyle? style = rich.text.style;
      final Color? colour = style?.color;
      if (colour == null) {
        continue;
      }
      // WCAG exempts disabled controls.
      if (colour == palette.disabled || colour == palette.disabledBorder) {
        continue;
      }
      final Color? background = paintedBackground(element);
      if (background == null) {
        continue;
      }

      final Color foreground = colour.a < 1
          ? Color.alphaBlend(colour, background)
          : colour;
      final double ratio = Contrast.ratio(foreground, background);
      final double size = style?.fontSize ?? 14;
      final bool bold =
          (style?.fontWeight ?? FontWeight.normal).value >=
          FontWeight.w700.value;
      final bool large = size >= 24 || (size >= 18.66 && bold);
      final double target = large ? Contrast.largeText : Contrast.normalText;

      if (ratio < target) {
        problems.add(
          '"${rich.text.toPlainText()}" '
          '${colour.toARGB32().toRadixString(16)} on '
          '${background.toARGB32().toRadixString(16)} = '
          '${ratio.toStringAsFixed(2)}:1 (needs $target:1)',
        );
      }
    }

    expect(problems, isEmpty, reason: '$screen in dark mode');
  }

  final Map<String, Widget> screens = <String, Widget>{
    'shell': const ShellPage(),
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
    'age': AgePage(today: DateTime.utc(2026, 10, 28)),
    'date difference': DateDifferencePage(today: DateTime.utc(2026, 10, 28)),
    'BMI': const BmiPage(),
    'GPA': const GpaPage(),
    'equation': const EquationPage(),
    'statistics': const StatisticsPage(),
  };

  for (final MapEntry<String, Widget> screen in screens.entries) {
    testWidgets('the ${screen.key} screen is readable in dark', (tester) async {
      await pumpDark(tester, screen.value);
      expectReadableText(tester, screen.key);
    });
  }

  testWidgets('the scientific calculator is readable in dark', (tester) async {
    await pumpDark(tester, const CalculatorPage());
    await tester.tap(find.text('Scientific'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expectReadableText(tester, 'scientific calculator');
  });

  testWidgets('the programmer calculator is readable in dark', (tester) async {
    await pumpDark(tester, const CalculatorPage());
    await tester.tap(find.text('Programmer'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expectReadableText(tester, 'programmer calculator');
  });

  testWidgets('memory is readable in dark', (tester) async {
    await pumpDark(tester, const HistoryPage());
    await tester.tap(find.text('Memory'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expectReadableText(tester, 'memory');
  });
}
