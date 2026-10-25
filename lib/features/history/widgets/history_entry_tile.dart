import 'package:flutter/material.dart';

import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';
import '../history_entry.dart';

/// One row of the history list (screen 04): the expression in 14 px muted
/// text above the 24 px result, right aligned, with a 1 px separator.
class HistoryEntryTile extends StatelessWidget {
  const HistoryEntryTile({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onLongPress,
  });

  final HistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Semantics(
      button: true,
      label: '${entry.expression} = ${entry.result}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          key: Key('history-entry-${entry.id}'),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.historyEntryPaddingV,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: palette.historyDivider,
                width: AppSizes.borderWidth,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                entry.expression,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: AppTypography.historyExpression.copyWith(
                  color: palette.onPrimaryMuted,
                ),
              ),
              const SizedBox(height: AppSizes.historyEntryGap),
              Text(
                entry.result,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: AppTypography.historyResult.copyWith(
                  color: palette.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
