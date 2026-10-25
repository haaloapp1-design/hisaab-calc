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
import 'widgets/display.dart';
import 'widgets/keypad.dart';

/// The Calculator tab (SPEC §1, screens 01–03).
///
/// Blue top area (header, mode switcher, display) and the white keypad sheet.
/// The page formats state values and forwards keys; it owns no maths. Basic is
/// wired end to end in T23 — the Scientific (T24) and Programmer (T33) keypads
/// arrive later, so every mode currently shows the Basic keys.
class CalculatorPage extends ConsumerStatefulWidget {
  const CalculatorPage({super.key});

  @override
  ConsumerState<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends ConsumerState<CalculatorPage> {
  static const List<String> _modes = <String>[
    'Basic',
    'Scientific',
    'Programmer',
  ];

  /// T24/T33 swap the keypad per mode and persist the choice.
  int _mode = 0;

  @override
  Widget build(BuildContext context) {
    final CalcState calc = ref.watch(calculatorProvider);
    final CalculatorController controller = ref.read(
      calculatorProvider.notifier,
    );

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
                selectedIndex: _mode,
                onSelected: (int index) => setState(() => _mode = index),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Display(
                    expression: calc.justEvaluated
                        ? ''
                        : formatExpression(calc.buffer.tokens),
                    result: formatNumber(calc.displayValue),
                    preview: calc.result == null && calc.preview != null,
                    error: calc.error,
                  ),
                ],
              ),
            ),
            WhiteSheet(
              child: Keypad(spec: basicKeys(controller.onKey), columns: 4),
            ),
          ],
        ),
      ),
    );
  }

  /// T26 pushes the Settings page.
  void _openSettings() {}
}
