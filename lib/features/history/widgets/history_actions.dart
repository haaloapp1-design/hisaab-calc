import 'package:flutter/material.dart';

import '../../../shared/widgets/white_sheet.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// The white action sheet at the bottom of screen 04: "Copy all" and
/// "Clear history", 48 px high with 16 px radii and a 10 px gap.
class HistoryActions extends StatelessWidget {
  const HistoryActions({
    super.key,
    required this.onCopyAll,
    required this.onClear,
  });

  final VoidCallback onCopyAll;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return WhiteSheet(
      child: Row(
        children: <Widget>[
          Expanded(
            child: _HistoryActionButton(
              buttonKey: const Key('history-copy-all'),
              label: 'Copy all',
              onTap: onCopyAll,
            ),
          ),
          const SizedBox(width: AppSizes.historyActionGap),
          Expanded(
            child: _HistoryActionButton(
              buttonKey: const Key('history-clear'),
              label: 'Clear history',
              danger: true,
              onTap: onClear,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryActionButton extends StatelessWidget {
  const _HistoryActionButton({
    required this.buttonKey,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          key: buttonKey,
          height: AppSizes.historyActionHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: danger ? palette.dangerSurface : palette.keyNumber,
            borderRadius: BorderRadius.circular(AppRadii.historyAction),
            border: Border.all(
              color: danger ? palette.dangerBorder : palette.keyNumberBorder,
              width: AppSizes.borderWidth,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.historyAction.copyWith(
              color: danger ? palette.danger : palette.primaryText,
            ),
          ),
        ),
      ),
    );
  }
}
