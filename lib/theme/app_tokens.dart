import 'package:flutter/material.dart';

/// Design tokens from `docs/DESIGN.md`.
///
/// Widgets must use these values instead of hard-coded colours, font sizes or
/// radii. Everything visual in the app starts here.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF2D46B9);
  static const Color primaryDeep = Color(0xFF1F3391);
  static const Color primaryTrack = Color(0xFF3E58C8);

  // On blue
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryMuted = Color(0xFFDDE3FF);
  static const Color onPrimaryFaint = Color(0xFFC7D1FF);
  static const Color dividerOnPrimary = Color(0xFF5A72D6);

  // Surfaces
  static const Color sheet = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF4F6FD);

  // Keys
  static const Color keyNumber = Color(0xFFF6F7FD);
  static const Color keyNumberScientific = Color(0xFFF9FAFE);
  static const Color keyNumberBorder = Color(0xFFE4E8F7);
  static const Color keyFunction = Color(0xFFEEF1FB);
  static const Color keyOperator = Color(0xFFE6EBFC);
  static const Color keyOperatorBorder = Color(0xFFD6DDF8);

  // Text
  static const Color ink = Color(0xFF18224F);
  static const Color inkMuted = Color(0xFF5A6487);

  // Segmented control
  static const Color segmentedInactive = Color(0xFFE4E9FF);

  // Navigation
  static const Color navDivider = Color(0xFFEDF0FA);

  // States
  static const Color disabled = Color(0xFFA3ABC7);
  static const Color disabledBorder = Color(0xFFDCE1F2);
  static const Color warning = Color(0xFFF5B971);
  static const Color danger = Color(0xFFB4410E);
  static const Color dangerSurface = Color(0xFFFFF4EE);

  // Accent choices shown in Settings
  static const Color accentTeal = Color(0xFF0F766E);
  static const Color accentViolet = Color(0xFF7C3AED);
  static const Color accentRust = Color(0xFFC2410C);

  static const List<Color> accentSwatches = <Color>[
    primary,
    accentTeal,
    accentViolet,
    accentRust,
  ];
}

/// Corner radii.
abstract final class AppRadii {
  static const double sheet = 32;
  static const double handle = 2;
  static const double header = 28;

  static const double keyBasic = 18;
  static const double keyScientific = 14;
  static const double keyConverter = 16;

  static const double segmentedTrack = 14;
  static const double segmentedPill = 10;

  static const double chip = 10;

  static const double navItem = 14;

  static const double card = 18;
  static const double cardLarge = 20;
}

/// Heights, paddings, gaps and other measurements.
abstract final class AppSizes {
  static const double screenPadding = 20;
  static const double screenPaddingWide = 24;
  static const double sheetPaddingTop = 12;
  static const double sheetPaddingSide = 20;
  static const double sheetPaddingBottom = 14;
  static const double sheetContentGap = 14;

  static const double headerPaddingTop = 20;
  static const double hubHeaderPaddingTop = 24;
  static const double hubHeaderPaddingBottom = 20;
  static const double headerSubtitleGap = 6;
  static const double headerIcon = 22;

  static const double segmentedTopGap = 14;
  static const double segmentGap = 4;
  static const double segmentTrackPadding = 4;
  static const double segmentPillPadding = 10;

  static const double displayPaddingSide = 24;
  static const double displayPaddingBottom = 22;
  static const double displayScientificPaddingBottom = 18;
  static const double displayGap = 10;
  static const double displayScientificGap = 8;
  static const double chipPaddingV = 4;
  static const double chipPaddingH = 10;

  static const double keyHeightBasic = 60;
  static const double keyHeightScientific = 46;
  static const double keyHeightConverter = 52;

  static const double keyGapBasic = 12;
  static const double keyGapScientific = 8;
  static const double keyGapConverter = 10;

  static const double segmentedHeight = 44;
  static const double handleWidth = 44;
  static const double handleHeight = 4;

  static const double navGap = 6;
  static const double navItemGap = 3;
  static const double navItemPadding = 7;
  static const double navIcon = 22;
  static const double navPaddingTop = 10;
  static const double navPaddingBottom = 14;

  static const double minTapTarget = 44;
  static const double borderWidth = 1;
  static const double icon = 24;

  static const double disabledDash = 4;
  static const double disabledDashGap = 4;
}

/// Motion values from DESIGN "Components" (key press feedback).
abstract final class AppMotion {
  static const Duration keyPress = Duration(milliseconds: 80);
  static const double keyPressScale = 0.96;
  static const double keyPressDarken = 0.06;
}

/// Font sizes and weights from the DESIGN type table.
abstract final class AppTypography {
  static const String fontFamily = 'Ubuntu';

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight bold = FontWeight.w700;

  // Result / expression
  static const TextStyle resultBasic = TextStyle(
    fontFamily: fontFamily,
    fontSize: 60,
    fontWeight: medium,
    height: 1.05,
  );
  static const TextStyle resultBasicMin = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: medium,
    height: 1.05,
  );
  static const TextStyle resultScientific = TextStyle(
    fontFamily: fontFamily,
    fontSize: 52,
    fontWeight: medium,
    height: 1.05,
  );
  static const TextStyle converterValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: 38,
    fontWeight: medium,
  );
  static const TextStyle expression = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: regular,
    letterSpacing: 0.5,
  );
  static const TextStyle expressionScientific = TextStyle(
    fontFamily: fontFamily,
    fontSize: 19,
    fontWeight: regular,
    letterSpacing: 0.5,
  );

  // Keys
  static const TextStyle keyNumberBasic = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: regular,
  );
  static const TextStyle keyNumberScientific = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: regular,
  );
  static const TextStyle keyFunction = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: medium,
  );
  static const TextStyle keyFunctionBasic = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: bold,
  );
  static const TextStyle keyOperatorBasic = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: regular,
  );
  static const TextStyle keyOperatorScientific = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: regular,
  );
  static const TextStyle keyEqualsBasic = TextStyle(
    fontFamily: fontFamily,
    fontSize: 30,
    fontWeight: regular,
  );
  static const TextStyle keyEqualsScientific = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: regular,
  );
  static const TextStyle keyDisabled = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: regular,
  );

  // Text
  static const TextStyle screenTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: medium,
  );
  static const TextStyle hubTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: medium,
  );
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: regular,
  );
  static const TextStyle small = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: regular,
  );
  static const TextStyle hubSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: regular,
  );
  static const TextStyle segmentedLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: regular,
  );
  static const TextStyle navLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: medium,
  );
}
