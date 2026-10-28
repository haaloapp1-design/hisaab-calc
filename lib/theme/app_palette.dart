import 'package:flutter/material.dart';

import 'app_tokens.dart';
import 'contrast.dart';

/// The colours of one theme + accent combination, exposed as a
/// [ThemeExtension] so widgets can read them from `Theme.of(context)`.
///
/// `AppColors` keeps the light/cobalt design values as constants (tests and
/// fallbacks). Every widget renders with [AppPalette.of] instead, which is why
/// changing the accent or switching to dark recolours the whole app.
///
/// DESIGN "Accent swatches": changing the accent replaces `primary` and the
/// track/operator tints are derived by mixing it with the surface. For cobalt
/// the exact light tokens are used; the other swatches derive every tint with
/// the same mix factors, so the design stays consistent.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primary,
    required this.primaryDeep,
    required this.primaryTrack,
    required this.primaryText,
    required this.onPrimary,
    required this.onPrimaryMuted,
    required this.onPrimaryFaint,
    required this.dividerOnPrimary,
    required this.historyDivider,
    required this.memoryButtonBorder,
    required this.converterCardBorder,
    required this.sheet,
    required this.background,
    required this.keyNumber,
    required this.keyNumberScientific,
    required this.keyNumberBorder,
    required this.keyFunction,
    required this.keyOperator,
    required this.keyOperatorBorder,
    required this.ink,
    required this.inkMuted,
    required this.segmentedInactive,
    required this.divider,
    required this.selectorTrack,
    required this.switchOff,
    required this.dangerBorder,
    required this.navDivider,
    required this.disabled,
    required this.disabledBorder,
    required this.warning,
    required this.danger,
    required this.dangerSurface,
  });

  final Color primary;
  final Color primaryDeep;
  final Color primaryTrack;

  /// The accent as a *foreground* colour: text, icons and cursors on a sheet,
  /// a key or the background. It equals [primary] in light mode; in dark mode
  /// the accent itself is too dark for a dark surface, so this is the lightest
  /// tint of it that still reaches AA (T49).
  final Color primaryText;

  final Color onPrimary;
  final Color onPrimaryMuted;
  final Color onPrimaryFaint;
  final Color dividerOnPrimary;
  final Color historyDivider;
  final Color memoryButtonBorder;
  final Color converterCardBorder;
  final Color sheet;
  final Color background;
  final Color keyNumber;
  final Color keyNumberScientific;
  final Color keyNumberBorder;
  final Color keyFunction;
  final Color keyOperator;
  final Color keyOperatorBorder;
  final Color ink;
  final Color inkMuted;
  final Color segmentedInactive;
  final Color divider;
  final Color selectorTrack;
  final Color switchOff;
  final Color dangerBorder;
  final Color navDivider;
  final Color disabled;
  final Color disabledBorder;
  final Color warning;
  final Color danger;
  final Color dangerSurface;

  /// The light theme with the cobalt accent: exactly the DESIGN tokens.
  static const AppPalette lightCobalt = AppPalette(
    primary: AppColors.primary,
    primaryDeep: AppColors.primaryDeep,
    primaryTrack: AppColors.primaryTrack,
    primaryText: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    onPrimaryMuted: AppColors.onPrimaryMuted,
    onPrimaryFaint: AppColors.onPrimaryFaint,
    dividerOnPrimary: AppColors.dividerOnPrimary,
    historyDivider: AppColors.historyDivider,
    memoryButtonBorder: AppColors.memoryButtonBorder,
    converterCardBorder: AppColors.converterCardBorder,
    sheet: AppColors.sheet,
    background: AppColors.background,
    keyNumber: AppColors.keyNumber,
    keyNumberScientific: AppColors.keyNumberScientific,
    keyNumberBorder: AppColors.keyNumberBorder,
    keyFunction: AppColors.keyFunction,
    keyOperator: AppColors.keyOperator,
    keyOperatorBorder: AppColors.keyOperatorBorder,
    ink: AppColors.ink,
    inkMuted: AppColors.inkMuted,
    segmentedInactive: AppColors.segmentedInactive,
    divider: AppColors.divider,
    selectorTrack: AppColors.selectorTrack,
    switchOff: AppColors.switchOff,
    dangerBorder: AppColors.dangerBorder,
    navDivider: AppColors.navDivider,
    disabled: AppColors.disabled,
    disabledBorder: AppColors.disabledBorder,
    warning: AppColors.warning,
    danger: AppColors.danger,
    dangerSurface: AppColors.dangerSurface,
  );

  /// The dark theme with the cobalt accent, matching [AppTheme.dark]'s default.
  static final AppPalette darkCobalt = AppPalette.dark(AppColors.primary);

  /// The light theme for any accent. Cobalt keeps the exact design tokens.
  factory AppPalette.light(Color accent) {
    if (accent == AppColors.primary) {
      return lightCobalt;
    }
    return AppPalette(
      primary: accent,
      primaryDeep: _mixBlack(accent, 0.28),
      primaryTrack: _mixWhite(accent, 0.08),
      primaryText: accent,
      onPrimary: AppColors.onPrimary,
      onPrimaryMuted: _mixWhite(accent, 0.84),
      onPrimaryFaint: _mixWhite(accent, 0.73),
      dividerOnPrimary: _mixWhite(accent, 0.22),
      historyDivider: _mixWhite(accent, 0.20),
      memoryButtonBorder: _mixWhite(accent, 0.48),
      converterCardBorder: _mixWhite(accent, 0.55),
      sheet: AppColors.sheet,
      background: AppColors.background,
      keyNumber: AppColors.keyNumber,
      keyNumberScientific: AppColors.keyNumberScientific,
      keyNumberBorder: AppColors.keyNumberBorder,
      keyFunction: AppColors.keyFunction,
      keyOperator: _mixWhite(accent, 0.88),
      keyOperatorBorder: _mixWhite(accent, 0.80),
      ink: AppColors.ink,
      inkMuted: AppColors.inkMuted,
      segmentedInactive: _mixWhite(accent, 0.88),
      divider: AppColors.divider,
      selectorTrack: AppColors.selectorTrack,
      switchOff: AppColors.switchOff,
      dangerBorder: AppColors.dangerBorder,
      navDivider: AppColors.navDivider,
      disabled: AppColors.disabled,
      disabledBorder: AppColors.disabledBorder,
      warning: AppColors.warning,
      danger: AppColors.danger,
      dangerSurface: AppColors.dangerSurface,
    );
  }

  /// The dark theme from DESIGN "Dark theme": #10142B background, #181D3A
  /// sheet, #222849 keys and #E8EBFA ink; the accent stays `primary`.
  ///
  /// On dark surfaces the accent itself is too dark to read (cobalt is only
  /// 2.11:1 on the sheet), so every accent *foreground* is derived as the
  /// lightest tint that still reaches AA: [primaryText] on the surfaces and the
  /// on-blue tints on the header. T49.
  factory AppPalette.dark(Color accent) {
    final Color sheet = _darkSheet;
    final Color track = _mixWhite(accent, 0.08);
    return AppPalette(
      primary: accent,
      primaryDeep: _mixBlack(accent, 0.18),
      primaryTrack: track,
      primaryText: _tintUntil(accent, _darkFunction, Contrast.normalText),
      onPrimary: AppColors.onPrimary,
      onPrimaryMuted: _tintUntil(accent, track, Contrast.normalText),
      onPrimaryFaint: _tintUntil(accent, track, Contrast.normalText),
      dividerOnPrimary: _mixWhite(accent, 0.22),
      historyDivider: _mixWhite(accent, 0.22),
      memoryButtonBorder: _mixWhite(accent, 0.45),
      converterCardBorder: _mixWhite(accent, 0.55),
      sheet: sheet,
      background: _darkBackground,
      keyNumber: _darkKeys,
      keyNumberScientific: _darkKeysRaised,
      keyNumberBorder: _darkBorder,
      keyFunction: _darkFunction,
      keyOperator: Color.lerp(accent, sheet, 0.72)!,
      keyOperatorBorder: Color.lerp(accent, sheet, 0.56)!,
      ink: _darkInk,
      inkMuted: _darkInkMuted,
      segmentedInactive: _tintUntil(accent, track, Contrast.normalText),
      divider: _darkDivider,
      selectorTrack: _darkKeys,
      switchOff: _darkSwitchOff,
      dangerBorder: _darkDangerBorder,
      navDivider: _darkDivider,
      disabled: _darkDisabled,
      disabledBorder: _darkDisabledBorder,
      warning: AppColors.warning,
      danger: _darkDanger,
      dangerSurface: _darkDangerSurface,
    );
  }

  // Light + dark tokens that do not depend on the accent.
  static const Color _darkBackground = Color(0xFF10142B);
  static const Color _darkSheet = Color(0xFF181D3A);
  static const Color _darkKeys = Color(0xFF222849);
  static const Color _darkKeysRaised = Color(0xFF262C50);
  static const Color _darkBorder = Color(0xFF333A61);
  static const Color _darkFunction = Color(0xFF2A3054);
  static const Color _darkInk = Color(0xFFE8EBFA);
  static const Color _darkInkMuted = Color(0xFFA9B2D6);
  static const Color _darkDivider = Color(0xFF2A3054);
  static const Color _darkSwitchOff = Color(0xFF4A5178);
  static const Color _darkDisabled = Color(0xFF6B739A);
  static const Color _darkDisabledBorder = Color(0xFF3A4166);
  static const Color _darkDanger = Color(0xFFFF8A5C);
  static const Color _darkDangerSurface = Color(0xFF3A2320);
  static const Color _darkDangerBorder = Color(0xFF5C352A);

  static Color _mixWhite(Color colour, double amount) =>
      Color.lerp(colour, AppColors.onPrimary, amount)!;

  static Color _mixBlack(Color colour, double amount) =>
      Color.lerp(colour, const Color(0xFF000000), amount)!;

  /// Mixes [colour] with white in 1 % steps until it reaches [target] contrast
  /// against [surface], and returns the first tint that does. Used by the dark
  /// palette, where the accent has to become a light tint to be readable (T49).
  static Color _tintUntil(Color colour, Color surface, double target) {
    for (int step = 30; step < 100; step++) {
      final Color tint = _mixWhite(colour, step / 100);
      if (Contrast.ratio(tint, surface) >= target) {
        return tint;
      }
    }
    return AppColors.onPrimary;
  }

  /// The palette of the current theme, or [lightCobalt] when a test pumps a
  /// bare `MaterialApp` without [AppTheme] (never in the app itself).
  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ?? lightCobalt;

  Color get accent => primary;

  @override
  AppPalette copyWith({
    Color? primary,
    Color? primaryDeep,
    Color? primaryTrack,
    Color? primaryText,
    Color? onPrimary,
    Color? onPrimaryMuted,
    Color? onPrimaryFaint,
    Color? dividerOnPrimary,
    Color? historyDivider,
    Color? memoryButtonBorder,
    Color? converterCardBorder,
    Color? sheet,
    Color? background,
    Color? keyNumber,
    Color? keyNumberScientific,
    Color? keyNumberBorder,
    Color? keyFunction,
    Color? keyOperator,
    Color? keyOperatorBorder,
    Color? ink,
    Color? inkMuted,
    Color? segmentedInactive,
    Color? divider,
    Color? selectorTrack,
    Color? switchOff,
    Color? dangerBorder,
    Color? navDivider,
    Color? disabled,
    Color? disabledBorder,
    Color? warning,
    Color? danger,
    Color? dangerSurface,
  }) => AppPalette(
    primary: primary ?? this.primary,
    primaryDeep: primaryDeep ?? this.primaryDeep,
    primaryTrack: primaryTrack ?? this.primaryTrack,
    primaryText: primaryText ?? this.primaryText,
    onPrimary: onPrimary ?? this.onPrimary,
    onPrimaryMuted: onPrimaryMuted ?? this.onPrimaryMuted,
    onPrimaryFaint: onPrimaryFaint ?? this.onPrimaryFaint,
    dividerOnPrimary: dividerOnPrimary ?? this.dividerOnPrimary,
    historyDivider: historyDivider ?? this.historyDivider,
    memoryButtonBorder: memoryButtonBorder ?? this.memoryButtonBorder,
    converterCardBorder: converterCardBorder ?? this.converterCardBorder,
    sheet: sheet ?? this.sheet,
    background: background ?? this.background,
    keyNumber: keyNumber ?? this.keyNumber,
    keyNumberScientific: keyNumberScientific ?? this.keyNumberScientific,
    keyNumberBorder: keyNumberBorder ?? this.keyNumberBorder,
    keyFunction: keyFunction ?? this.keyFunction,
    keyOperator: keyOperator ?? this.keyOperator,
    keyOperatorBorder: keyOperatorBorder ?? this.keyOperatorBorder,
    ink: ink ?? this.ink,
    inkMuted: inkMuted ?? this.inkMuted,
    segmentedInactive: segmentedInactive ?? this.segmentedInactive,
    divider: divider ?? this.divider,
    selectorTrack: selectorTrack ?? this.selectorTrack,
    switchOff: switchOff ?? this.switchOff,
    dangerBorder: dangerBorder ?? this.dangerBorder,
    navDivider: navDivider ?? this.navDivider,
    disabled: disabled ?? this.disabled,
    disabledBorder: disabledBorder ?? this.disabledBorder,
    warning: warning ?? this.warning,
    danger: danger ?? this.danger,
    dangerSurface: dangerSurface ?? this.dangerSurface,
  );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }
    Color blend(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      primary: blend(primary, other.primary),
      primaryDeep: blend(primaryDeep, other.primaryDeep),
      primaryTrack: blend(primaryTrack, other.primaryTrack),
      primaryText: blend(primaryText, other.primaryText),
      onPrimary: blend(onPrimary, other.onPrimary),
      onPrimaryMuted: blend(onPrimaryMuted, other.onPrimaryMuted),
      onPrimaryFaint: blend(onPrimaryFaint, other.onPrimaryFaint),
      dividerOnPrimary: blend(dividerOnPrimary, other.dividerOnPrimary),
      historyDivider: blend(historyDivider, other.historyDivider),
      memoryButtonBorder: blend(memoryButtonBorder, other.memoryButtonBorder),
      converterCardBorder: blend(
        converterCardBorder,
        other.converterCardBorder,
      ),
      sheet: blend(sheet, other.sheet),
      background: blend(background, other.background),
      keyNumber: blend(keyNumber, other.keyNumber),
      keyNumberScientific: blend(
        keyNumberScientific,
        other.keyNumberScientific,
      ),
      keyNumberBorder: blend(keyNumberBorder, other.keyNumberBorder),
      keyFunction: blend(keyFunction, other.keyFunction),
      keyOperator: blend(keyOperator, other.keyOperator),
      keyOperatorBorder: blend(keyOperatorBorder, other.keyOperatorBorder),
      ink: blend(ink, other.ink),
      inkMuted: blend(inkMuted, other.inkMuted),
      segmentedInactive: blend(segmentedInactive, other.segmentedInactive),
      divider: blend(divider, other.divider),
      selectorTrack: blend(selectorTrack, other.selectorTrack),
      switchOff: blend(switchOff, other.switchOff),
      dangerBorder: blend(dangerBorder, other.dangerBorder),
      navDivider: blend(navDivider, other.navDivider),
      disabled: blend(disabled, other.disabled),
      disabledBorder: blend(disabledBorder, other.disabledBorder),
      warning: blend(warning, other.warning),
      danger: blend(danger, other.danger),
      dangerSurface: blend(dangerSurface, other.dangerSurface),
    );
  }
}
