import 'package:flutter/material.dart';

import '../../../core/programmer/base_format.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// The `32-bit` chip: 13 px faint text on a 1 px border, radius 10.
class WordSizeChip extends StatelessWidget {
  const WordSizeChip({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Semantics(
      button: true,
      label: 'Word size $label',
      child: GestureDetector(
        key: const Key('word-size-chip'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.chipPaddingV,
            horizontal: AppSizes.chipPaddingH,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.chip),
            border: Border.all(
              color: palette.dividerOnPrimary,
              width: AppSizes.borderWidth,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            style: AppTypography.programmerExpression.copyWith(
              color: palette.onPrimaryFaint,
            ),
          ),
        ),
      ),
    );
  }
}

/// One HEX/DEC/OCT/BIN row: white pill when it is the input base.
class BaseRow extends StatelessWidget {
  const BaseRow({
    super.key,
    required this.base,
    required this.value,
    required this.selected,
    required this.onTap,
    this.live = false,
    this.paddingV = AppSizes.baseRowPaddingV,
  });

  final NumberBase base;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  final bool live;
  final double paddingV;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    // The design's inactive row text is #E4E9FF, the same value as the
    // segmented control's inactive label.
    final Color colour = selected
        ? palette.primaryText
        : palette.segmentedInactive;

    return Semantics(
      button: true,
      selected: selected,
      liveRegion: live,
      label: '${base.label} base',
      child: GestureDetector(
        key: Key('base-${base.name}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: paddingV,
            horizontal: AppSizes.baseRowPaddingH,
          ),
          decoration: BoxDecoration(
            color: selected ? palette.sheet : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.chip),
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: AppSizes.baseRowNameWidth,
                child: Text(
                  base.label,
                  key: Key('base-name-${base.name}'),
                  maxLines: 1,
                  style: AppTypography.baseRowName.copyWith(color: colour),
                ),
              ),
              const SizedBox(width: AppSizes.baseRowGap),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  // The low bits matter most, so keep the end in view.
                  reverse: true,
                  child: Text(
                    value,
                    key: Key('base-value-${base.name}'),
                    maxLines: 1,
                    softWrap: false,
                    style: AppTypography.baseRowValue.copyWith(color: colour),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
