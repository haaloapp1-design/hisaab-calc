import 'package:flutter/material.dart';

import '../../../core/engine/angle_mode.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// The DEG/RAD chip row above the scientific display, with the open-bracket
/// badge on its right (SPEC §1.3, `02-scientific.html`).
///
/// Only the visible state lives here: the page owns [angleMode] and forwards
/// taps through [onChanged]. [openBrackets] is the count still waiting for a
/// `)`; the badge is hidden when it is zero.
class AngleControls extends StatelessWidget {
  const AngleControls({
    super.key,
    required this.angleMode,
    required this.onChanged,
    this.openBrackets = 0,
  });

  final AngleMode angleMode;
  final ValueChanged<AngleMode> onChanged;
  final int openBrackets;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('angle-controls'),
      children: <Widget>[
        _AngleChip(
          key: const Key('angle-deg'),
          label: 'DEG',
          selected: angleMode.isDegrees,
          onTap: () => onChanged(AngleMode.deg),
        ),
        const SizedBox(width: AppSizes.angleChipGap),
        _AngleChip(
          key: const Key('angle-rad'),
          label: 'RAD',
          selected: !angleMode.isDegrees,
          onTap: () => onChanged(AngleMode.rad),
        ),
        if (openBrackets > 0) ...<Widget>[
          const Spacer(),
          _BracketBadge(count: openBrackets),
        ],
      ],
    );
  }
}

/// The on/off chip styles from `02-scientific.html`: selected is a white pill
/// with 13/700 primary text, unselected a transparent pill with a 1 px
/// `dividerOnPrimary` border and `onPrimaryMuted` text.
class _AngleChip extends StatelessWidget {
  const _AngleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: '$label angle unit',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.angleChipPaddingV,
            horizontal: AppSizes.angleChipPaddingH,
          ),
          decoration: BoxDecoration(
            color: selected ? palette.onPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.chip),
            border: selected
                ? null
                : Border.all(
                    color: palette.dividerOnPrimary,
                    width: AppSizes.borderWidth,
                  ),
          ),
          child: Text(
            label,
            maxLines: 1,
            style: AppTypography.small.copyWith(
              color: selected ? palette.primary : palette.onPrimaryMuted,
              fontWeight: selected
                  ? AppTypography.bold
                  : AppTypography.regular,
            ),
          ),
        ),
      ),
    );
  }
}

/// SPEC §1.3 "open bracket count shown as a small badge": the same chip
/// surface as an unselected DEG/RAD chip, reading `(2` for two open brackets.
class _BracketBadge extends StatelessWidget {
  const _BracketBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Semantics(
      label: '$count open brackets',
      excludeSemantics: true,
      child: Container(
        key: const Key('bracket-badge'),
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.angleChipPaddingV,
          horizontal: AppSizes.angleChipPaddingH,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.chip),
          border: Border.all(
            color: palette.dividerOnPrimary,
            width: AppSizes.borderWidth,
          ),
        ),
        child: Text(
          '($count',
          maxLines: 1,
          style: AppTypography.small.copyWith(
            color: palette.onPrimaryMuted,
          ),
        ),
      ),
    );
  }
}
