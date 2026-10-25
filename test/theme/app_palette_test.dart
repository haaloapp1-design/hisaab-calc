import 'package:calculator/features/settings/accent_colors.dart';
import 'package:calculator/features/settings/settings_model.dart';
import 'package:calculator/theme/app_palette.dart';
import 'package:calculator/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light cobalt is exactly the DESIGN token set', () {
    const AppPalette palette = AppPalette.lightCobalt;

    expect(palette.primary, AppColors.primary);
    expect(palette.primaryDeep, AppColors.primaryDeep);
    expect(palette.primaryTrack, AppColors.primaryTrack);
    expect(palette.onPrimary, AppColors.onPrimary);
    expect(palette.onPrimaryMuted, AppColors.onPrimaryMuted);
    expect(palette.onPrimaryFaint, AppColors.onPrimaryFaint);
    expect(palette.dividerOnPrimary, AppColors.dividerOnPrimary);
    expect(palette.sheet, AppColors.sheet);
    expect(palette.background, AppColors.background);
    expect(palette.keyNumber, AppColors.keyNumber);
    expect(palette.keyNumberScientific, AppColors.keyNumberScientific);
    expect(palette.keyNumberBorder, AppColors.keyNumberBorder);
    expect(palette.keyFunction, AppColors.keyFunction);
    expect(palette.keyOperator, AppColors.keyOperator);
    expect(palette.keyOperatorBorder, AppColors.keyOperatorBorder);
    expect(palette.ink, AppColors.ink);
    expect(palette.inkMuted, AppColors.inkMuted);
    expect(palette.segmentedInactive, AppColors.segmentedInactive);
    expect(palette.divider, AppColors.divider);
    expect(palette.selectorTrack, AppColors.selectorTrack);
    expect(palette.switchOff, AppColors.switchOff);
    expect(palette.navDivider, AppColors.navDivider);
    expect(palette.disabled, AppColors.disabled);
    expect(palette.disabledBorder, AppColors.disabledBorder);
    expect(palette.warning, AppColors.warning);
    expect(palette.danger, AppColors.danger);
    expect(palette.dangerSurface, AppColors.dangerSurface);
  });

  test('the accent swatches map to the DESIGN colours', () {
    expect(AccentSwatch.cobalt.color, AppColors.primary);
    expect(AccentSwatch.teal.color, AppColors.accentTeal);
    expect(AccentSwatch.violet.color, AppColors.accentViolet);
    expect(AccentSwatch.rust.color, AppColors.accentRust);
  });

  test('every accent replaces primary and derives lighter tints', () {
    for (final AccentSwatch swatch in AccentSwatch.values) {
      final AppPalette palette = AppPalette.light(swatch.color);

      expect(palette.primary, swatch.color, reason: swatch.name);
      expect(palette.onPrimary, AppColors.onPrimary, reason: swatch.name);

      if (swatch == AccentSwatch.cobalt) {
        expect(palette, AppPalette.lightCobalt);
        continue;
      }

      expect(
        palette.primaryDeep.computeLuminance(),
        lessThan(palette.primary.computeLuminance()),
        reason: swatch.name,
      );
      for (final Color tint in <Color>[
        palette.primaryTrack,
        palette.onPrimaryMuted,
        palette.onPrimaryFaint,
        palette.dividerOnPrimary,
        palette.keyOperator,
        palette.keyOperatorBorder,
        palette.segmentedInactive,
      ]) {
        expect(
          tint.computeLuminance(),
          greaterThan(palette.primary.computeLuminance()),
          reason: swatch.name,
        );
      }
      expect(palette.sheet, AppColors.sheet, reason: swatch.name);
      expect(palette.background, AppColors.background, reason: swatch.name);
    }
  });

  test('dark uses the DESIGN palette and keeps the accent as primary', () {
    final AppPalette cobalt = AppPalette.dark(AppColors.primary);
    expect(cobalt.background, const Color(0xFF10142B));
    expect(cobalt.sheet, const Color(0xFF181D3A));
    expect(cobalt.keyNumber, const Color(0xFF222849));
    expect(cobalt.ink, const Color(0xFFE8EBFA));
    expect(cobalt.primary, AppColors.primary);
    expect(cobalt.onPrimary, AppColors.onPrimary);

    final AppPalette violet = AppPalette.dark(AppColors.accentViolet);
    expect(violet.primary, AppColors.accentViolet);
    expect(violet.background, cobalt.background);
    expect(violet.sheet, cobalt.sheet);
    expect(violet.ink, cobalt.ink);
    expect(violet.keyOperator, isNot(cobalt.keyOperator));
    expect(violet.keyOperator, isNot(violet.sheet));
    expect(violet.keyOperator, isNot(violet.primary));
  });

  testWidgets('of falls back to light cobalt outside an app theme', (
    tester,
  ) async {
    late AppPalette palette;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            palette = AppPalette.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(palette, AppPalette.lightCobalt);
  });

  test('lerp blends every colour between two palettes', () {
    final AppPalette light = AppPalette.lightCobalt;
    final AppPalette dark = AppPalette.dark(AppColors.accentRust);

    expect(light.lerp(dark, 0).primary, light.primary);
    expect(light.lerp(dark, 1).primary, dark.primary);
    expect(light.lerp(dark, 1).background, dark.background);

    final AppPalette half = light.lerp(dark, 0.5);
    expect(
      half.background,
      Color.lerp(light.background, dark.background, 0.5),
    );
    expect(half.lerp(null, 0.5), half);
  });
}
