import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/core/units/converter_memory.dart';
import 'package:calculator/core/units/unit_catalog.dart';
import 'package:calculator/features/converter/converter_key.dart';
import 'package:calculator/features/converter/converter_memory_controller.dart';
import 'package:calculator/features/converter/converter_page.dart';
import 'package:calculator/features/history/history_controller.dart';
import 'package:calculator/features/history/history_entry.dart';
import 'package:calculator/shared/widgets/blue_header.dart';
import 'package:calculator/shared/widgets/white_sheet.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:calculator/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app({
    UnitCategory category = UnitCategory.length,
    Unit? from,
    Unit? to,
    VoidCallback? onFavourite,
    MemoryKvStore? store,
  }) => ProviderScope(
    overrides: [kvStoreProvider.overrideWithValue(store ?? MemoryKvStore())],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: ConverterPage(
        category: category,
        from: from,
        to: to,
        onFavourite: onFavourite,
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

  String textOf(WidgetTester tester, Key key) =>
      tester.widget<Text>(find.byKey(key)).data!;

  Finder pill(Key key, String label) =>
      find.descendant(of: find.byKey(key), matching: find.text(label));

  Finder rowValue(String unitId, String value) => find.descendant(
    of: find.byKey(Key('converter-also-$unitId')),
    matching: find.text(value),
  );

  Future<void> tapKey(WidgetTester tester, ConverterKey key) async {
    await tester.tap(find.byKey(Key('converter-key-${key.name}')));
    await tester.pump();
  }

  List<String> captureClipboard(WidgetTester tester) {
    final List<String> copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'Clipboard.setData') {
          final Map<Object?, Object?> arguments =
              call.arguments as Map<Object?, Object?>;
          copied.add(arguments['text']! as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    return copied;
  }

  testWidgets('opens Length on km → mi with the design layout', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(BlueHeader),
        matching: find.text('Length'),
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byTooltip('Add to favourites'), findsOneWidget);

    expect(pill(const Key('converter-from-unit'), 'Kilometre (km)'), findsOne);
    expect(pill(const Key('converter-to-unit'), 'Mile (mi)'), findsOne);
    expect(textOf(tester, const Key('converter-from-value')), '0');
    expect(textOf(tester, const Key('converter-to-value')), '0');
    expect(textOf(tester, const Key('converter-rule')), '1 km = 0.621371 mi');
    expect(textOf(tester, const Key('converter-also-heading')), '0 km is also');

    for (final String id in <String>['m', 'ft', 'yd', 'nmi']) {
      expect(find.byKey(Key('converter-also-$id')), findsOneWidget);
      expect(rowValue(id, '0'), findsOneWidget);
    }

    for (final ConverterKey key in ConverterKey.values) {
      expect(
        find.byKey(Key('converter-key-${key.name}')),
        findsOneWidget,
        reason: key.name,
      );
    }
    expect(ConverterKey.values, hasLength(16));
  });

  testWidgets('uses the 390×844 design measurements', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const Key('converter-from-card'))).width,
      350,
    );
    expect(
      tester.getSize(find.byKey(const Key('converter-to-card'))).width,
      350,
    );
    expect(
      tester.getSize(find.byKey(const Key('converter-from-card'))).height,
      tester.getSize(find.byKey(const Key('converter-to-card'))).height,
    );
    expect(
      tester.getSize(find.byKey(const Key('converter-swap'))),
      const Size(48, 48),
    );
    expect(
      tester.getSize(find.byKey(const Key('converter-key-five'))),
      const Size(80, 52),
    );
    expect(find.byType(WhiteSheet), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('white-sheet-handle'))),
      const Size(44, 4),
    );
    expect(AppSizes.keyHeightConverter, 52);
  });

  testWidgets('converts live while typing', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tapKey(tester, ConverterKey.five);

    expect(textOf(tester, const Key('converter-from-value')), '5');
    expect(textOf(tester, const Key('converter-to-value')), '3.10686');
    expect(textOf(tester, const Key('converter-also-heading')), '5 km is also');
    expect(rowValue('m', '5,000'), findsOneWidget);
    expect(rowValue('ft', '16,404.2'), findsOneWidget);
    expect(rowValue('yd', '5,468.07'), findsOneWidget);
    expect(rowValue('nmi', '2.69978'), findsOneWidget);
  });

  testWidgets('swap exchanges the pair and keeps the amount', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tapKey(tester, ConverterKey.five);
    await tester.tap(find.byKey(const Key('converter-swap')));
    await tester.pump();

    expect(pill(const Key('converter-from-unit'), 'Mile (mi)'), findsOne);
    expect(pill(const Key('converter-to-unit'), 'Kilometre (km)'), findsOne);
    expect(textOf(tester, const Key('converter-from-value')), '5');
    expect(textOf(tester, const Key('converter-to-value')), '8.04672');
    expect(textOf(tester, const Key('converter-rule')), '1 mi = 1.60934 km');
  });

  testWidgets('the unit picker lists the category and changes the side', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('converter-to-unit')));
    await tester.pumpAndSettle();

    expect(find.text('To unit'), findsOneWidget);
    for (final Unit unit in UnitCatalog.of(UnitCategory.length).units) {
      expect(
        find.byKey(Key('picker-unit-${unit.id}')),
        findsOneWidget,
        reason: unit.id,
      );
    }

    await tester.tap(find.byKey(const Key('picker-unit-ft')));
    await tester.pumpAndSettle();

    expect(pill(const Key('converter-to-unit'), 'Foot (ft)'), findsOne);
    expect(textOf(tester, const Key('converter-rule')), '1 km = 3,280.84 ft');
    expect(find.text('To unit'), findsNothing);
  });

  testWidgets('the From picker changes the From side', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('converter-from-unit')));
    await tester.pumpAndSettle();
    expect(find.text('From unit'), findsOneWidget);

    await tester.tap(find.byKey(const Key('picker-unit-m')));
    await tester.pumpAndSettle();

    expect(pill(const Key('converter-from-unit'), 'Metre (m)'), findsOne);
    expect(pill(const Key('converter-to-unit'), 'Mile (mi)'), findsOne);
  });

  testWidgets('keypad editing follows the converter input rules', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tapKey(tester, ConverterKey.zero);
    await tapKey(tester, ConverterKey.zero);
    expect(textOf(tester, const Key('converter-from-value')), '0');

    await tapKey(tester, ConverterKey.five);
    await tapKey(tester, ConverterKey.doubleZero);
    expect(textOf(tester, const Key('converter-from-value')), '500');

    await tapKey(tester, ConverterKey.dot);
    expect(textOf(tester, const Key('converter-from-value')), '500.');

    await tapKey(tester, ConverterKey.backspace);
    expect(textOf(tester, const Key('converter-from-value')), '500');

    await tapKey(tester, ConverterKey.clear);
    expect(textOf(tester, const Key('converter-from-value')), '0');
    expect(textOf(tester, const Key('converter-to-value')), '0');
  });

  testWidgets('below absolute zero shows the §12 error', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app(category: UnitCategory.temperature));
    await tester.pumpAndSettle();

    await tapKey(tester, ConverterKey.three);
    await tapKey(tester, ConverterKey.doubleZero);
    await tapKey(tester, ConverterKey.toggleSign);

    expect(textOf(tester, const Key('converter-from-value')), '−300');
    expect(
      textOf(tester, const Key('converter-to-value')),
      'Below absolute zero',
    );
    expect(rowValue('kelvin', '—'), findsOneWidget);
  });

  testWidgets('Copy puts the To value on the clipboard', (tester) async {
    designSurface(tester);
    final List<String> copied = captureClipboard(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tapKey(tester, ConverterKey.five);
    await tester.tap(find.byKey(const Key('converter-key-copy')));
    await tester.pumpAndSettle();

    expect(copied, <String>['3.10686']);
    expect(find.text('Copied'), findsOneWidget);
  });

  testWidgets('a unit from the hub search opens as From', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(
      app(category: UnitCategory.area, from: UnitCatalog.byId('marla')),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(BlueHeader), matching: find.text('Area')),
      findsOneWidget,
    );
    expect(pill(const Key('converter-from-unit'), 'Marla'), findsOne);
    expect(pill(const Key('converter-to-unit'), 'Square foot (ft²)'), findsOne);
    expect(textOf(tester, const Key('converter-rule')), '1 marla = 272.25 ft²');
  });

  testWidgets('the star reports its tap for T38', (tester) async {
    designSurface(tester);
    int favourites = 0;
    await tester.pumpWidget(app(onFavourite: () => favourites++));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add to favourites'));
    await tester.pump();

    expect(favourites, 1);
  });

  testWidgets('the star saves and removes the current pair', (tester) async {
    designSurface(tester);
    final MemoryKvStore store = MemoryKvStore();
    await tester.pumpWidget(app(store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add to favourites'));
    await tester.pumpAndSettle();

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(ConverterPage)),
    );
    ConverterMemory memory = container.read(converterMemoryProvider);
    expect(memory.favourites, hasLength(1));
    expect(memory.favourites.single.category, UnitCategory.length);
    expect(memory.favourites.single.from.id, 'km');
    expect(memory.favourites.single.to.id, 'mi');
    expect(find.byTooltip('Remove from favourites'), findsOneWidget);
    expect(find.text('Added to favourites'), findsOneWidget);
    expect(
      ConverterMemory.decode(
        await store.getString(ConverterMemoryController.key),
      ).favourites,
      hasLength(1),
    );

    await tester.tap(find.byTooltip('Remove from favourites'));
    await tester.pumpAndSettle();

    memory = container.read(converterMemoryProvider);
    expect(memory.favourites, isEmpty);
    expect(find.byTooltip('Add to favourites'), findsOneWidget);
    expect(find.text('Removed from favourites'), findsOneWidget);
  });

  testWidgets('opens with the remembered pair for the category', (
    tester,
  ) async {
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

    expect(pill(const Key('converter-from-unit'), 'Metre (m)'), findsOne);
    expect(pill(const Key('converter-to-unit'), 'Foot (ft)'), findsOne);
    expect(textOf(tester, const Key('converter-rule')), '1 m = 3.28084 ft');
  });

  testWidgets('a remembered pair of another category is ignored', (
    tester,
  ) async {
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
    await tester.pumpWidget(app(category: UnitCategory.area, store: store));
    await tester.pumpAndSettle();

    expect(
      pill(const Key('converter-from-unit'), 'Square metre (m²)'),
      findsOne,
    );
    expect(pill(const Key('converter-to-unit'), 'Square foot (ft²)'), findsOne);
  });

  testWidgets('a pair from the hub wins over the remembered one', (
    tester,
  ) async {
    designSurface(tester);
    final MemoryKvStore store = MemoryKvStore(<String, String>{
      ConverterMemoryController.key: ConverterMemory(
        last: ConverterPair(
          category: UnitCategory.area,
          from: UnitCatalog.byId('m2')!,
          to: UnitCatalog.byId('ft2')!,
        ),
      ).encode(),
    });
    await tester.pumpWidget(
      app(
        category: UnitCategory.area,
        from: UnitCatalog.byId('marla'),
        store: store,
      ),
    );
    await tester.pumpAndSettle();

    expect(pill(const Key('converter-from-unit'), 'Marla'), findsOne);
    expect(pill(const Key('converter-to-unit'), 'Square foot (ft²)'), findsOne);
  });

  testWidgets('the pair is remembered after a picker change and a swap', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('converter-to-unit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('picker-unit-ft')));
    await tester.pumpAndSettle();

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(ConverterPage)),
    );
    expect(container.read(converterMemoryProvider).last!.to.id, 'ft');

    await tester.tap(find.byKey(const Key('converter-swap')));
    await tester.pump();

    final ConverterPair last = container.read(converterMemoryProvider).last!;
    expect(last.from.id, 'ft');
    expect(last.to.id, 'km');
  });

  testWidgets('long-pressing Copy saves the conversion to history', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tapKey(tester, ConverterKey.five);
    await tester.longPress(find.byKey(const Key('converter-key-copy')));
    await tester.pumpAndSettle();

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(ConverterPage)),
    );
    final List<HistoryEntry> entries = container.read(historyProvider);
    expect(entries, hasLength(1));
    expect(entries.single.expression, '5 km → mi');
    expect(entries.single.result, '3.10686');
    expect(entries.single.mode, HistoryMode.converter);
    expect(find.text('Saved to history'), findsOneWidget);

    // Let the SnackBar go so it does not cover the keypad.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('converter-key-copy')));
    await tester.pumpAndSettle();

    expect(container.read(historyProvider), hasLength(1));
    expect(find.text('Already in history'), findsOneWidget);
  });

  testWidgets('a failed conversion is not saved to history', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app(category: UnitCategory.temperature));
    await tester.pumpAndSettle();

    await tapKey(tester, ConverterKey.three);
    await tapKey(tester, ConverterKey.doubleZero);
    await tapKey(tester, ConverterKey.toggleSign);
    await tester.longPress(find.byKey(const Key('converter-key-copy')));
    await tester.pumpAndSettle();

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(ConverterPage)),
    );
    expect(container.read(historyProvider), isEmpty);
    expect(find.text('Saved to history'), findsNothing);
  });
}
