import 'package:flutter/material.dart';

import '../../../shared/widgets/white_sheet.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';
import '../history_entry.dart';

/// The long-press sheet of one history entry (SPEC §2: copy / delete).
///
/// It repeats the row's expression and result and offers the two actions as
/// full-width rows, so a long press never deletes anything without a tap.
class HistoryEntrySheet extends StatelessWidget {
  const HistoryEntrySheet({
    super.key,
    required this.entry,
    required this.onCopy,
    required this.onDelete,
  });

  final HistoryEntry entry;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return WhiteSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            entry.expression,
            textAlign: TextAlign.right,
            style: AppTypography.historyExpression.copyWith(
              color: palette.inkMuted,
            ),
          ),
          const SizedBox(height: AppSizes.historyEntryGap),
          Text(
            entry.result,
            textAlign: TextAlign.right,
            style: AppTypography.historyResult.copyWith(color: palette.ink),
          ),
          const SizedBox(height: AppSizes.sheetContentGap),
          _SheetAction(
            actionKey: const Key('history-entry-copy'),
            icon: Icons.copy_rounded,
            label: 'Copy',
            onTap: onCopy,
          ),
          Divider(
            height: AppSizes.borderWidth,
            thickness: AppSizes.borderWidth,
            color: palette.divider,
          ),
          _SheetAction(
            actionKey: const Key('history-entry-delete'),
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            danger: true,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.actionKey,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final Key actionKey;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Color colour = danger ? palette.danger : palette.ink;

    return Semantics(
      button: true,
      child: GestureDetector(
        key: actionKey,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: AppSizes.historyMenuRowHeight,
          child: Row(
            children: <Widget>[
              Icon(icon, size: AppSizes.historyMenuIcon, color: colour),
              const SizedBox(width: AppSizes.historyActionGap),
              Text(
                label,
                style: AppTypography.historyMenu.copyWith(color: colour),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
