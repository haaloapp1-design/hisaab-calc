import 'package:calculator/theme/app_palette.dart';
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

    test('carries the cobalt palette', () {
      final ThemeData theme = AppTheme.light();

      expect(theme.brightness, Brightness.light);
      expect(theme.extension<AppPalette>(), AppPalette.lightCobalt);
    });

    test('takes the accent from Settings', () {
      final ThemeData theme = AppTheme.light(accent: AppColors.accentTeal);
      final AppPalette palette = theme.extension<AppPalette>()!;

      expect(palette.primary, AppColors.accentTeal);
      expect(theme.colorScheme.primary, AppColors.accentTeal);
      expect(theme.colorScheme.primaryContainer, palette.keyOperator);
      expect(theme.appBarTheme.backgroundColor, AppColors.accentTeal);
    });
  });

  group('AppTheme.dark', () {
    test('carries the dark palette and keeps the accent', () {
      final ThemeData theme = AppTheme.dark(accent: AppColors.accentRust);
      final AppPalette palette = theme.extension<AppPalette>()!;
      final AppPalette expected = AppPalette.dark(AppColors.accentRust);

      expect(theme.brightness, Brightness.dark);
      expect(palette.primary, expected.primary);
      expect(palette.background, expected.background);
      expect(palette.sheet, expected.sheet);
      expect(palette.keyNumber, expected.keyNumber);
      expect(palette.ink, expected.ink);
      expect(theme.colorScheme.primary, AppColors.accentRust);
      expect(theme.scaffoldBackgroundColor, const Color(0xFF10142B));
      expect(theme.canvasColor, const Color(0xFF181D3A));
      expect(theme.textTheme.bodyMedium?.color, const Color(0xFFE8EBFA));
    });
  });

  test('Material colours follow the palette, not fixed constants', () {
    final ThemeData theme = AppTheme.light(accent: AppColors.accentViolet);
    final AppPalette palette = theme.extension<AppPalette>()!;

    expect(theme.iconTheme.color, palette.ink);
    expect(theme.dividerTheme.color, palette.keyNumberBorder);
    expect(theme.bottomSheetTheme.backgroundColor, palette.sheet);
    expect(
      theme.filledButtonTheme.style!.backgroundColor!.resolve(<WidgetState>{}),
      palette.primary,
    );
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
