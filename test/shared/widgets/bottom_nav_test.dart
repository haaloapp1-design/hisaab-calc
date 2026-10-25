import 'package:calculator/shared/widgets/bottom_nav.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:calculator/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(BottomNav nav) => MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: nav),
  );

  Finder inNav(Finder matching) =>
      find.descendant(of: find.byType(BottomNav), matching: matching);

  testWidgets('renders the four destinations in order', (tester) async {
    await tester.pumpWidget(
      wrap(BottomNav(currentIndex: 0, onSelected: (_) {})),
    );

    expect(inNav(find.text('Calculator')), findsOneWidget);
    expect(inNav(find.text('Convert')), findsOneWidget);
    expect(inNav(find.text('Tools')), findsOneWidget);
    expect(inNav(find.text('History')), findsOneWidget);

    final double calculatorX = tester.getCenter(inNav(find.text('Calculator'))).dx;
    final double convertX = tester.getCenter(inNav(find.text('Convert'))).dx;
    final double toolsX = tester.getCenter(inNav(find.text('Tools'))).dx;
    final double historyX = tester.getCenter(inNav(find.text('History'))).dx;
    expect(calculatorX < convertX, isTrue);
    expect(convertX < toolsX, isTrue);
    expect(toolsX < historyX, isTrue);
  });

  testWidgets('the active destination gets the pill and primary colour', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(BottomNav(currentIndex: 0, onSelected: (_) {})),
    );

    expect(
      tester.widget<Icon>(find.byIcon(Icons.calculate_outlined)).color,
      AppColors.primary,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.swap_horiz_rounded)).color,
      AppColors.inkMuted,
    );

    final Material active = tester.widget<Material>(
      find
          .ancestor(
            of: find.byIcon(Icons.calculate_outlined),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(active.color, AppColors.keyOperator);

    final Material inactive = tester.widget<Material>(
      find
          .ancestor(
            of: find.byIcon(Icons.swap_horiz_rounded),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(inactive.color, Colors.transparent);
  });

  testWidgets('selecting a destination reports its index', (tester) async {
    int? selected;
    await tester.pumpWidget(
      wrap(
        BottomNav(
          currentIndex: 0,
          onSelected: (int index) => selected = index,
        ),
      ),
    );

    await tester.tap(inNav(find.text('Tools')));
    expect(selected, 2);

    await tester.tap(inNav(find.text('History')));
    expect(selected, 3);
  });

  testWidgets('the top divider and item sizes come from the tokens', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(BottomNav(currentIndex: 0, onSelected: (_) {})),
    );

    final Container bar = tester.widget<Container>(
      find.byKey(const Key('bottom-nav')),
    );
    final BoxDecoration decoration = bar.decoration! as BoxDecoration;
    final Border border = decoration.border! as Border;
    expect(border.top.color, AppColors.navDivider);
    expect(border.top.width, AppSizes.borderWidth);

    expect(
      tester.getSize(find.byIcon(Icons.calculate_outlined)),
      const Size.square(AppSizes.navIcon),
    );
    final Size itemSize = tester.getSize(
      find
          .ancestor(
            of: find.byIcon(Icons.calculate_outlined),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(itemSize.height, greaterThanOrEqualTo(AppSizes.minTapTarget));
  });
}
