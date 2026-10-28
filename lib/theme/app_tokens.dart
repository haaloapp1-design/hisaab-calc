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

  // Settings
  static const Color divider = Color(0xFFEDF0FA);
  static const Color selectorTrack = Color(0xFFEEF1FB);
  static const Color switchOff = Color(0xFFC9CFE3);
  static const Color dangerBorder = Color(0xFFF3C9B5);

  // Navigation
  static const Color navDivider = Color(0xFFEDF0FA);

  // History (screen 04)
  static const Color historyDivider = Color(0xFF4A62CF);

  // Memory (screen 04)
  static const Color memoryButtonBorder = Color(0xFF7F93E3);

  // Unit converter (screen 07)
  static const Color converterCardBorder = Color(0xFF9FB0F2);

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

  static const double historyAction = 16;
  static const double historySearch = 14;

  static const double memoryCard = 16;
  static const double memoryButton = 12;

  static const double card = 18;
  static const double cardLarge = 20;

  static const double settingsTrack = 10;
  static const double settingsPill = 8;

  // Tool pages (screen 10)
  static const double toolField = 14;
  static const double toolRateChip = 12;
  static const double toolSegmentPill = 11;
}

/// Heights, paddings, gaps and other measurements.
abstract final class AppSizes {
  static const double screenPadding = 20;
  static const double screenPaddingWide = 24;
  static const double sheetPaddingTop = 12;
  static const double sheetPaddingSide = 20;
  static const double sheetPaddingBottom = 14;
  static const double sheetScientificPaddingSide = 16;
  static const double sheetContentGap = 14;
  static const double sheetScientificContentGap = 12;

  static const double headerPaddingTop = 20;
  static const double headerSettingsPaddingBottom = 22;
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

  static const double angleChipPaddingV = 6;
  static const double angleChipPaddingH = 12;
  static const double angleChipGap = 6;
  static const double angleRowBottomGap = 8;

  // Settings (screen 05)
  static const double settingsPaddingTop = 18;
  static const double settingsSectionGap = 18;
  static const double settingsTitleGap = 8;
  static const double settingsTitleInset = 4;
  static const double settingsCardPaddingH = 16;
  static const double settingsCardPaddingV = 6;
  static const double settingsRowPaddingV = 10;
  static const double settingsTrackPadding = 3;
  static const double settingsPillPaddingV = 6;
  static const double settingsPillPaddingH = 10;
  static const double settingsPillGap = 2;
  static const double accentDot = 28;
  static const double accentDotGap = 10;
  static const double accentSelectedBorder = 3;
  static const double accentRing = 2;
  static const double switchWidth = 50;
  static const double switchHeight = 30;
  static const double switchPadding = 3;
  static const double switchKnob = 24;
  static const double stepperButton = 32;
  static const double stepperGap = 8;
  static const double stepperValueWidth = 40;
  static const double clearButtonHeight = 36;
  static const double clearButtonPaddingH = 14;

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

  // History (screen 04)
  static const double historyListPaddingTop = 16;
  static const double historyListPaddingSide = 24;
  static const double historyListPaddingBottom = 16;
  static const double historyGroupGap = 6;
  static const double historyGroupTopGap = 10;
  static const double historyEntryPaddingV = 8;
  static const double historyEntryGap = 2;
  static const double historyActionGap = 10;
  static const double historyActionHeight = 48;
  static const double historyMenuRowHeight = 48;
  static const double historyMenuIcon = 20;
  static const double searchIcon = 20;
  static const double historySearchTopGap = 14;
  static const double historySearchPaddingH = 14;
  static const double historySearchRadius = 14;

  // Memory (screen 04)
  static const double memoryListPaddingTop = 16;
  static const double memoryListPaddingSide = 24;
  static const double memoryCardGap = 6;
  static const double memoryCardPaddingV = 12;
  static const double memoryCardPaddingH = 14;
  static const double memorySlotGap = 2;
  static const double memoryButtonGap = 6;
  static const double memoryButtonHeight = 44;
  static const double memoryButtonPaddingH = 12;

  // Programmer (screen 03)
  static const double programmerDisplaySide = 20;
  static const double programmerDisplayBottom = 16;
  static const double programmerDisplayGap = 6;
  static const double baseRowPaddingV = 6;
  static const double baseRowPaddingH = 12;
  static const double baseRowNameWidth = 40;
  static const double baseRowGap = 12;

  // Converter hub (screen 06)
  static const double hubHeaderGap = 14;
  static const double hubSearchHeight = 48;
  static const double hubSearchPaddingH = 14;
  static const double hubSearchRadius = 14;
  static const double hubSearchIcon = 18;
  static const double hubSearchGap = 10;
  static const double hubContentPaddingTop = 16;
  static const double hubContentGap = 12;
  static const double hubCurrencyPaddingV = 14;
  static const double hubCurrencyPaddingH = 16;
  static const double hubCurrencyGap = 14;
  static const double hubCurrencyIcon = 46;
  static const double hubCurrencyIconRadius = 14;
  static const double hubCurrencyChevron = 20;
  static const double hubGridGap = 10;
  static const double hubCellHeight = 86;
  static const double hubCellGap = 8;
  static const double hubChipHeight = 32;
  static const double hubChipMinWidth = 40;
  static const double hubChipPaddingH = 8;
  static const double hubResultPaddingV = 14;
  static const double hubResultPaddingH = 16;
  static const double hubResultGap = 2;
  static const int hubGridColumns = 3;
  static const double hubFavouritePaddingV = 14;
  static const double hubFavouritePaddingH = 16;
  static const double hubFavouriteTitleGap = 6;
  static const double hubFavouriteRowHeight = 48;
  static const double hubFavouriteIcon = 18;
  static const double hubFavouriteGap = 12;
  static const double hubFavouriteChevron = 20;

