import 'package:flutter/material.dart';

import '../../../core/programmer/word.dart';
import '../../../shared/widgets/white_sheet.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// The word-size chip's sheet (SPEC §1.4: 8 / 16 / 32 / 64-bit).
///
/// Pops the chosen [WordSize]; the page applies it and shows the §11
/// "Value truncated to 16-bit" toast when the value no longer fits.
class WordSizeMenu extends StatelessWidget {
  const WordSizeMenu({super.key, required this.selected});

  final WordSize selected;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return WhiteSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Word size',
            style: AppTypography.historyMenu.copyWith(color: palette.ink),
          ),
          const SizedBox(height: AppSizes.historyEntryGap),
          for (final WordSize size in WordSize.values) ...<Widget>[
            if (size != WordSize.values.first)
              Divider(
                height: AppSizes.borderWidth,
                thickness: AppSizes.borderWidth,
                color: palette.divider,
              ),
            Semantics(
              button: true,
              selected: size == selected,
              child: GestureDetector(
                key: Key('word-size-${size.bits}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(size),
                child: SizedBox(
                  height: AppSizes.historyMenuRowHeight,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          size.label,
                          maxLines: 1,
                          style: AppTypography.historyMenu.copyWith(
                            color: palette.ink,
                          ),
                        ),
                      ),
                      if (size == selected)
                        Icon(
                          Icons.check_rounded,
                          size: AppSizes.historyMenuIcon,
                          color: palette.primary,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
