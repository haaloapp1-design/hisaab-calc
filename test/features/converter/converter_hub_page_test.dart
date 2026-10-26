import 'package:calculator/core/currency/currency_repository.dart';
import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/core/units/converter_memory.dart';
import 'package:calculator/core/units/unit_catalog.dart';
import 'package:calculator/features/converter/converter_hub_page.dart';
import 'package:calculator/features/converter/converter_memory_controller.dart';
import 'package:calculator/features/converter/converter_page.dart';
import 'package:calculator/features/converter/widgets/hub_search_field.dart';
import 'package:calculator/features/currency/currency_page.dart';
import 'package:calculator/features/currency/currency_repository_provider.dart';
import 'package:calculator/shared/widgets/blue_header.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  Widget app({
    ValueChanged<UnitCategory>? onCategorySelected,
    ValueChanged<UnitMatch>? onUnitSelected,
    VoidCallback? onCurrencyTap,
    MemoryKvStore? store,
  }) => ProviderScope(
    overrides: [kvStoreProvider.overrideWithValue(store ?? MemoryKvStore())],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: ConverterHubPage(
        onCategorySelected: onCategorySelected,
        onUnitSelected: onUnitSelected,
        onCurrencyTap: onCurrencyTap,
      ),
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

  testWidgets('opens the unit converter for a category and a search result', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('hub-category-length')));
    await tester.pumpAndSettle();

    final ConverterPage categoryPage = tester.widget<ConverterPage>(
      find.byType(ConverterPage),
    );
    expect(categoryPage.category, UnitCategory.length);
    expect(categoryPage.from, isNull);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ConverterPage), findsNothing);

    await tester.enterText(searchField(), 'marla');
    await tester.pump();
    await tester.tap(find.byKey(const Key('hub-result-area-marla')));
    await tester.pumpAndSettle();

    final ConverterPage unitPage = tester.widget<ConverterPage>(
      find.byType(ConverterPage),
    );
    expect(unitPage.category, UnitCategory.area);
    expect(unitPage.from?.id, 'marla');
  });

  testWidgets('has no favourites card before a pair is starred', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('hub-favourites')), findsNothing);
  });

  testWidgets('shows the starred pairs and opens one', (tester) async {
    designSurface(tester);
    final ConverterPair pair = ConverterPair(
      category: UnitCategory.length,
      from: UnitCatalog.byId('km')!,
      to: UnitCatalog.byId('mi')!,
    );
    final MemoryKvStore store = MemoryKvStore(<String, String>{
      ConverterMemoryController.key: ConverterMemory(
        last: pair,
        favourites: <ConverterPair>[pair],
      ).encode(),
    });

    await tester.pumpWidget(app(store: store));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('hub-favourites')), findsOneWidget);
    expect(find.text('Favourites'), findsOneWidget);
    expect(find.text('Length'), findsWidgets);
    expect(find.text('km → mi'), findsOneWidget);

    await tester.tap(find.byKey(const Key('hub-favourite-length-km-mi')));
    await tester.pumpAndSettle();

    final ConverterPage page = tester.widget<ConverterPage>(
      find.byType(ConverterPage),
    );
    expect(page.category, UnitCategory.length);
    expect(page.from?.id, 'km');
    expect(page.to?.id, 'mi');
  });

  testWidgets('a starred pair from the page appears on the hub', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('hub-category-length')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add to favourites'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('hub-favourites')), findsOneWidget);
    expect(find.byKey(const Key('hub-favourite-length-km-mi')), findsOneWidget);
  });

  testWidgets('opens a category on its remembered pair', (tester) async {
    designSurface(tester);
    final MemoryKvStore store = MemoryKvStore(<String, String>{
      ConverterMemoryController.key: ConverterMemory(
        last: ConverterPair(
          category: UnitCategory.length,
          from: UnitCatalog.byId('m')!,
          to: UnitCatalog.byId('ft')!,
        ),
      ).encode(),
    });

    await tester.pumpWidget(app(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('hub-category-length')));
    await tester.pumpAndSettle();

    final ConverterPage page = tester.widget<ConverterPage>(
      find.byType(ConverterPage),
    );
    expect(page.from, isNull);
    expect(page.to, isNull);
    expect(find.text('1 m = 3.28084 ft'), findsOneWidget);
  });

  testWidgets('the currency card opens the currency page by default', (
    tester,
  ) async {
    designSurface(tester);
    final MemoryKvStore store = MemoryKvStore();
    final CurrencyRepository repository = CurrencyRepository(
      store: store,
      client: MockClient(
        (http.Request request) async => http.Response(
          '{"result":"success","base_code":"USD",'
          '"rates":{"USD":1,"PKR":278.5}}',
          200,
        ),
      ),
      clock: () => DateTime.utc(2026, 10, 26, 12),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kvStoreProvider.overrideWithValue(store),
          currencyRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ConverterHubPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('hub-currency-card')));
    await tester.pumpAndSettle();

    expect(find.byType(CurrencyPage), findsOneWidget);
  });
}
