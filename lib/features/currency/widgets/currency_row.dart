import 'package:flutter/material.dart';

import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';
import '../currency_readout.dart';

/// One target currency on the white sheet of screen 08.
///
/// Tapping changes the currency; a long press opens the change / move / remove
/// actions so the list can be rearranged without hidden gestures.
class CurrencyRow extends StatelessWidget {
  const CurrencyRow({
    super.key,
    required this.row,
    required this.onTap,
    required this.onLongPress,
  });

  final CurrencyRowReadout row;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final BorderRadius radius = BorderRadius.circular(
      AppSizes.currencyRowRadius,
    );

    return Material(
      color: palette.keyNumberScientific,
      borderRadius: radius,
      child: InkWell(
        key: Key('currency-row-${row.currency.code}'),
        borderRadius: radius,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.currencyRowPaddingH,
            vertical: AppSizes.currencyRowPaddingV,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: palette.keyNumberBorder,
              width: AppSizes.borderWidth,
            ),
            borderRadius: radius,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: AppSizes.currencyCodeWidth,
                height: AppSizes.currencyCodeHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.keyOperator,
                  borderRadius: BorderRadius.circular(
                    AppSizes.currencyCodeRadius,
                  ),
                ),
                child: Text(
                  row.currency.code,
                  style: AppTypography.currencyCode.copyWith(
                    color: palette.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.currencyRowGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      row.currency.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.currencyName.copyWith(
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: AppSizes.currencyRowContentGap),
                    Text(
                      row.rate,
                      key: Key('currency-rate-${row.currency.code}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.currencyRate.copyWith(
                        color: palette.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.currencyRowGap),
              Flexible(
                child: Text(
                  row.value,
                  key: Key('currency-value-${row.currency.code}'),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.currencyValue.copyWith(
                    color: palette.ink,
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