  // Unit converter (screen 07)
  static const double converterCardsTopGap = 16;
  static const double converterCardPaddingV = 14;
  static const double converterCardPaddingH = 16;
  static const double converterCardGap = 12;
  static const double converterCardContentGap = 6;
  static const double converterCardBorderWidth = 2;
  static const double converterValueHeight = 46;
  static const double converterUnitPillPaddingV = 6;
  static const double converterUnitPillPaddingH = 10;
  static const double converterUnitPillGap = 6;
  static const double converterUnitPillIcon = 14;
  static const double converterSwapSize = 48;
  static const double converterSwapBorder = 4;
  static const double converterSwapIcon = 20;
  static const double converterRulePaddingTop = 8;
  static const double converterRulePaddingH = 4;
  static const double converterAlsoPaddingTop = 10;
  static const double converterAlsoPaddingSide = 24;
  static const double converterAlsoPaddingBottom = 14;
  static const double converterAlsoTitleGap = 4;
  static const double converterAlsoRowPaddingV = 5;
  static const double converterAlsoValueGap = 12;
  static const double converterSheetPaddingBottom = 18;
  static const double converterKeypadGap = 12;
  static const double converterPickerTitleGap = 8;
  static const double converterPickerRowHeight = 48;
  static const double converterPickerCheck = 20;
  static const double converterPickerMaxHeight = 0.7;

  // Currency (screen 08)
  static const double currencyTopPaddingTop = 18;
  static const double currencyTopPaddingSide = 24;
  static const double currencyTopPaddingBottom = 24;
  static const double currencyTopGap = 12;
  static const double currencyBasePillPaddingV = 8;
  static const double currencyBasePillPaddingH = 12;
  static const double currencyBasePillRadius = 12;
  static const double currencyBasePillGap = 8;
  static const double currencyBaseArrow = 14;
  static const double currencyAmountHeight = 62;
  static const double currencyStatusDot = 8;
  static const double currencyStatusGap = 8;
  static const double currencySheetPaddingTop = 12;
  static const double currencySheetPaddingSide = 20;
  static const double currencySheetGap = 10;
  static const double currencyRowPaddingV = 10;
  static const double currencyRowPaddingH = 12;
  static const double currencyRowRadius = 16;
  static const double currencyRowGap = 12;
  static const double currencyCodeWidth = 48;
  static const double currencyCodeHeight = 40;
  static const double currencyCodeRadius = 12;
  static const double currencyRowContentGap = 2;
  static const double currencyAddHeight = 48;
  static const double currencyAddRadius = 16;
  static const double currencyAddBottom = 14;
  static const double currencyAddDash = 5;
  static const double currencyAddDashGap = 4;
  static const double currencyPickerMaxHeight = 0.7;
  static const double currencyPickerTitleGap = 8;
  static const double currencyPickerSearchHeight = 44;
  static const double currencyPickerRowHeight = 52;
  static const double currencyPickerChipWidth = 44;
  static const double currencyPickerChipHeight = 32;
  static const double currencyPickerCheck = 20;

  // Tools hub (screen 09)
  static const double toolsHeaderPaddingBottom = 22;
  static const double toolsContentPaddingTop = 16;
  static const double toolsContentPaddingBottom = 16;
  static const double toolsGridGap = 10;
  static const double toolsCardHeight = 92;
  static const double toolsCardPaddingV = 12;
  static const double toolsCardPaddingH = 14;
  static const double toolsCardTextGap = 1;
  static const double toolsChipHeight = 30;
  static const double toolsChipMinWidth = 36;
  static const double toolsChipPaddingH = 8;
  static const int toolsGridColumns = 2;

  // Tool page (screen 10)
  static const double toolShareIcon = 20;
  static const double toolResultPaddingTop = 14;
  static const double toolResultPaddingSide = 24;
  static const double toolResultPaddingBottom = 24;
  static const double toolResultGap = 4;
  static const double toolSheetPaddingTop = 12;
  static const double toolSheetPaddingSide = 20;
  static const double toolSheetPaddingBottom = 18;
  static const double toolSheetGap = 14;
  static const double toolActionHeight = 52;
  static const double toolActionRadius = 16;
  static const double toolNotePadding = 16;
  static const double toolNoteGap = 8;

