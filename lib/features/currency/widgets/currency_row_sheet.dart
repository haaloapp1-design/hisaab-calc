import 'package:flutter/material.dart';

import '../../../core/currency/currency_catalog.dart';
import '../../../shared/widgets/white_sheet.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// What a long press on a currency row can do.
enum CurrencyRowAction { change, moveUp, moveDown, remove }

/// Opens the long-press actions of one target currency.
///
/// The move rows are hidden at the ends of the list, so a tap always has an
/// effect. Removing is the only danger-coloured row.
Future<CurrencyRowAction?> showCurrencyRowSheet(
  BuildContext context, {
  required Currency currency,
  required bool canMoveUp,
  required bool canMoveDown,
}) {
  return showModalBottomSheet<CurrencyRowAction>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) => WhiteSheet(
      padding: EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.sheetPaddingTop,
        AppSizes.screenPadding,
        AppSizes.converterSheetPaddingBottom +
            MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            '${currency.code} · ${currency.name}',
            style: AppTypography.hubItemTitle.copyWith(
              color: AppPalette.of(context).ink,
            ),
          ),
          const SizedBox(height: AppSizes.currencyPickerTitleGap),
          _RowAction(
            actionKey: 'currency-action-change',
            icon: Icons.swap_horiz_rounded,
            label: 'Change currency',
            onTap: () => Navigator.of(context).pop(CurrencyRowAction.change),
          ),
          if (canMoveUp)
            _RowAction(
              actionKey: 'currency-action-up',
              icon: Icons.arrow_upward_rounded,
              label: 'Move up',
              onTap: () => Navigator.of(context).pop(CurrencyRowAction.moveUp),
            ),
          if (canMoveDown)
            _RowAction(
              actionKey: 'currency-action-down',
              icon: Icons.arrow_downward_rounded,
              label: 'Move down',
              onTap: () =>
                  Navigator.of(context).pop(CurrencyRowAction.moveDown),
            ),
          _RowAction(
            actionKey: 'currency-action-remove',
            icon: Icons.delete_outline_rounded,
            label: 'Remove currency',
            danger: true,
            onTap: () => Navigator.of(context).pop(CurrencyRowAction.remove),
          ),
        ],
      ),
    ),
  );
}

class _RowAction extends StatelessWidget {
  const _RowAction({
    required this.actionKey,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final String actionKey;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Color color = danger ? palette.danger : palette.primary;

    return SizedBox(
      height: AppSizes.historyMenuRowHeight,
      child: InkWell(
        key: Key(actionKey),
        onTap: onTap,
        child: Row(
          children: <Widget>[
            Icon(icon, size: AppSizes.historyMenuIcon, color: color),
            const SizedBox(width: AppSizes.currencyRowGap),
            Expanded(
              child: Text(
                label,
                style: AppTypography.historyMenu.copyWith(
                  color: danger ? palette.danger : palette.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
