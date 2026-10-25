import 'package:flutter/material.dart';

import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// The 36 px "Clear" button from the Data card (screen 05): white `danger`
/// text on `dangerSurface` with a `dangerBorder` outline.
class ClearDataButton extends StatelessWidget {
  const ClearDataButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          key: const Key('clear-data'),
          height: AppSizes.clearButtonHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.clearButtonPaddingH,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.dangerSurface,
            borderRadius: BorderRadius.circular(AppRadii.chip),
            border: Border.all(
              color: palette.dangerBorder,
              width: AppSizes.borderWidth,
            ),
          ),
          child: Text(
            'Clear',
            style: AppTypography.clearButton.copyWith(color: palette.danger),
          ),
        ),
      ),
    );
  }
}
