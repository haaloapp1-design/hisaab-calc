import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_tokens.dart';

/// The app's light and dark themes, built only from [AppPalette] plus the
/// tokens in [AppRadii], [AppSizes] and [AppTypography].
///
/// The accent colour comes from Settings; every widget reads the resulting
/// [AppPalette] from the theme, so one accent/mode change recolours the app.
abstract final class AppTheme {
  static ThemeData light({Color accent = AppColors.primary}) =>
      _build(AppPalette.light(accent), Brightness.light);

  static ThemeData dark({Color accent = AppColors.primary}) =>
      _build(AppPalette.dark(accent), Brightness.dark);

  static ThemeData _build(AppPalette palette, Brightness brightness) {
    final ThemeData base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTypography.fontFamily,
    );

    final ColorScheme colors =
        ColorScheme.fromSeed(
          seedColor: palette.primary,
          brightness: brightness,
        ).copyWith(
          primary: palette.primary,
          onPrimary: palette.onPrimary,
          primaryContainer: palette.keyOperator,
          onPrimaryContainer: palette.ink,
          secondary: palette.warning,
          onSecondary: palette.ink,
          surface: palette.sheet,
          onSurface: palette.ink,
          outline: palette.keyNumberBorder,
          error: palette.danger,
          onError: palette.onPrimary,
        );

    final TextTheme textTheme = base.textTheme
        .apply(
          fontFamily: AppTypography.fontFamily,
          bodyColor: palette.ink,
          displayColor: palette.ink,
        )
        .copyWith(
          displayLarge: AppTypography.resultBasic.copyWith(color: palette.ink),
          displayMedium: AppTypography.resultScientific.copyWith(
            color: palette.ink,
          ),
          headlineMedium: AppTypography.hubTitle.copyWith(color: palette.ink),
          titleMedium: AppTypography.screenTitle.copyWith(color: palette.ink),
          bodyMedium: AppTypography.body.copyWith(color: palette.ink),
          bodySmall: AppTypography.small.copyWith(color: palette.inkMuted),
          labelSmall: AppTypography.navLabel.copyWith(color: palette.inkMuted),
        );

    return base.copyWith(
      colorScheme: colors,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.sheet,
      textTheme: textTheme,
      primaryTextTheme: base.primaryTextTheme.apply(
        fontFamily: AppTypography.fontFamily,
        bodyColor: palette.onPrimary,
        displayColor: palette.onPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.primary,
        foregroundColor: palette.onPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.screenTitle.copyWith(
          color: palette.onPrimary,
        ),
        iconTheme: IconThemeData(color: palette.onPrimary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.sheet,
        modalBackgroundColor: palette.sheet,
        surfaceTintColor: palette.sheet,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.keyNumberBorder,
        thickness: AppSizes.borderWidth,
        space: AppSizes.borderWidth,
      ),
      iconTheme: IconThemeData(color: palette.ink, size: AppSizes.icon),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.ink,
        contentTextStyle: AppTypography.body.copyWith(color: palette.sheet),
        behavior: SnackBarBehavior.floating,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          minimumSize: const Size(AppSizes.minTapTarget, AppSizes.minTapTarget),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(AppRadii.keyConverter),
            ),
          ),
        ),
      ),
      // Text buttons and the date picker sit on the sheet, so their accent
      // text uses `primaryText`; the raw accent is only 2.11:1 on the dark
      // sheet (T49).
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primaryText,
          minimumSize: const Size(AppSizes.minTapTarget, AppSizes.minTapTarget),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: palette.sheet,
        headerBackgroundColor: palette.primary,
        headerForegroundColor: palette.onPrimary,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return palette.disabled;
          }
          if (states.contains(WidgetState.selected)) {
            return palette.onPrimary;
          }
          return palette.ink;
        }),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return palette.disabled;
          }
          if (states.contains(WidgetState.selected)) {
            return palette.onPrimary;
          }
          return palette.ink;
        }),
      ),
      extensions: <ThemeExtension<dynamic>>[palette],
    );
  }
}
