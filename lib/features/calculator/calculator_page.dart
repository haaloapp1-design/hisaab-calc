import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/engine/formatter.dart';
import '../../shared/widgets/blue_header.dart';
import '../../shared/widgets/segmented.dart';
import '../../shared/widgets/white_sheet.dart';
import '../../theme/app_tokens.dart';
import 'calc_state.dart';
import 'calculator_controller.dart';
import 'keypads/basic_keys.dart';
import 'keypads/scientific_keys.dart';
import 'widgets/angle_controls.dart';
import 'widgets/calc_key_button.dart';
import 'widgets/display.dart';
import 'widgets/keypad.dart';

/// The Calculator tab (SPEC §1, screens 01–03).
///
/// Blue top area (header, mode switcher, display) and the white keypad sheet.
/// The page formats state values and forwards keys; it owns no maths. Basic
/// (T23) and Scientific (T24) are wired end to end; Programmer still shows the
/// Basic keys until T33.
class CalculatorPage extends ConsumerWidget {
  const CalculatorPage({super.key});

  static const List<String> _modes = <String>[
    'Basic',
    'Scientific',
    'Programmer',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CalcState calc = ref.watch(calculatorProvider);
    final CalculatorController controller = ref.read(
      calculatorProvider.notifier,
    );
    final bool scientific = calc.mode == CalcMode.scientific;

    return ColoredBox(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            BlueHeader(
              title: 'Calculator',
              actionIcon: Icons.tune_rounded,
              actionTooltip: 'Settings',
              onAction: _openSettings,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                AppSizes.segmentedTopGap,
                AppSizes.screenPadding,
                0,
              ),
              child: Segmented(
                labels: _modes,
                selectedIndex: calc.mode.index,
                onSelected: (int index) =>
                    controller.setMode(CalcMode.values[index]),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (scientific)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.displayPaddingSide,
                        0,
                        AppSizes.displayPaddingSide,
                        AppSizes.angleRowBottomGap,
                      ),
                      child: AngleControls(
                        angleMode: calc.angleMode,
                        onChanged: controller.setAngleMode,
                        openBrackets: calc.openBrackets,
                      ),
                    ),
                  Display(
                    expression: calc.justEvaluated
                        ? ''
                        : formatExpression(calc.buffer.tokens),
                    result: formatNumber(calc.displayValue),
                    preview: calc.result == null && calc.preview != null,
                    error: calc.error,
                    density: scientific
                        ? DisplayDensity.scientific
                        : DisplayDensity.basic,
                  ),
                ],
              ),
            ),
            WhiteSheet(
              padding: scientific
                  ? const EdgeInsets.fromLTRB(
                      AppSizes.sheetScientificPaddingSide,
                      AppSizes.sheetPaddingTop,
                      AppSizes.sheetScientificPaddingSide,
                      AppSizes.sheetPaddingBottom,
                    )
                  : null,
              contentGap: scientific
                  ? AppSizes.sheetScientificContentGap
                  : null,
              child: scientific
                  ? Keypad(
                      spec: scientificKeys(
                        onKey: controller.onKey,
                        second: calc.second,
                        onSecond: controller.toggleSecond,
                      ),
                      columns: 5,
                      density: CalcKeyDensity.scientific,
                    )
                  : Keypad(
                      spec: basicKeys(controller.onKey),
                      columns: 4,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// T26 pushes the Settings page.
  void _openSettings() {}
}
