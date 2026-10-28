import 'package:flutter/material.dart';

import '../../core/tools/tool_catalog.dart';
import '../../shared/widgets/blue_header.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_tokens.dart';
import 'pages/age_page.dart';
import 'pages/bmi_page.dart';
import 'pages/date_difference_page.dart';
import 'pages/discount_page.dart';
import 'pages/equation_page.dart';
import 'pages/gpa_page.dart';
import 'pages/loan_page.dart';
import 'pages/percentage_page.dart';
import 'pages/statistics_page.dart';
import 'pages/tip_page.dart';
import 'pages/tool_placeholder_page.dart';
import 'widgets/tool_grid.dart';

/// The Tools tab: ten ready-made calculators (SPEC §6, screen 09).
///
/// The grid is pure catalog data. A tile opens its tool page unless the caller
/// supplies [onToolSelected], which the tests and the shell use to override the
/// route.
class ToolsHubPage extends StatelessWidget {
  const ToolsHubPage({super.key, this.onToolSelected});

  final ValueChanged<Tool>? onToolSelected;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return ColoredBox(
      color: palette.primary,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            BlueHeader(
              title: 'Tools',
              subtitle: 'Ready-made calculators for everyday sums',
              large: true,
              rounded: true,
              bottomPadding: AppSizes.toolsHeaderPaddingBottom,
            ),
            Expanded(
              child: ColoredBox(
                color: palette.background,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.screenPadding,
                    AppSizes.toolsContentPaddingTop,
                    AppSizes.screenPadding,
                    AppSizes.toolsContentPaddingBottom,
                  ),
                  child: ToolGrid(
                    onSelected: (Tool tool) => _openTool(context, tool),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTool(BuildContext context, Tool tool) {
    final ValueChanged<Tool>? callback = onToolSelected;
    if (callback != null) {
      callback(tool);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => switch (tool.id) {
          'loan' => const LoanPage(),
          'percentage' => const PercentagePage(),
          'discount' => const DiscountPage(),
          'tip' => const TipPage(),
          'age' => const AgePage(),
          'date-diff' => const DateDifferencePage(),
          'bmi' => const BmiPage(),
          'gpa' => const GpaPage(),
          'equation' => const EquationPage(),
          'statistics' => const StatisticsPage(),
          _ => ToolPlaceholderPage(tool: tool),
        },
      ),
    );
  }
}
