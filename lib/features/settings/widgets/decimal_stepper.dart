import 'package:flutter/material.dart';

import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';
import '../settings_model.dart';

/// The − / value / + control in the Decimal places row (screen 05).
///
/// [value] is null for Auto; the steps go Auto ↔ 0 ↔ … ↔ 10 without wrapping,
/// so the ends simply stop. The page persists whatever this reports.
class DecimalStepper extends StatelessWidget {
  const DecimalStepper({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int? value;
  final ValueChanged<int?> onChanged;

  /// Auto → 0, otherwise one step up, stopping at 10.
  static int? increase(int? current) {
    if (current == null) {
      return 0;
    }
    return current >= Settings.maxDecimalPlaces ? current : current + 1;
  }

  /// 0 → Auto, otherwise one step down, stopping at Auto.
  static int? decrease(int? current) {
    if (current == null) {
      return null;
    }
    return current <= 0 ? null : current - 1;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _StepButton(
          key: const Key('decimal-fewer'),
          glyph: '−',
          tooltip: 'Fewer decimal places',
          onTap: () => onChanged(decrease(value)),
        ),
        const SizedBox(width: AppSizes.stepperGap),
        SizedBox(
          width: AppSizes.stepperValueWidth,
          child: Text(
            value?.toString() ?? 'Auto',
            textAlign: TextAlign.center,
            maxLines: 1,
            style: AppTypography.body.copyWith(color: palette.ink),
          ),
        ),
        const SizedBox(width: AppSizes.stepperGap),
        _StepButton(
          key: const Key('decimal-more'),
          glyph: '+',
          tooltip: 'More decimal places',
          onTap: () => onChanged(increase(value)),
        ),
      ],
    );
  }
}

/// The 0–10 bound shared by the widget and the Settings model.
class _StepButton extends StatelessWidget {
  const _StepButton({
    super.key,
    required this.glyph,
    required this.tooltip,
    required this.onTap,
  });

  final String glyph;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: AppSizes.stepperButton,
          height: AppSizes.stepperButton,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.keyNumber,
            borderRadius: BorderRadius.circular(AppRadii.chip),
            border: Border.all(
              color: palette.keyNumberBorder,
              width: AppSizes.borderWidth,
            ),
          ),
          child: Text(
            glyph,
            style: AppTypography.stepperGlyph.copyWith(
              color: palette.primaryText,
            ),
          ),
        ),
      ),
    );
  }
}
