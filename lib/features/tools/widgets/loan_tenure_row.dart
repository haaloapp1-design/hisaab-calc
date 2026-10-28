import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';
import 'tool_field.dart';

/// The unit the tenure field is counted in (screen 10).
///
/// The number stays the same when the unit changes; only its meaning does, so
/// `5` years becomes `5` months after tapping Months.
enum LoanTenureUnit {
  years,
  months;

  /// The label in the Years / Months toggle.
  String get label => switch (this) {
    LoanTenureUnit.years => 'Years',
    LoanTenureUnit.months => 'Months',
  };

  /// Converts [value] of this unit to the months the engine expects.
  int toMonths(int value) => switch (this) {
    LoanTenureUnit.years => value * 12,
    LoanTenureUnit.months => value,
  };

  /// The most digits the tenure field accepts for this unit.
  int get maxDigits => switch (this) {
    LoanTenureUnit.years => 2,
    LoanTenureUnit.months => 3,
  };
}

/// The tenure input and its Years / Months toggle.
///
/// The left half is the 50 px number field, the right half is the 50 px
/// segmented track with the same 14 px radius and 3 px padding as the design.
class LoanTenureRow extends StatelessWidget {
  const LoanTenureRow({
    super.key,
    required this.controller,
    required this.unit,
    required this.onChanged,
    required this.onUnitChanged,
  });

  final TextEditingController controller;
  final LoanTenureUnit unit;
  final ValueChanged<String> onChanged;
  final ValueChanged<LoanTenureUnit> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: ToolField(
            label: 'Tenure',
            child: ToolFieldBox(
              child: ToolTextField(
                fieldKey: const Key('loan-tenure'),
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(unit.maxDigits),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.toolTenureGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'In',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.toolFieldLabel.copyWith(
                  color: AppPalette.of(context).inkMuted,
                ),
              ),
              const SizedBox(height: AppSizes.toolLabelGap),
              _UnitToggle(unit: unit, onChanged: onUnitChanged),
            ],
          ),
        ),
      ],
    );
  }
}

class _UnitToggle extends StatelessWidget {
  const _UnitToggle({required this.unit, required this.onChanged});

  final LoanTenureUnit unit;
  final ValueChanged<LoanTenureUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Container(
      height: AppSizes.toolFieldHeight,
      padding: const EdgeInsets.all(AppSizes.toolSegmentPadding),
      decoration: BoxDecoration(
        color: palette.selectorTrack,
        borderRadius: BorderRadius.circular(AppRadii.toolField),
      ),
      child: Row(
        children: <Widget>[
          for (final LoanTenureUnit option in LoanTenureUnit.values)
            Expanded(
              child: _UnitPill(
                option: option,
                selected: option == unit,
                onTap: () => onChanged(option),
              ),
            ),
        ],
      ),
    );
  }
}

class _UnitPill extends StatelessWidget {
  const _UnitPill({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final LoanTenureUnit option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final BorderRadius radius = BorderRadius.circular(AppRadii.toolSegmentPill);

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? palette.sheet : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          key: Key('loan-unit-${option.name}'),
          borderRadius: radius,
          onTap: onTap,
          child: Center(
            child: Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.segmentedLabel.copyWith(
                color: selected ? palette.primary : palette.inkMuted,
                fontWeight: selected
                    ? AppTypography.bold
                    : AppTypography.regular,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
