import 'package:flutter/material.dart';

import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// The white "Currency" card at the top of the converter hub (screen 06).
class CurrencyCard extends StatelessWidget {
  const CurrencyCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final BorderRadius radius = BorderRadius.circular(AppRadii.cardLarge);

    return Material(
      color: palette.sheet,
      borderRadius: radius,
      child: InkWell(
        key: const Key('hub-currency-card'),
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.hubCurrencyPaddingH,
            vertical: AppSizes.hubCurrencyPaddingV,
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
                key: const Key('hub-currency-icon'),
                width: AppSizes.hubCurrencyIcon,
                height: AppSizes.hubCurrencyIcon,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.primary,
                  borderRadius: BorderRadius.circular(
                    AppSizes.hubCurrencyIconRadius,
                  ),
                ),
                child: Text(
                  r'$',
                  style: AppTypography.hubCurrencyGlyph.copyWith(
                    color: palette.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.hubCurrencyGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Currency',
                      style: AppTypography.hubItemTitle.copyWith(
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: AppSizes.hubResultGap),
                    Text(
                      'Live rates, works offline with last saved rates',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.small.copyWith(
                        color: palette.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: AppSizes.hubCurrencyChevron,
                color: palette.primaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
