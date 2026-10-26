import 'dart:convert';

import 'package:calculator/core/currency/currency_amount.dart';
import 'package:calculator/core/currency/currency_config.dart';
import 'package:calculator/core/currency/currency_repository.dart';
import 'package:calculator/core/currency/rates.dart';
import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/features/currency/currency_controller.dart';
import 'package:calculator/features/currency/currency_page.dart';
import 'package:calculator/features/currency/currency_repository_provider.dart';
import 'package:calculator/features/currency/currency_state.dart';
import 'package:calculator/features/currency/widgets/currency_sheet.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:calculator/theme/app_tokens.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 10, 26, 12);

  String body() => jsonEncode(<String, Object?>{
    'result': 'success',
    'base_code': 'USD',
    'rates': <String, Object?>{'USD': 1, 'PKR': 278.5, 'EUR': 0.92, 'GBP': 0.8},
  });

  Rates rates({DateTime? fetchedAt}) => Rates(
    base: 'USD',
    rates: <String, Decimal>{
      'USD': Decimal.one,
      'PKR': Decimal.parse('278.5'),
      'EUR': Decimal.parse('0.92'),
      'GBP': Decimal.parse('0.8'),
    },
    fetchedAt: fetchedAt ?? now,
  );

  Widget app(
    MemoryKvStore store,
    http.Client client, {
    DateTime Function()? clock,
  }) {
    final CurrencyRepository repository = CurrencyRepository(
      store: store,
      client: client,
      clock: clock ?? () => now,
    );
    return ProviderScope(
      overrides: [
        kvStoreProvider.overrideWithValue(store),
        currencyRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const CurrencyPage()),
    );
  }

  MockClient success({void Function()? onCall}) =>
      MockClient((http.Request request) async {
        onCall?.call();
        return http.Response(body(), 200);
      });

  /// The screens in `docs/screens/` are 390×844.
  void designSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  CurrencyState stateOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(CurrencyPage)))
          .read(currencyProvider)
          .value!;

  testWidgets('shows the header, top area, five rows and add button', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app(MemoryKvStore(), success()));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(CurrencyPage),
        matching: find.text('Currency'),
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byTooltip('Refresh rates'), findsOneWidget);

    expect(find.byKey(const Key('currency-base')), findsOneWidget);
    expect(find.text('PKR'), findsWidgets);
    expect(find.byKey(const Key('currency-base-name')), findsOneWidget);
    expect(find.text('Pakistani rupee'), findsOneWidget);
    expect(find.text('10,000'), findsOneWidget);
    expect(find.text('Live rates'), findsOneWidget);

    for (final String code in <String>['USD', 'EUR', 'GBP', 'AED', 'SAR']) {
      expect(
        find.byKey(Key('currency-row-$code')),
        findsOneWidget,
        reason: code,
      );
    }
    expect(find.byKey(const Key('currency-value-USD')), findsOneWidget);
    expect(find.text('35.91'), findsOneWidget);
    expect(find.text('1 USD = 278.5 PKR'), findsOneWidget);
    expect(find.byKey(const Key('currency-add')), findsOneWidget);
    expect(find.text('Add currency'), findsOneWidget);
  });

  testWidgets('uses the screen 08 sizes and styles', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app(MemoryKvStore(), success()));
    await tester.pumpAndSettle();

    final TextField amount = tester.widget<TextField>(
      find.byKey(const Key('currency-amount')),
    );
    expect(amount.style?.fontSize, 52);
    expect(amount.textAlign, TextAlign.right);

    final Size row = tester.getSize(find.byKey(const Key('currency-row-USD')));
    expect(row.width, 350);
    expect(row.height, 62);

    final Container sheet = tester.widget<Container>(
      find.byKey(const Key('currency-sheet')),
    );
    final BoxDecoration decoration = sheet.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.sheet);
    expect(
      decoration.borderRadius,
      const BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
    );

    expect(
      tester.getSize(find.byKey(const Key('currency-status-dot'))),
      const Size.square(AppSizes.currencyStatusDot),
    );
    expect(
      tester.getSize(find.byKey(const Key('currency-add'))).height,
      AppSizes.currencyAddHeight,
    );
    expect(find.byType(CurrencySheet), findsOneWidget);
  });

  testWidgets('typing an amount converts every row and saves it', (
    tester,
  ) async {
    designSurface(tester);
    final MemoryKvStore store = MemoryKvStore();
    await tester.pumpWidget(app(store, success()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('currency-amount')), '5000');
    await tester.pumpAndSettle();

    expect(find.text('5,000'), findsOneWidget);
    expect(find.text('17.95'), findsOneWidget);
    expect(find.text('1 USD = 278.5 PKR'), findsOneWidget);

    await ProviderScope.containerOf(tester.element(find.byType(CurrencyPage)))
        .read(currencyProvider.notifier)
        .persistDone;
    expect(
      CurrencyConfig.decode(await store.getString(CurrencyController.key))
          .amount,
      const CurrencyAmount('5000'),
    );
  });

  testWidgets('tapping a row changes its currency', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app(MemoryKvStore(), success()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('currency-row-USD')));
    await tester.pumpAndSettle();

    expect(find.text('Change USD'), findsOneWidget);
    expect(find.byKey(const Key('currency-picker-search')), findsOneWidget);
    // The sheet opens on the current currency, which is checked.
    expect(find.byKey(const Key('currency-pick-USD')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('currency-picker-search')),
      'afn',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('currency-pick-AFN')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('currency-row-USD')), findsNothing);
    expect(find.byKey(const Key('currency-row-AFN')), findsOneWidget);
    expect(stateOf(tester).config.targets, contains('AFN'));
  });

  testWidgets('the base pill swaps the base and the old base', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app(MemoryKvStore(), success()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('currency-base')));
    await tester.pumpAndSettle();
    expect(find.text('Base currency'), findsOneWidget);
    expect(find.byKey(const Key('currency-pick-PKR')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('currency-picker-search')),
      'usd',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('currency-pick-USD')));
    await tester.pumpAndSettle();

    expect(find.text('US dollar'), findsOneWidget);
    expect(stateOf(tester).config.base, 'USD');
    expect(stateOf(tester).config.targets.first, 'PKR');
    expect(stateOf(tester).config.targets, isNot(contains('USD')));
  });

  testWidgets('the add button searches and appends a currency', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app(MemoryKvStore(), success()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('currency-add')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('currency-picker-title')), findsOneWidget);
    expect(find.text('Add currency'), findsWidgets);
    expect(find.byKey(const Key('currency-pick-USD')), findsNothing);
    expect(find.byKey(const Key('currency-pick-PKR')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('currency-picker-search')),
      'jap',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('currency-pick-JPY')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('currency-row-JPY')), findsOneWidget);
    expect(stateOf(tester).config.targets.last, 'JPY');
  });

  testWidgets('the picker shows an empty state for an unknown search', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app(MemoryKvStore(), success()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('currency-add')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('currency-picker-search')),
      'zzz',
    );
    await tester.pump();

    expect(find.byKey(const Key('currency-picker-empty')), findsOneWidget);
    expect(find.text('No currencies found'), findsOneWidget);
  });

  testWidgets('long press moves a row up and hides impossible moves', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app(MemoryKvStore(), success()));
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('currency-row-EUR')));
    await tester.pumpAndSettle();
    expect(find.text('EUR · Euro'), findsOneWidget);
    expect(find.byKey(const Key('currency-action-up')), findsOneWidget);
    expect(find.byKey(const Key('currency-action-down')), findsOneWidget);

    await tester.tap(find.byKey(const Key('currency-action-up')));
    await tester.pumpAndSettle();

    expect(stateOf(tester).config.targets.take(3), <String>[
      'EUR',
      'USD',
      'GBP',
    ]);

    await tester.longPress(find.byKey(const Key('currency-row-EUR')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('currency-action-up')), findsNothing);
    expect(find.byKey(const Key('currency-action-down')), findsOneWidget);
  });

  testWidgets('long press removes a currency', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app(MemoryKvStore(), success()));
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('currency-row-EUR')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('currency-action-remove')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('currency-row-EUR')), findsNothing);
    expect(stateOf(tester).config.targets, isNot(contains('EUR')));
    expect(find.text('EUR removed'), findsOneWidget);
  });

  testWidgets('the refresh icon downloads fresh rates', (tester) async {
    designSurface(tester);
    int calls = 0;
    await tester.pumpWidget(
      app(MemoryKvStore(), success(onCall: () => calls++)),
    );
    await tester.pumpAndSettle();
    expect(calls, 1);

    await tester.tap(find.byTooltip('Refresh rates'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('Live rates'), findsOneWidget);
  });

  testWidgets('pulling the list refreshes the rates', (tester) async {
    designSurface(tester);
    int calls = 0;
    await tester.pumpWidget(
      app(MemoryKvStore(), success(onCall: () => calls++)),
    );
    await tester.pumpAndSettle();
    expect(calls, 1);

    await tester.drag(
      find.byKey(const Key('currency-row-USD')),
      const Offset(0, 320),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(calls, 2);
  });

  testWidgets('offline with a cache shows the cached date and values', (
    tester,
  ) async {
    designSurface(tester);
    final MemoryKvStore store = MemoryKvStore(<String, String>{
      CurrencyRepository.cacheKey: rates(
        fetchedAt: now.subtract(const Duration(days: 1)),
      ).encode(),
    });
    await tester.pumpWidget(
      app(
        store,
        MockClient(
          (http.Request request) async => throw http.ClientException('offline'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Offline · Rates from 25 Oct 2026'), findsOneWidget);
    expect(find.text('35.91'), findsOneWidget);
  });

  testWidgets('offline without a cache shows dashes and no rates', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(
      app(
        MemoryKvStore(),
        MockClient(
          (http.Request request) async => throw http.ClientException('offline'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Offline · No rates yet'), findsOneWidget);
    expect(find.text('—'), findsWidgets);
    expect(find.text('No rate yet'), findsWidgets);
  });
}
