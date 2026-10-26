import 'package:flutter/material.dart';

import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';
import '../currency_readout.dart';

/// The blue top area of screen 08: base pill, amount, rule and status line.
class CurrencyTop extends StatelessWidget {
  const CurrencyTop({
    super.key,
    required this.readout,
    required this.amountField,
    required this.onPickBase,
  });

  final CurrencyReadout readout;
  final Widget amountField;
  final VoidCallback onPickBase;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.currencyTopPaddingSide,
        AppSizes.currencyTopPaddingTop,
        AppSizes.currencyTopPaddingSide,
        AppSizes.currencyTopPaddingBottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Material(
                color: palette.sheet,
                borderRadius: BorderRadius.circular(
                  AppSizes.currencyBasePillRadius,
                ),
                child: InkWell(
                  key: const Key('currency-base'),
                  borderRadius: BorderRadius.circular(
                    AppSizes.currencyBasePillRadius,
                  ),
                  onTap: onPickBase,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.currencyBasePillPaddingH,
                      vertical: AppSizes.currencyBasePillPaddingV,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          readout.base,
                          style: AppTypography.currencyBaseCode.copyWith(
                            color: palette.primary,
                          ),
                        ),
                        const SizedBox(width: AppSizes.currencyBasePillGap),
                        Icon(
                          Icons.expand_more_rounded,
                          size: AppSizes.currencyBaseArrow,
                          color: palette.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.currencyTopGap),
              Expanded(
                child: Text(
                  readout.baseName,
                  key: const Key('currency-base-name'),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.currencyBaseName.copyWith(
                    color: palette.onPrimaryMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.currencyTopGap),
          amountField,
          const SizedBox(height: AppSizes.currencyTopGap),
          Container(
            height: AppSizes.borderWidth,
            color: palette.dividerOnPrimary,
          ),
          const SizedBox(height: AppSizes.currencyTopGap),
          Row(
            children: <Widget>[
              Container(
                key: const Key('currency-status-dot'),
                width: AppSizes.currencyStatusDot,
                height: AppSizes.currencyStatusDot,
                decoration: BoxDecoration(
                  color: readout.isLive ? palette.onPrimary : palette.warning,
                  borderRadius: BorderRadius.circular(
                    AppSizes.currencyStatusDot / 2,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.currencyStatusGap),
              Expanded(
                child: Text(
                  readout.statusText,
                  key: const Key('currency-status'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.currencyStatus.copyWith(
                    color: palette.onPrimaryMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