  // Loan page (screen 10)
  static const double toolFieldHeight = 50;
  static const double toolFieldPaddingH = 14;
  static const double toolLabelGap = 6;
  static const double toolDateIcon = 18;
  static const double toolRateChipHeight = 44;
  static const double toolRateChipGap = 8;
  static const double toolTenureGap = 10;
  static const double toolSegmentPadding = 3;
  static const double toolBreakdownPadding = 14;
  static const double toolBreakdownGap = 8;
  static const double toolBarHeight = 12;
  static const double toolBarRadius = 6;
  static const double toolLegendSize = 10;
  static const double toolLegendRadius = 3;
  static const double toolLegendGap = 6;
  static const double toolTotalPaddingTop = 8;
  static const double toolScheduleHeightFactor = 0.85;
  static const double toolScheduleTitleGap = 2;
  static const double toolScheduleHeaderGap = 10;
  static const double toolScheduleRowPaddingV = 8;
  static const double toolScheduleRowPaddingH = 4;
  static const double toolScheduleMonthWidth = 44;
  static const double toolScheduleClose = 20;

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
  static const Duration toggle = Duration(milliseconds: 120);
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
  static const TextStyle keyFunctionStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: 19,
    fontWeight: bold,
  );
  static const TextStyle keyFunctionActive = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: bold,
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
  static const TextStyle hubItemTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: medium,
  );
  static const TextStyle hubChip = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: bold,
  );
  static const TextStyle hubCurrencyGlyph = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: bold,
  );
  static const TextStyle converterUnitPill = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: medium,
  );
  static const TextStyle converterAlsoTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: bold,
  );
  static const TextStyle converterKeyNumber = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: regular,
  );
  static const TextStyle converterKeyFunction = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: bold,
  );
  static const TextStyle converterError = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: medium,
  );

  // Currency (screen 08)
  static const TextStyle currencyAmount = TextStyle(
    fontFamily: fontFamily,
    fontSize: 52,
    fontWeight: medium,
    height: 1.05,
  );
  static const TextStyle currencyBaseCode = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: bold,
  );
  static const TextStyle currencyBaseName = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: regular,
  );
  static const TextStyle currencyStatus = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: regular,
  );
  static const TextStyle currencyCode = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: bold,
  );
  static const TextStyle currencyName = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: regular,
  );
  static const TextStyle currencyRate = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: regular,
  );
  static const TextStyle currencyValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: medium,
  );
  static const TextStyle currencyAdd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: medium,
  );

  // Tools (screens 09–10)
  static const TextStyle toolSymbol = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: bold,
    height: 1,
  );
  static const TextStyle toolName = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: medium,
    height: 1.2,
  );
  static const TextStyle toolSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: regular,
    height: 1.2,
  );
  static const TextStyle toolResultLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: regular,
  );
  static const TextStyle toolResult = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    fontWeight: medium,
    height: 1.05,
  );
  static const TextStyle toolAction = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: medium,
  );

  // Loan page (screen 10)
  static const TextStyle toolFieldLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: medium,
  );
  static const TextStyle toolFieldValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: regular,
  );
  static const TextStyle toolRateChip = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: bold,
  );
  static const TextStyle toolBreakdownRow = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: regular,
  );
  static const TextStyle toolBreakdownTotal = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: bold,
  );
  static const TextStyle toolScheduleHeader = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: medium,
  );
  static const TextStyle toolScheduleCell = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
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

  // History (screen 04)
  static const TextStyle historyDay = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: bold,
  );
  static const TextStyle historyExpression = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: regular,
  );
  static const TextStyle historyResult = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: medium,
  );
  static const TextStyle historyAction = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: medium,
  );
  static const TextStyle historyEmpty = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: regular,
  );
  static const TextStyle historyMenu = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: medium,
  );
  static const TextStyle memorySlot = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: regular,
  );
  static const TextStyle memoryValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: medium,
  );
  static const TextStyle memoryRecall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: bold,
  );
  static const TextStyle memoryAdjust = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: regular,
  );

  // Settings (screen 05)
  static const TextStyle sectionLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: bold,
  );
  static const TextStyle settingsPill = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: regular,
  );
  static const TextStyle settingsValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: medium,
  );
  static const TextStyle stepperGlyph = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: regular,
  );
  static const TextStyle clearButton = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: medium,
  );

  // Programmer (screen 03)
  static const TextStyle programmerValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: 44,
    fontWeight: medium,
    height: 1.05,
  );

  /// The big line is smaller in BIN so 32 bits stay readable (screen 03).
  static const TextStyle programmerValueBinary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: medium,
    height: 1.05,
  );

  static const TextStyle baseRowName = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: bold,
    // Explicit heights keep the fixed-height display stable across platforms
    // (the bundled font and the monospace fallback have different metrics).
    height: 1.2,
  );

  /// The design sets the base rows in Ubuntu Mono; the app bundles only Ubuntu,
  /// so the platform's monospace face keeps the digit columns aligned.
  static const TextStyle baseRowValue = TextStyle(
    fontFamily: 'monospace',
    fontSize: 16,
    fontWeight: regular,
    height: 1.2,
  );

  /// Line 1 of the display: the source being typed (SPEC §1.1).
  static const TextStyle programmerExpression = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: regular,
    height: 1.2,
  );
}
