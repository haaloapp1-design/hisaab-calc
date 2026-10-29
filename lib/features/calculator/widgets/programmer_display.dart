import 'package:flutter/material.dart';

import '../../../core/engine/formatter.dart';
import '../../../core/programmer/base_format.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';
import '../prog_state.dart';
import 'programmer_rows.dart';

/// How much of the Programmer display fits above the keypad.
///
/// [full] is screen 03 plus the expression line. Phones with less room
/// (a status bar and the shell's bottom nav eat ~80 dp of the 844 dp design)
/// drop the big value — the active base row already shows it on a white
/// pill — and put the expression next to the word-size chip. [tight] also
/// shrinks the base rows so 360×772 dp phones fit without scrolling.
enum ProgrammerDensity { full, condensed, tight }

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
    this.density = ProgrammerDensity.full,
  });

  final ProgState state;

  /// Settings separators; only the DEC row groups digits (§8.4).
  final NumberFormatOptions options;

  final ValueChanged<NumberBase> onBaseSelected;
  final VoidCallback onWordSizeTap;
  final ProgrammerDensity density;

  static double _line(TextStyle style) => style.fontSize! * style.height!;

  /// The height each density needs, from the same tokens the layout uses.
  static double heightFor(ProgrammerDensity density) {
    final double expression = _line(AppTypography.programmerExpression);
    final double chip =
        expression + 2 * AppSizes.chipPaddingV + 2 * AppSizes.borderWidth;
    final double header = chip > expression ? chip : expression;
    final double rowText =
        _line(AppTypography.baseRowValue) > _line(AppTypography.baseRowName)
        ? _line(AppTypography.baseRowValue)
        : _line(AppTypography.baseRowName);
    double rows(double paddingV, double spacing) =>
        4 * (rowText + 2 * paddingV) + 3 * spacing;
    return switch (density) {
      ProgrammerDensity.full =>
        expression +
            AppSizes.programmerDisplayGap +
            _line(AppTypography.programmerValue) +
            AppSizes.programmerDisplayGap +
            rows(AppSizes.baseRowPaddingV, AppSizes.programmerDisplayGap) +
            AppSizes.programmerDisplayBottom,
      ProgrammerDensity.condensed =>
        header +
            AppSizes.programmerDisplayGap +
            rows(AppSizes.baseRowPaddingV, AppSizes.programmerDisplayGap) +
            AppSizes.programmerDisplayBottom,
      ProgrammerDensity.tight =>
        header +
            AppSizes.programmerDisplayGapTight +
            rows(AppSizes.baseRowPaddingVTight, AppSizes.baseRowSpacingTight) +
            AppSizes.programmerDisplayBottomTight,
    };
  }

  /// The roomiest density that fits [available] dp of height.
  static ProgrammerDensity densityFor(double available) {
    for (final ProgrammerDensity density in ProgrammerDensity.values) {
      if (available >= heightFor(density)) return density;
    }
    return ProgrammerDensity.tight;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool binary = state.base == NumberBase.bin;
    final TextStyle valueStyle = binary
        ? AppTypography.programmerValueBinary
        : AppTypography.programmerValue;
    final bool full = density == ProgrammerDensity.full;
    final bool tight = density == ProgrammerDensity.tight;
    final double gap = tight
        ? AppSizes.programmerDisplayGapTight
        : AppSizes.programmerDisplayGap;
    final double rowSpacing = tight
        ? AppSizes.baseRowSpacingTight
        : AppSizes.programmerDisplayGap;

    final Widget expression = Text(
      state.expression,
      key: const Key('programmer-expression'),
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.right,
      style: AppTypography.programmerExpression.copyWith(
        color: palette.onPrimaryMuted,
      ),
    );
    final Widget chip = WordSizeChip(
      label: state.size.label,
      onTap: onWordSizeTap,
    );

    return Padding(
      key: const Key('programmer-display'),
      padding: EdgeInsets.fromLTRB(
        AppSizes.programmerDisplaySide,
        0,
        AppSizes.programmerDisplaySide,
        tight
            ? AppSizes.programmerDisplayBottomTight
            : AppSizes.programmerDisplayBottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (full) ...<Widget>[
            expression,
            SizedBox(height: gap),
            Row(
              children: <Widget>[
                chip,
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
          ] else
            // No big value: an error takes the expression's place.
            Row(
              children: <Widget>[
                chip,
                const SizedBox(width: AppSizes.displayGap),
                Expanded(
                  child: state.error == null
                      ? expression
                      : Semantics(
                          liveRegion: true,
                          child: Text(
                            state.error!.displayText,
                            key: const Key('programmer-error'),
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: AppTypography.programmerExpression.copyWith(
                              color: palette.warning,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          SizedBox(height: gap),
          for (final NumberBase base in NumberBase.values) ...<Widget>[
            BaseRow(
              base: base,
              value: formatBaseValue(state.value, base, options: options),
              selected: base == state.base,
              // Without the big line, the active row announces the result.
              live: !full && base == state.base,
              paddingV: tight
                  ? AppSizes.baseRowPaddingVTight
                  : AppSizes.baseRowPaddingV,
              onTap: () => onBaseSelected(base),
            ),
            if (base != NumberBase.values.last) SizedBox(height: rowSpacing),
          ],
        ],
      ),
    );
  }
}
