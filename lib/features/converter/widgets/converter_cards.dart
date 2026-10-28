import 'package:flutter/material.dart';

import '../../../core/units/unit_catalog.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// The From card, swap button, To card and rule line (screen 07).
///
/// The two cards have the same height, so the swap button centred on the
/// [Stack] sits exactly in the 12 px gap between them.
class ConverterCards extends StatelessWidget {
  const ConverterCards({
    super.key,
    required this.from,
    required this.to,
    required this.fromText,
    required this.toText,
    required this.toIsError,
    required this.rule,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onSwap,
  });

  final Unit from;
  final Unit to;
  final String fromText;
  final String toText;

  /// The To value is an error message (`Below absolute zero`).
  final bool toIsError;

  final String rule;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.converterCardsTopGap,
        AppSizes.screenPadding,
        0,
      ),
      child: Column(
        children: <Widget>[
          Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Column(
                children: <Widget>[
                  _UnitCard(
                    unit: from,
                    value: fromText,
                    onPrimary: false,
                    cardKey: const Key('converter-from-card'),
                    pickerKey: const Key('converter-from-unit'),
                    valueKey: const Key('converter-from-value'),
                    onPick: onPickFrom,
                  ),
                  const SizedBox(height: AppSizes.converterCardGap),
                  _UnitCard(
                    unit: to,
                    value: toText,
                    onPrimary: true,
                    isError: toIsError,
                    cardKey: const Key('converter-to-card'),
                    pickerKey: const Key('converter-to-unit'),
                    valueKey: const Key('converter-to-value'),
                    onPick: onPickTo,
                  ),
                ],
              ),
              _SwapButton(onTap: onSwap),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.converterRulePaddingH,
              AppSizes.converterRulePaddingTop,
              AppSizes.converterRulePaddingH,
              0,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                rule,
                key: const Key('converter-rule'),
                style: AppTypography.small.copyWith(
                  color: palette.onPrimaryMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.unit,
    required this.value,
    required this.onPrimary,
    required this.cardKey,
    required this.pickerKey,
    required this.valueKey,
    required this.onPick,
    this.isError = false,
  });

  final Unit unit;
  final String value;
  final bool onPrimary;
  final bool isError;
  final Key cardKey;
  final Key pickerKey;
  final Key valueKey;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final BorderRadius radius = BorderRadius.circular(AppRadii.cardLarge);
    final BorderRadius cardRadius = radius;

    return Container(
      key: cardKey,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.converterCardPaddingH,
        vertical: AppSizes.converterCardPaddingV,
      ),
      decoration: BoxDecoration(
        color: onPrimary ? palette.primaryTrack : palette.sheet,
        borderRadius: cardRadius,
      ),
      foregroundDecoration: onPrimary
          ? null
          : BoxDecoration(
              borderRadius: cardRadius,
              border: Border.all(
                color: palette.converterCardBorder,
                width: AppSizes.converterCardBorderWidth,
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              button: true,
              label: 'Change ${onPrimary ? 'to' : 'from'} unit, ${unit.label}',
              onTap: onPick,
              excludeSemantics: true,
              child: Material(
                color: onPrimary ? palette.sheet : palette.keyFunction,
                borderRadius: BorderRadius.circular(AppRadii.chip),
                child: InkWell(
                  key: pickerKey,
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                  onTap: onPick,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.converterUnitPillPaddingH,
                      vertical: AppSizes.converterUnitPillPaddingV,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            unit.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.converterUnitPill.copyWith(
                              color: palette.primaryText,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.converterUnitPillGap),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: AppSizes.converterUnitPillIcon,
                          color: palette.primaryText,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.converterCardContentGap),
          SizedBox(
            height: AppSizes.converterValueHeight,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  value,
                  key: valueKey,
                  maxLines: 1,
                  style:
                      (isError
                              ? AppTypography.converterError
                              : AppTypography.converterValue)
                          .copyWith(
                            color: onPrimary ? palette.onPrimary : palette.ink,
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwapButton extends StatelessWidget {
  const _SwapButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    const CircleBorder shape = CircleBorder();

    return Semantics(
      button: true,
      label: 'Swap units',
      onTap: onTap,
      excludeSemantics: true,
      child: SizedBox(
        width: AppSizes.converterSwapSize,
        height: AppSizes.converterSwapSize,
        child: Material(
          color: palette.sheet,
          shape: shape.copyWith(
            side: BorderSide(
              color: palette.primaryText,
              width: AppSizes.converterSwapBorder,
            ),
          ),
          child: InkWell(
            key: const Key('converter-swap'),
            customBorder: shape,
            onTap: onTap,
            child: Icon(
              Icons.swap_vert_rounded,
              size: AppSizes.converterSwapIcon,
              color: palette.primaryText,
            ),
          ),
        ),
      ),
    );
  }
}
