import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import '../../theme/app_tokens.dart';

/// The white card that holds the lower half of a screen (DESIGN "Components").
///
/// It is the surface only: rounded top corners, the drag handle and the
/// padding from `01-basic.html`. Its child decides how tall it gets, so a
/// screen can put it above the bottom navigation or let it fill the rest of
/// the page with an [Expanded].
class WhiteSheet extends StatelessWidget {
  const WhiteSheet({
    super.key,
    required this.child,
    this.showHandle = true,
    this.padding,
    this.contentGap,
  });

  final Widget child;

  /// The small grabber at the top of the sheet.
  final bool showHandle;

  /// Overrides the default 12/20/14 sheet padding.
  final EdgeInsetsGeometry? padding;

  /// Overrides the default 14 px gap between the handle and the child.
  final double? contentGap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Container(
      key: const Key('white-sheet'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.sheet,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet),
        ),
      ),
      padding:
          padding ??
          const EdgeInsets.fromLTRB(
            AppSizes.sheetPaddingSide,
            AppSizes.sheetPaddingTop,
            AppSizes.sheetPaddingSide,
            AppSizes.sheetPaddingBottom,
          ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (showHandle) ...<Widget>[
            Center(
              child: Container(
                key: const Key('white-sheet-handle'),
                width: AppSizes.handleWidth,
                height: AppSizes.handleHeight,
                decoration: BoxDecoration(
                  color: palette.primary,
                  borderRadius: BorderRadius.circular(AppRadii.handle),
                ),
              ),
            ),
            SizedBox(height: contentGap ?? AppSizes.sheetContentGap),
          ],
          child,
        ],
      ),
    );
  }
}