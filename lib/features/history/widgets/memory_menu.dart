import 'package:flutter/material.dart';

import '../../../shared/widgets/white_sheet.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// The memory chip's long-press sheet (SPEC 2: `MS` / `MC`).
///
/// `MS` stores the calculator's current display value in the next free slot;
/// `MC` empties the main slot M1. Both are deliberate taps, so the chip can
/// never wipe a value just because a finger rested on it.
class MemoryMenu extends StatelessWidget {
  const MemoryMenu({super.key, required this.onStore, required this.onClear});

  final VoidCallback onStore;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return WhiteSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Memory',
            style: AppTypography.historyMenu.copyWith(color: palette.ink),
          ),
          const SizedBox(height: AppSizes.historyEntryGap),
          _MemoryMenuRow(
            rowKey: const Key('memory-store'),
            icon: Icons.save_alt_rounded,
            label: 'Store current value (MS)',
            onTap: onStore,
          ),
          Divider(
            height: AppSizes.borderWidth,
            thickness: AppSizes.borderWidth,
            color: palette.divider,
          ),
          _MemoryMenuRow(
            rowKey: const Key('memory-clear'),
            icon: Icons.backspace_outlined,
            label: 'Clear main memory (MC)',
            danger: true,
            onTap: onClear,
          ),
        ],
      ),
    );
  }
}

class _MemoryMenuRow extends StatelessWidget {
  const _MemoryMenuRow({
    required this.rowKey,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final Key rowKey;
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
        key: rowKey,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: AppSizes.historyMenuRowHeight,
          child: Row(
            children: <Widget>[
              Icon(icon, size: AppSizes.historyMenuIcon, color: colour),
              const SizedBox(width: AppSizes.historyActionGap),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.historyMenu.copyWith(color: colour),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
