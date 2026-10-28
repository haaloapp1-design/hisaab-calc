import 'package:flutter/material.dart';

import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// The annual-rate choices on screen 10.
///
/// The design offers three fixed rates; the selected one is a filled primary
/// pill and the others are the tinted outline. The page keeps the picked rate
/// and recalculates.
class LoanRateChips extends StatelessWidget {
  const LoanRateChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  /// The rates the screen offers, in order.
  static const List<int> options = <int>[10, 12, 14];

  /// The current annual percentage.
  final int selected;

  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Interest rate per year',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.toolFieldLabel.copyWith(color: palette.inkMuted),
        ),
        const SizedBox(height: AppSizes.toolLabelGap),
        Row(
          children: <Widget>[
            for (int i = 0; i < options.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: AppSizes.toolRateChipGap),
              Expanded(
                child: _RateChip(
                  rate: options[i],
                  selected: options[i] == selected,
                  onTap: () => onSelected(options[i]),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _RateChip extends StatelessWidget {
  const _RateChip({
    required this.rate,
    required this.selected,
    required this.onTap,
  });

  final int rate;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final BorderRadius radius = BorderRadius.circular(AppRadii.toolRateChip);

    return Semantics(
      selected: selected,
      button: true,
      child: SizedBox(
        height: AppSizes.toolRateChipHeight,
        child: Material(
          color: selected ? palette.primary : palette.keyNumber,
          borderRadius: radius,
          child: InkWell(
            key: Key('loan-rate-$rate'),
            borderRadius: radius,
            onTap: onTap,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: radius,
                border: selected
                    ? null
                    : Border.all(
                        color: palette.keyOperatorBorder,
                        width: AppSizes.borderWidth,
                      ),
              ),
              child: Text(
                '$rate%',
                style: AppTypography.toolRateChip.copyWith(
                  color: selected ? palette.onPrimary : palette.primary,
                  fontWeight: selected
                      ? AppTypography.bold
                      : AppTypography.regular,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
