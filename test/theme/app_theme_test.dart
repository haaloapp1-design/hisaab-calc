import 'package:calculator/theme/app_theme.dart';
import 'package:calculator/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme.light', () {
    test('uses the design colours', () {
      final ThemeData theme = AppTheme.light();

      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.onPrimary, AppColors.onPrimary);
      expect(theme.colorScheme.surface, AppColors.sheet);
      expect(theme.colorScheme.onSurface, AppColors.ink);
      expect(theme.scaffoldBackgroundColor, AppColors.background);
      expect(theme.bottomSheetTheme.backgroundColor, AppColors.sheet);
      expect(theme.appBarTheme.backgroundColor, AppColors.primary);
    });

    test('uses the Ubuntu type scale', () {
      final ThemeData theme = AppTheme.light();

      expect(AppTypography.fontFamily, 'Ubuntu');
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Ubuntu');
      expect(theme.textTheme.bodyMedium?.fontSize, 15);
      expect(theme.textTheme.displayLarge?.fontSize, 60);
      expect(theme.textTheme.displayMedium?.fontSize, 52);
      expect(theme.textTheme.headlineMedium?.fontSize, 26);
    });

    test('uses the sheet shape and key radius tokens', () {
      final ThemeData theme = AppTheme.light();
      final ShapeBorder? sheetShape = theme.bottomSheetTheme.shape;

      expect(sheetShape, isA<RoundedRectangleBorder>());
      final BorderRadius radius =
          (sheetShape! as RoundedRectangleBorder).borderRadius as BorderRadius;
      expect(radius.topLeft.x, AppRadii.sheet);
      expect(AppRadii.keyBasic, 18);
      expect(AppSizes.keyHeightBasic, 60);
    });
  });

  test('accent swatches match the design', () {
    expect(AppColors.accentSwatches, <Color>[
      AppColors.primary,
      AppColors.accentTeal,
      AppColors.accentViolet,
      AppColors.accentRust,
    ]);
  });
}
