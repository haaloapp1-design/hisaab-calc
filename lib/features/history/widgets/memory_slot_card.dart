import 'package:flutter/material.dart';

import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// One saved memory slot on screen 04: the `M1` label over its value and the
/// `MR` / `M+` / `M-` buttons.
///
/// [index] is zero-based; the label is `M<index + 1>`. The card only renders
/// slots that hold a value.
class MemorySlotCard extends StatelessWidget {
  const MemorySlotCard({
    super.key,
    required this.index,
    required this.value,
    required this.onRecall,
    required this.onAdd,
    required this.onSubtract,
  });

  final int index;
  final String value;
  final VoidCallback onRecall;
  final VoidCallback onAdd;
  final VoidCallback onSubtract;

  String get _slot => 'M${index + 1}';

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Container(
      key: Key('memory-slot-$_slot'),
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.memoryCardPaddingV,
        horizontal: AppSizes.memoryCardPaddingH,
      ),
      decoration: BoxDecoration(
        color: palette.primaryTrack,
        borderRadius: BorderRadius.circular(AppRadii.memoryCard),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _slot,
                  style: AppTypography.memorySlot.copyWith(
                    color: palette.onPrimaryMuted,
                  ),
                ),
                const SizedBox(height: AppSizes.memorySlotGap),
                Text(
                  value,
                  key: Key('memory-value-$_slot'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.memoryValue.copyWith(
                    color: palette.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.memoryButtonGap),
          _MemoryButton(
            buttonKey: Key('memory-recall-$_slot'),
            label: 'MR',
            semanticLabel: 'Recall $_slot',
            onTap: onRecall,
            filled: true,
          ),
          const SizedBox(width: AppSizes.memoryButtonGap),
          _MemoryButton(
            buttonKey: Key('memory-add-$_slot'),
            label: 'M+',
            semanticLabel: 'Add to $_slot',
            onTap: onAdd,
          ),
          const SizedBox(width: AppSizes.memoryButtonGap),
          _MemoryButton(
            buttonKey: Key('memory-subtract-$_slot'),
            label: 'M−',
            semanticLabel: 'Subtract from $_slot',
            onTap: onSubtract,
          ),
        ],
      ),
    );
  }
}

class _MemoryButton extends StatelessWidget {
  const _MemoryButton({
    required this.buttonKey,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
    this.filled = false,
  });

  final Key buttonKey;
  final String label;
  final String semanticLabel;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          key: buttonKey,
          height: AppSizes.memoryButtonHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.memoryButtonPaddingH,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? palette.onPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.memoryButton),
            border: filled
                ? null
                : Border.all(
                    color: palette.memoryButtonBorder,
                    width: AppSizes.borderWidth,
                  ),
          ),
          child: Text(
            label,
            maxLines: 1,
            style:
                (filled
                        ? AppTypography.memoryRecall
                        : AppTypography.memoryAdjust)
                    .copyWith(
                      color: filled ? palette.primary : palette.onPrimary,
                    ),
          ),
        ),
      ),
    );
  }
}
