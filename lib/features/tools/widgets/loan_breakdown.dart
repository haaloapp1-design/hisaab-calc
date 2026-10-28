import 'package:flutter/material.dart';

import '../../../core/engine/formatter.dart';
import '../../../core/tools/loan.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// The principal / interest bar and the three money rows on screen 10.
///
/// The bar's filled part is [LoanResult.principalShare]; the rest is the
/// interest tint. Every value is formatted here from the unrounded engine
/// result, so the page never does arithmetic.
class LoanBreakdown extends StatelessWidget {
  const LoanBreakdown({super.key, required this.result, required this.options});

  final LoanResult result;
  final NumberFormatOptions options;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final double share = result.principalShare.toDouble().clamp(0, 1);

    return Container(
      key: const Key('loan-breakdown'),
      padding: const EdgeInsets.all(AppSizes.toolBreakdownPadding),
      decoration: BoxDecoration(
        border: Border.all(
          color: palette.keyNumberBorder,
          width: AppSizes.borderWidth,
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _ShareBar(share: share),
          const SizedBox(height: AppSizes.toolBreakdownGap),
          _BreakdownRow(
            colour: palette.primary,
            label: 'Principal',
            value: formatLoanMoney(result.principal, options: options),
          ),
          const SizedBox(height: AppSizes.toolBreakdownGap),
          _BreakdownRow(
            colour: palette.warning,
            label: 'Total interest',
            value: formatLoanMoney(result.totalInterest, options: options),
          ),
          const SizedBox(height: AppSizes.toolBreakdownGap),
          Container(
            padding: const EdgeInsets.only(top: AppSizes.toolTotalPaddingTop),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: palette.divider,
                  width: AppSizes.borderWidth,
                ),
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Total payable',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.toolBreakdownTotal.copyWith(
                      color: palette.ink,
                    ),
                  ),
                ),
                Text(
                  formatLoanMoney(result.totalPayable, options: options),
                  key: const Key('loan-total-payable'),
                  style: AppTypography.toolBreakdownTotal.copyWith(
                    color: palette.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The 12 px track: interest behind, principal filled from the left.
class _ShareBar extends StatelessWidget {
  const _ShareBar({required this.share});

  final double share;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return ClipRRect(
      key: const Key('loan-bar'),
      borderRadius: BorderRadius.circular(AppSizes.toolBarRadius),
      child: SizedBox(
        height: AppSizes.toolBarHeight,
        child: ColoredBox(
          color: palette.warning,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              key: const Key('loan-bar-principal'),
              widthFactor: share,
              heightFactor: 1,
              child: ColoredBox(color: palette.primary),
            ),
          ),
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.colour,
    required this.label,
    required this.value,
  });

  final Color colour;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Row(
      children: <Widget>[
        Container(
          width: AppSizes.toolLegendSize,
          height: AppSizes.toolLegendSize,
          decoration: BoxDecoration(
            color: colour,
            borderRadius: BorderRadius.circular(AppSizes.toolLegendRadius),
          ),
        ),
        const SizedBox(width: AppSizes.toolLegendGap),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.toolBreakdownRow.copyWith(color: palette.ink),
          ),
        ),
        Text(
          value,
          style: AppTypography.toolBreakdownRow.copyWith(color: palette.ink),
        ),
      ],
    );
  }
}
