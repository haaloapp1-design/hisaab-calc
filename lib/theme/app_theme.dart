import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// The app's light theme, built only from the tokens in [AppColors],
/// [AppRadii], [AppSizes] and [AppTypography].
///
/// Dark theme arrives in T49.
abstract final class AppTheme {
  static ThemeData light() {
    final ThemeData base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTypography.fontFamily,
    );

    const ColorScheme colors = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.keyOperator,
      onPrimaryContainer: AppColors.ink,
      secondary: AppColors.warning,
      onSecondary: AppColors.ink,
      surface: AppColors.sheet,
      onSurface: AppColors.ink,
      outline: AppColors.keyNumberBorder,
      error: AppColors.danger,
      onError: AppColors.onPrimary,
    );

    final TextTheme textTheme = base.textTheme
        .apply(
          fontFamily: AppTypography.fontFamily,
          bodyColor: AppColors.ink,
          displayColor: AppColors.ink,
        )
        .copyWith(
          displayLarge: AppTypography.resultBasic.copyWith(
            color: AppColors.ink,
          ),
          displayMedium: AppTypography.resultScientific.copyWith(
            color: AppColors.ink,
          ),
          headlineMedium: AppTypography.hubTitle.copyWith(
            color: AppColors.ink,
          ),
          titleMedium: AppTypography.screenTitle.copyWith(
            color: AppColors.ink,
          ),
          bodyMedium: AppTypography.body.copyWith(color: AppColors.ink),
          bodySmall: AppTypography.small.copyWith(color: AppColors.inkMuted),
          labelSmall: AppTypography.navLabel.copyWith(
            color: AppColors.inkMuted,
          ),
        );

    return base.copyWith(
      colorScheme: colors,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.sheet,
      textTheme: textTheme,
      primaryTextTheme: base.primaryTextTheme.apply(
        fontFamily: AppTypography.fontFamily,
        bodyColor: AppColors.onPrimary,
        displayColor: AppColors.onPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.screenTitle.copyWith(
          color: AppColors.onPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.onPrimary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.sheet,
        modalBackgroundColor: AppColors.sheet,
        surfaceTintColor: AppColors.sheet,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.keyNumberBorder,
        thickness: AppSizes.borderWidth,
        space: AppSizes.borderWidth,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.ink,
        size: AppSizes.icon,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: AppTypography.body.copyWith(
          color: AppColors.sheet,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(
            AppSizes.minTapTarget,
            AppSizes.minTapTarget,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadii.keyConverter)),
          ),
        ),
      ),
    );
  }
}
