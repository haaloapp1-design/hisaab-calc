import 'package:calculator/core/units/unit_catalog.dart';
import 'package:calculator/features/converter/converter_hub_page.dart';
import 'package:calculator/features/converter/widgets/hub_search_field.dart';
import 'package:calculator/shared/widgets/blue_header.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app({
    ValueChanged<UnitCategory>? onCategorySelected,
    ValueChanged<UnitMatch>? onUnitSelected,
    VoidCallback? onCurrencyTap,
  }) => MaterialApp(
    theme: AppTheme.light(),
    home: ConverterHubPage(
      onCategorySelected: onCategorySelected,
      onUnitSelected: onUnitSelected,
      onCurrencyTap: onCurrencyTap,
    ),
  );

  /// The screens in `docs/screens/` are 390×844.
  void designSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Finder searchField() => find.byKey(const Key('hub-search-field'));

  testWidgets('shows the header, search, currency card and twelve tiles', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    expect(
      find.descendant(
        of: find.byType(BlueHeader),
        matching: find.text('Convert'),
      ),
      findsOneWidget,
    );
    expect(searchField(), findsOneWidget);
    expect(find.text(HubSearchField.hint), findsOneWidget);

    expect(find.byKey(const Key('hub-currency-card')), findsOneWidget);
    expect(find.text('Currency'), findsOneWidget);
    expect(
      find.text('Live rates, works offline with last saved rates'),
      findsOneWidget,
    );

    for (final UnitCategory category in UnitCategory.values) {
      expect(
        find.byKey(Key('hub-category-${category.name}')),
        findsOneWidget,
        reason: category.label,
      );
      expect(find.text(category.label), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(Key('hub-chip-${category.name}')),
          matching: find.text(category.hubSymbol),
        ),
        findsOneWidget,
        reason: category.label,
      );
    }
    expect(find.byKey(const Key('hub-search-results')), findsNothing);
  });

  testWidgets('uses the 390×844 design measurements', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    expect(
      tester.getSize(find.byKey(const Key('hub-search-box'))),
      const Size(350, 48),
    );
    expect(
      tester.getSize(find.byKey(const Key('hub-currency-card'))),
      const Size(350, 76),
    );
    expect(
      tester.getSize(find.byKey(const Key('hub-currency-icon'))),
      const Size(46, 46),
    );
    expect(
      tester.getSize(find.byKey(const Key('hub-category-length'))),
      const Size(110, 86),
    );
    expect(tester.getSize(find.byKey(const Key('hub-chip-length'))).height, 32);
    expect(
      tester.getSize(find.byKey(const Key('hub-category-grid'))).width,
      350,
    );
  });

  testWidgets('typing a unit replaces the hub with the search results', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    await tester.enterText(searchField(), 'inch');
    await tester.pump();

    expect(find.byKey(const Key('hub-currency-card')), findsNothing);
    expect(find.byKey(const Key('hub-category-grid')), findsNothing);
    expect(find.byKey(const Key('hub-search-results')), findsOneWidget);
    expect(find.text('Inch (in)'), findsOneWidget);
    expect(find.text('Square inch (in²)'), findsOneWidget);
    expect(find.text('Pound per square inch (psi)'), findsOneWidget);
  });

  testWidgets('a search without matches shows the empty state', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    await tester.enterText(searchField(), 'zzz');
    await tester.pump();

    expect(find.byKey(const Key('hub-search-empty')), findsOneWidget);
    expect(find.text('No units found'), findsOneWidget);
    expect(find.byKey(const Key('hub-search-results')), findsNothing);
  });

  testWidgets('clearing the search brings the hub back', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    await tester.enterText(searchField(), 'psi');
    await tester.pump();
    expect(find.byKey(const Key('hub-search-results')), findsOneWidget);

    await tester.enterText(searchField(), '  ');
    await tester.pump();

    expect(find.byKey(const Key('hub-category-grid')), findsOneWidget);
    expect(find.byKey(const Key('hub-currency-card')), findsOneWidget);
    expect(find.byKey(const Key('hub-search-results')), findsNothing);
  });

  testWidgets('trims the query before searching', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    await tester.enterText(searchField(), '  PSI  ');
    await tester.pump();

    expect(find.text('Pound per square inch (psi)'), findsOneWidget);
    expect(find.text('Pressure'), findsOneWidget);
  });

  testWidgets('tapping currency, a category and a result calls back', (
    tester,
  ) async {
    designSurface(tester);
    final List<UnitCategory> categories = <UnitCategory>[];
    final List<UnitMatch> units = <UnitMatch>[];
    int currencyTaps = 0;

    await tester.pumpWidget(
      app(
        onCategorySelected: categories.add,
        onUnitSelected: units.add,
        onCurrencyTap: () => currencyTaps++,
      ),
    );

    await tester.tap(find.byKey(const Key('hub-currency-card')));
    await tester.pump();
    expect(currencyTaps, 1);

    await tester.tap(find.byKey(const Key('hub-category-area')));
    await tester.pump();
    expect(categories, <UnitCategory>[UnitCategory.area]);

    await tester.enterText(searchField(), 'marla');
    await tester.pump();
    await tester.tap(find.byKey(const Key('hub-result-area-marla')));
    await tester.pump();

    expect(units, hasLength(1));
    expect(units.single.category, UnitCategory.area);
    expect(units.single.unit.id, 'marla');
  });
}
