import 'package:calculator/shared/widgets/blue_header.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:calculator/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(theme: AppTheme.light(), home: Scaffold(body: child));

  Container headerBox(WidgetTester tester) =>
      tester.widget<Container>(find.byKey(const Key('blue-header')));

  testWidgets('the standard header centres a 17 px title and keeps the side '
      'slots empty', (tester) async {
    await tester.pumpWidget(wrap(const BlueHeader(title: 'Calculator')));

    final Text title = tester.widget<Text>(find.text('Calculator'));
    expect(title.style?.fontSize, 17);
    expect(title.style?.fontWeight, AppTypography.medium);
    expect(title.style?.color, AppColors.onPrimary);
    expect(title.textAlign, TextAlign.center);

    // 800 px test surface: the title stays dead centre despite the slots.
    expect(tester.getCenter(find.text('Calculator')).dx, 400);

    expect(find.byIcon(Icons.chevron_left), findsNothing);
    expect(find.byKey(const Key('blue-header-back')), findsNothing);
    expect(find.byKey(const Key('blue-header-action')), findsNothing);
  });

  testWidgets('the header uses the design paddings and the primary colour', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const BlueHeader(title: 'History')));

    final Container box = headerBox(tester);
    expect(
      box.padding,
      const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.headerPaddingTop,
        AppSizes.screenPadding,
        0,
      ),
    );

    final BoxDecoration decoration = box.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.primary);
    expect(decoration.borderRadius, isNull);
    expect(tester.getSize(find.byKey(const Key('blue-header'))).height, 64);
  });

  testWidgets('back and action icons are 44 px targets that report taps', (
    tester,
  ) async {
    int backs = 0;
    int actions = 0;

    await tester.pumpWidget(
      wrap(
        BlueHeader(
          title: 'History',
          onBack: () => backs++,
          actionIcon: Icons.search_rounded,
          actionTooltip: 'Search history',
          onAction: () => actions++,
        ),
      ),
    );

    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byTooltip('Search history'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('blue-header-back'))),
      const Size.square(AppSizes.minTapTarget),
    );
    expect(
      tester.getSize(find.byKey(const Key('blue-header-action'))),
      const Size.square(AppSizes.minTapTarget),
    );
    expect(
      tester.getSize(find.byIcon(Icons.chevron_left)),
      const Size.square(AppSizes.headerIcon),
    );

    await tester.tap(find.byKey(const Key('blue-header-back')));
    await tester.tap(find.byKey(const Key('blue-header-action')));

    expect(backs, 1);
    expect(actions, 1);
  });

  testWidgets('the large variant is left aligned with an optional subtitle', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const BlueHeader(
          title: 'Tools',
          subtitle: 'Ready-made calculators for everyday sums',
          large: true,
        ),
      ),
    );

    final Text title = tester.widget<Text>(find.text('Tools'));
    expect(title.style?.fontSize, 26);
    expect(title.style?.fontWeight, AppTypography.medium);
    expect(title.style?.color, AppColors.onPrimary);

    final Text subtitle = tester.widget<Text>(
      find.text('Ready-made calculators for everyday sums'),
    );
    expect(subtitle.style?.fontSize, 14);
    expect(subtitle.style?.color, AppColors.onPrimaryMuted);

    final Container box = headerBox(tester);
    expect(
      box.padding,
      const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.hubHeaderPaddingTop,
        AppSizes.screenPadding,
        AppSizes.hubHeaderPaddingBottom,
      ),
    );
    expect(find.byIcon(Icons.chevron_left), findsNothing);
  });

  testWidgets('rounded rounds the bottom corners, standard does not', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const BlueHeader(title: 'Settings', rounded: true)),
    );

    final BoxDecoration rounded =
        headerBox(tester).decoration! as BoxDecoration;
    expect(
      rounded.borderRadius,
      const BorderRadius.vertical(bottom: Radius.circular(AppRadii.header)),
    );
  });

  testWidgets('the Settings header adds its 22 px bottom padding', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        BlueHeader(
          title: 'Settings',
          rounded: true,
          bottomPadding: AppSizes.headerSettingsPaddingBottom,
          onBack: () {},
        ),
      ),
    );

    final Container box = headerBox(tester);
    expect(
      box.padding,
      const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.headerPaddingTop,
        AppSizes.screenPadding,
        AppSizes.headerSettingsPaddingBottom,
      ),
    );
    expect(
      tester.getSize(find.byKey(const Key('blue-header'))).height,
      AppSizes.headerPaddingTop +
          AppSizes.minTapTarget +
          AppSizes.headerSettingsPaddingBottom,
    );
  });
}
