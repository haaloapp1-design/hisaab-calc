import 'package:flutter/material.dart';

import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// A row of equal-width choice chips for a tool page.
///
/// It uses the screen-10 rate-chip look: a filled primary pill for the picked
/// option and a tinted outline for the others. The caller owns the index.
class ToolChoiceChips extends StatelessWidget {
  const ToolChoiceChips({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.keyPrefix = 'tool-choice',
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// The test key prefix; each chip is `Key('$keyPrefix-$index')`.
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (int i = 0; i < labels.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: AppSizes.toolRateChipGap),
          Expanded(
            child: _ChoiceChip(
              label: labels[i],
              selected: i == selectedIndex,
              onTap: () => onSelected(i),
              chipKey: Key('$keyPrefix-$i'),
            ),
          ),
        ],
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.chipKey,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Key chipKey;

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
            key: chipKey,
            borderRadius: radius,
            onTap: onTap,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6),
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
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.toolRateChip.copyWith(
                  color: selected ? palette.onPrimary : palette.primaryText,
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
