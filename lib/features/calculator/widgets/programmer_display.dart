import 'package:flutter/material.dart';

import '../../../core/engine/formatter.dart';
import '../../../core/programmer/base_format.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';
import '../prog_state.dart';

/// The Programmer blue area (SPEC §1.4, `03-programmer.html`).
///
/// From top: the typed expression (SPEC §1.1 applies to all three calculator
/// modes, though screen 03 does not draw the line), the word-size chip with the
/// big value in the active base, then the HEX/DEC/OCT/BIN rows. Tapping a row
/// switches the input base; tapping the chip offers the word widths.
class ProgrammerDisplay extends StatelessWidget {
  const ProgrammerDisplay({
    super.key,
    required this.state,
    this.options = const NumberFormatOptions(),
    required this.onBaseSelected,
    required this.onWordSizeTap,
  });

  final ProgState state;

  /// Settings separators; only the DEC row groups digits (§8.4).
  final NumberFormatOptions options;

  final ValueChanged<NumberBase> onBaseSelected;
  final VoidCallback onWordSizeTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool binary = state.base == NumberBase.bin;
    final TextStyle valueStyle = binary
        ? AppTypography.programmerValueBinary
        : AppTypography.programmerValue;

    return Padding(
      key: const Key('programmer-display'),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.programmerDisplaySide,
        0,
        AppSizes.programmerDisplaySide,
        AppSizes.programmerDisplayBottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            state.expression,
            key: const Key('programmer-expression'),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: AppTypography.programmerExpression.copyWith(
              color: palette.onPrimaryMuted,
            ),
          ),
          const SizedBox(height: AppSizes.programmerDisplayGap),
          Row(
            children: <Widget>[
              _WordSizeChip(label: state.size.label, onTap: onWordSizeTap),
              const SizedBox(width: AppSizes.displayGap),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      state.error?.displayText ??
                          formatBaseValue(
                            state.value,
                            state.base,
                            options: options,
                          ),
                      key: const Key('programmer-value'),
                      maxLines: 1,
                      softWrap: false,
                      style: valueStyle.copyWith(
                        color: state.error != null
                            ? palette.warning
                            : (state.preview
                                  ? palette.onPrimaryMuted
                                  : palette.onPrimary),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.programmerDisplayGap),
          for (final NumberBase base in NumberBase.values) ...<Widget>[
            _BaseRow(
              base: base,
              value: formatBaseValue(state.value, base, options: options),
              selected: base == state.base,
              onTap: () => onBaseSelected(base),
            ),
            if (base != NumberBase.values.last)
              const SizedBox(height: AppSizes.programmerDisplayGap),
          ],
        ],
      ),
    );
  }
}

/// The `32-bit` chip: 13 px faint text on a 1 px border, radius 10.
class _WordSizeChip extends StatelessWidget {
  const _WordSizeChip({required this.label, required this.onTap});

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
class _BaseRow extends StatelessWidget {
  const _BaseRow({
    required this.base,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final NumberBase base;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    // The design's inactive row text is #E4E9FF, the same value as the
    // segmented control's inactive label.
    final Color colour = selected ? palette.primary : palette.segmentedInactive;

    return Semantics(
      button: true,
      selected: selected,
      label: '${base.label} base',
      child: GestureDetector(
        key: Key('base-${base.name}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.baseRowPaddingV,
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
