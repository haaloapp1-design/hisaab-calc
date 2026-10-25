import 'package:calculator/core/engine/angle_mode.dart';
import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/features/calculator/calculator_controller.dart';
import 'package:calculator/features/settings/settings_controller.dart';
import 'package:calculator/features/settings/settings_model.dart';
import 'package:calculator/features/settings/settings_page.dart';
import 'package:calculator/features/settings/widgets/accent_selector.dart';
import 'package:calculator/features/settings/widgets/decimal_stepper.dart';
import 'package:calculator/features/settings/widgets/settings_section.dart';
import 'package:calculator/features/settings/widgets/theme_selector.dart';
import 'package:calculator/features/settings/widgets/toggle_switch.dart';
import 'package:calculator/shared/widgets/blue_header.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:calculator/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app(MemoryKvStore store) => ProviderScope(
    overrides: [kvStoreProvider.overrideWithValue(store)],
    child: MaterialApp(theme: AppTheme.light(), home: const SettingsPage()),
  );

  /// The screens in `docs/screens/` are 390×844.
  void designSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<Settings> persisted(MemoryKvStore store) async =>
      Settings.decode((await store.getString(SettingsController.key))!);

  testWidgets('renders the header, four cards, every row and the version', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app(MemoryKvStore()));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(BlueHeader),
        matching: find.text('Settings'),
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Back'), findsOneWidget);

    for (final String title in <String>[
      'Appearance',
      'Calculation',
      'Feel',
      'Data',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.byType(SettingsSection), findsNWidgets(4));
    expect(find.byKey(const Key('settings-card')), findsNWidgets(4));

    for (final String label in <String>[
      'Theme',
      'Accent colour',
      'Angle unit',
      'Decimal places',
      'Thousands separator',
      'Vibrate on key press',
      'Key sounds',
      'Keep history for',
      'Clear all saved data',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('Version 1.0.0'), findsOneWidget);

    // Defaults from SPEC §3 / the design.
    expect(
      tester.widget<ThemeSelector>(find.byType(ThemeSelector)).value,
      AppThemeMode.system,
    );
    expect(
      tester.widget<AccentSelector>(find.byType(AccentSelector)).value,
      AccentSwatch.cobalt,
    );
    expect(
      tester.widget<DecimalStepper>(find.byType(DecimalStepper)).value,
      isNull,
    );
    expect(find.text('Degrees'), findsOneWidget);
    expect(find.text('30 days'), findsOneWidget);
    expect(
      tester.widget<ToggleSwitch>(
        find.byKey(const Key('switch-thousands')),
      ).value,
      isTrue,
    );
    expect(
      tester.widget<ToggleSwitch>(find.byKey(const Key('switch-sounds'))).value,
      isFalse,
    );
  });

  testWidgets('uses the screen 05 sizes, colours and header paddings', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app(MemoryKvStore()));
    await tester.pumpAndSettle();

    final BlueHeader header = tester.widget<BlueHeader>(
      find.byType(BlueHeader),
    );
    expect(header.rounded, isTrue);
    expect(header.bottomPadding, AppSizes.headerSettingsPaddingBottom);
    expect(
      tester.getSize(find.byKey(const Key('blue-header'))).height,
      AppSizes.headerPaddingTop +
          AppSizes.minTapTarget +
          AppSizes.headerSettingsPaddingBottom,
    );

    final Container card = tester.widget<Container>(
      find.byKey(const Key('settings-card')).first,
    );
    final BoxDecoration cardDecoration = card.decoration! as BoxDecoration;
    expect(cardDecoration.color, AppColors.sheet);
    expect(
      cardDecoration.borderRadius,
      BorderRadius.circular(AppRadii.cardLarge),
    );
    expect(
      card.padding,
      const EdgeInsets.symmetric(
        horizontal: AppSizes.settingsCardPaddingH,
        vertical: AppSizes.settingsCardPaddingV,
      ),
    );

    // Theme track and its selected/unselected pills.
    final Container track = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(ThemeSelector),
            matching: find.byType(Container),
          )
          .first,
    );
    final BoxDecoration trackDecoration = track.decoration! as BoxDecoration;
    expect(trackDecoration.color, AppColors.selectorTrack);
    expect(
      trackDecoration.borderRadius,
      BorderRadius.circular(AppRadii.settingsTrack),
    );
    expect(
      track.padding,
      const EdgeInsets.all(AppSizes.settingsTrackPadding),
    );

    final Container selectedPill = tester.widget<Container>(
      find.descendant(
        of: find.byKey(const Key('theme-system')),
        matching: find.byType(Container),
      ),
    );
    expect(
      (selectedPill.decoration! as BoxDecoration).color,
      AppColors.onPrimary,
    );
    final Text selectedLabel = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('theme-system')),
        matching: find.text('System'),
      ),
    );
    expect(selectedLabel.style?.fontSize, 13);
    expect(selectedLabel.style?.fontWeight, AppTypography.bold);
    expect(selectedLabel.style?.color, AppColors.primary);

    final Text unselectedLabel = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('theme-light')),
        matching: find.text('Light'),
      ),
    );
    expect(unselectedLabel.style?.fontWeight, AppTypography.regular);
    expect(unselectedLabel.style?.color, AppColors.inkMuted);

    // Accent dots: 28 px, selected gets the white border and colour ring.
    expect(
      tester.getSize(find.byKey(const Key('accent-cobalt'))),
      const Size.square(AppSizes.accentDot),
    );
    final Container selectedDot = tester.widget<Container>(
      find.descendant(
        of: find.byKey(const Key('accent-cobalt')),
        matching: find.byType(Container),
      ),
    );
    final BoxDecoration dotDecoration = selectedDot.decoration! as BoxDecoration;
    expect(dotDecoration.color, AppColors.primary);
    expect(
      dotDecoration.border,
      Border.all(
        color: AppColors.onPrimary,
        width: AppSizes.accentSelectedBorder,
      ),
    );
    expect(dotDecoration.boxShadow, hasLength(1));
    expect(dotDecoration.boxShadow!.single.spreadRadius, AppSizes.accentRing);
    expect(dotDecoration.boxShadow!.single.blurRadius, 0);

    expect(
      tester.getSize(find.byKey(const Key('switch-haptics'))),
      const Size(AppSizes.switchWidth, AppSizes.switchHeight),
    );
    expect(
      tester.getSize(find.byKey(const Key('clear-data'))).height,
      AppSizes.clearButtonHeight,
    );
  });

  testWidgets('theme and accent rows save the choice', (tester) async {
    designSurface(tester);
    final MemoryKvStore store = MemoryKvStore();
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('theme-dark')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('accent-rust')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<ThemeSelector>(find.byType(ThemeSelector)).value,
      AppThemeMode.dark,
    );
    expect(
      tester.widget<AccentSelector>(find.byType(AccentSelector)).value,
      AccentSwatch.rust,
    );
    final Settings saved = await persisted(store);
    expect(saved.themeMode, AppThemeMode.dark);
    expect(saved.accent, AccentSwatch.rust);
  });

  testWidgets('the angle row toggles Degrees and Radians', (tester) async {
    designSurface(tester);
    final MemoryKvStore store = MemoryKvStore();
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Angle unit'));
    await tester.pumpAndSettle();

    expect(find.text('Radians'), findsOneWidget);
    expect((await persisted(store)).angleMode, AngleMode.rad);

    await tester.tap(find.text('Angle unit'));
    await tester.pumpAndSettle();

    expect(find.text('Degrees'), findsOneWidget);
    expect((await persisted(store)).angleMode, AngleMode.deg);
  });

  testWidgets('the decimal stepper walks Auto → 0 → 1 and back', (
    tester,
  ) async {
    designSurface(tester);
    final MemoryKvStore store = MemoryKvStore();
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();

    expect(find.text('Auto'), findsOneWidget);

    await tester.tap(find.byKey(const Key('decimal-more')));
    await tester.pumpAndSettle();
    expect(find.text('0'), findsOneWidget);
    expect((await persisted(store)).decimalPlaces, 0);

    await tester.tap(find.byKey(const Key('decimal-more')));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('decimal-fewer')));
    await tester.pumpAndSettle();
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byKey(const Key('decimal-fewer')));
    await tester.pumpAndSettle();
    expect(find.text('Auto'), findsOneWidget);
    expect((await persisted(store)).decimalPlaces, isNull);
  });

  testWidgets('every switch flips and saves', (tester) async {
    designSurface(tester);
    final MemoryKvStore store = MemoryKvStore();
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('switch-thousands')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('switch-haptics')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('switch-sounds')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<ToggleSwitch>(
        find.byKey(const Key('switch-thousands')),
      ).value,
      isFalse,
    );
    expect(
      tester.widget<ToggleSwitch>(
        find.byKey(const Key('switch-haptics')),
      ).value,
      isFalse,
    );
    expect(
      tester.widget<ToggleSwitch>(find.byKey(const Key('switch-sounds'))).value,
      isTrue,
    );

    final Settings saved = await persisted(store);
    expect(saved.thousandsSeparator, isFalse);
    expect(saved.haptics, isFalse);
    expect(saved.keySounds, isTrue);
  });

  testWidgets('the retention row walks the four choices', (tester) async {
    designSurface(tester);
    final MemoryKvStore store = MemoryKvStore();
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();

    expect(find.text('30 days'), findsOneWidget);

    await tester.tap(find.text('Keep history for'));
    await tester.pumpAndSettle();
    expect(find.text('90 days'), findsOneWidget);

    await tester.tap(find.text('Keep history for'));
    await tester.pumpAndSettle();
    expect(find.text('Forever'), findsOneWidget);

    await tester.tap(find.text('Keep history for'));
    await tester.pumpAndSettle();
    expect(find.text('7 days'), findsOneWidget);
    expect((await persisted(store)).historyRetention, HistoryRetention.days7);

    await tester.tap(find.text('Keep history for'));
    await tester.pumpAndSettle();
    expect(find.text('30 days'), findsOneWidget);
  });

  testWidgets('Clear asks first, then wipes settings, Ans and mode', (
    tester,
  ) async {
    designSurface(tester);
    final MemoryKvStore store = MemoryKvStore(
      <String, String>{
        SettingsController.key: const Settings(
          accent: AccentSwatch.rust,
        ).encode(),
        CalculatorController.ansKey: '42',
        CalculatorController.modeKey: 'scientific',
      },
    );
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();

    expect(
      tester.widget<AccentSelector>(find.byType(AccentSelector)).value,
      AccentSwatch.rust,
    );

    await tester.tap(find.byKey(const Key('clear-data')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('clear-dialog')), findsOneWidget);
    expect(find.text('Clear all saved data?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('clear-cancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('clear-dialog')), findsNothing);
    expect(await store.getString(SettingsController.key), isNotNull);
    expect(await store.getString(CalculatorController.ansKey), '42');

    await tester.tap(find.byKey(const Key('clear-data')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('clear-confirm')));
    await tester.pumpAndSettle();

    expect(await store.getString(SettingsController.key), isNull);
    expect(await store.getString(CalculatorController.ansKey), isNull);
    expect(await store.getString(CalculatorController.modeKey), isNull);
    expect(
      tester.widget<ThemeSelector>(find.byType(ThemeSelector)).value,
      AppThemeMode.system,
    );
    expect(
      tester.widget<AccentSelector>(find.byType(AccentSelector)).value,
      AccentSwatch.cobalt,
    );
    expect(find.text('Degrees'), findsOneWidget);
    expect(find.text('Auto'), findsOneWidget);
    expect(find.text('30 days'), findsOneWidget);
  });
}
