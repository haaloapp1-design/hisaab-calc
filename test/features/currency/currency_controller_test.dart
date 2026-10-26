import 'dart:convert';

import 'package:calculator/core/currency/currency_amount.dart';
import 'package:calculator/core/currency/currency_config.dart';
import 'package:calculator/core/currency/currency_repository.dart';
import 'package:calculator/core/currency/rates.dart';
import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/features/currency/currency_controller.dart';
import 'package:calculator/features/currency/currency_repository_provider.dart';
import 'package:calculator/features/currency/currency_state.dart';
import 'package:decimal/decimal.dart';
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

  Rates cachedRates({DateTime? fetchedAt}) => Rates(
    base: 'USD',
    rates: <String, Decimal>{
      'USD': Decimal.one,
      'PKR': Decimal.parse('278.5'),
      'EUR': Decimal.parse('0.92'),
      'GBP': Decimal.parse('0.8'),
    },
    fetchedAt: fetchedAt ?? now,
  );

  ProviderContainer container(
    MemoryKvStore store,
    http.Client client, {
    DateTime Function()? clock,
    Duration maxAge = CurrencyRepository.defaultMaxAge,
  }) {
    final CurrencyRepository repository = CurrencyRepository(
      store: store,
      client: client,
      clock: clock ?? () => now,
      maxAge: maxAge,
    );
    final ProviderContainer result = ProviderContainer(
      overrides: [
        kvStoreProvider.overrideWithValue(store),
        currencyRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(result.dispose);
    return result;
  }

  MockClient success({void Function()? onCall}) =>
      MockClient((http.Request request) async {
        onCall?.call();
        return http.Response(body(), 200);
      });

  group('build', () {
    test('starts from the defaults and downloads missing rates', () async {
      final MemoryKvStore store = MemoryKvStore();
      int calls = 0;
      final ProviderContainer c = container(
        store,
        success(onCall: () => calls++),
      );

      final CurrencyState state = await c.read(currencyProvider.future);

      expect(calls, 1);
      expect(state.config, CurrencyConfig.defaults);
      expect(state.status, CurrencyStatus.live);
      expect(state.refreshFailed, isFalse);
      expect(state.rates!.rateFor('PKR'), Decimal.parse('278.5'));
      expect(await store.getString(CurrencyRepository.cacheKey), isNotNull);
    });

    test(
      'restores the saved config and a live cache without a download',
      () async {
        final CurrencyConfig config = CurrencyConfig.defaults
            .withBase('USD')
            .addCurrency('JPY')
            .withAmount(const CurrencyAmount('500'));
        final MemoryKvStore store = MemoryKvStore(<String, String>{
          CurrencyController.key: config.encode(),
          CurrencyRepository.cacheKey: cachedRates().encode(),
        });
        int calls = 0;
        final ProviderContainer c = container(
          store,
          success(onCall: () => calls++),
        );

        final CurrencyState state = await c.read(currencyProvider.future);

        expect(calls, 0);
        expect(state.config, config);
        expect(state.status, CurrencyStatus.live);
      },
    );
  });

  group('user changes', () {
    test('setBase swaps and persists the whole config', () async {
      final MemoryKvStore store = MemoryKvStore();
      final ProviderContainer c = container(store, success());
      await c.read(currencyProvider.future);
      final CurrencyController controller = c.read(currencyProvider.notifier);

      controller.setBase('USD');
      await controller.persistDone;

      final CurrencyState state = c.read(currencyProvider).value!;
      expect(state.config.base, 'USD');
      expect(state.config.targets, <String>['PKR', 'EUR', 'GBP', 'AED', 'SAR']);
      final CurrencyConfig saved = CurrencyConfig.decode(
        await store.getString(CurrencyController.key),
      );
      expect(saved, state.config);
    });

    test('add, replace, move and remove update the list', () async {
      final MemoryKvStore store = MemoryKvStore();
      final ProviderContainer c = container(store, success());
      await c.read(currencyProvider.future);
      final CurrencyController controller = c.read(currencyProvider.notifier);

      expect(controller.addCurrency('JPY'), isTrue);
      expect(controller.addCurrency('JPY'), isFalse);
      expect(controller.addCurrency('PKR'), isFalse);
      expect(controller.addCurrency('XYZ'), isFalse);
      expect(c.read(currencyProvider).value!.config.targets.last, 'JPY');

      expect(controller.replaceCurrency('GBP', 'CAD'), isTrue);
      expect(controller.replaceCurrency('GBP', 'CAD'), isFalse);
      expect(c.read(currencyProvider).value!.config.targets, contains('CAD'));

      expect(controller.moveCurrency(4, -1), isTrue);
      expect(c.read(currencyProvider).value!.config.targets[3], 'SAR');
      expect(controller.moveCurrency(0, -1), isFalse);
      expect(controller.moveCurrency(99, 1), isFalse);

      expect(controller.removeCurrency('EUR'), isTrue);
      expect(controller.removeCurrency('EUR'), isFalse);
      await controller.persistDone;

      final CurrencyConfig saved = CurrencyConfig.decode(
        await store.getString(CurrencyController.key),
      );
      expect(saved, c.read(currencyProvider).value!.config);
      expect(saved.targets, isNot(contains('EUR')));
    });

    test('setAmount stores the typed amount', () async {
      final MemoryKvStore store = MemoryKvStore();
      final ProviderContainer c = container(store, success());
      await c.read(currencyProvider.future);
      final CurrencyController controller = c.read(currencyProvider.notifier);

      controller.setAmount(const CurrencyAmount('1234.50'));
      await controller.persistDone;

      expect(
        c.read(currencyProvider).value!.config.amount,
        const CurrencyAmount('1234.50'),
      );
      expect(
        CurrencyConfig.decode(await store.getString(CurrencyController.key))
            .amount,
        const CurrencyAmount('1234.50'),
      );
    });
  });

  group('refresh', () {
    test('a failed first download keeps the state usable', () async {
      final MemoryKvStore store = MemoryKvStore();
      final ProviderContainer c = container(
        store,
        MockClient(
          (http.Request request) async => throw http.ClientException('offline'),
        ),
      );

      final CurrencyState state = await c.read(currencyProvider.future);

      expect(state.rates, isNull);
      expect(state.status, CurrencyStatus.none);
      expect(state.refreshFailed, isTrue);
    });

    test('a failed refresh keeps the cached table', () async {
      final MemoryKvStore store = MemoryKvStore(<String, String>{
        CurrencyRepository.cacheKey: cachedRates(
          fetchedAt: now.subtract(const Duration(hours: 7)),
        ).encode(),
      });
      final ProviderContainer c = container(
        store,
        MockClient(
          (http.Request request) async => throw http.ClientException('offline'),
        ),
      );

      final CurrencyState state = await c.read(currencyProvider.future);

      expect(state.status, CurrencyStatus.cached);
      expect(state.refreshFailed, isTrue);
      expect(state.rates!.rateFor('PKR'), Decimal.parse('278.5'));
    });

    test('refresh downloads again and reports success', () async {
      int calls = 0;
      final MemoryKvStore store = MemoryKvStore();
      final ProviderContainer c = container(
        store,
        success(onCall: () => calls++),
      );
      await c.read(currencyProvider.future);
      final CurrencyController controller = c.read(currencyProvider.notifier);

      final bool ok = await controller.refresh();

      expect(ok, isTrue);
      expect(calls, 2);
      expect(c.read(currencyProvider).value!.status, CurrencyStatus.live);
      expect(c.read(currencyProvider).value!.refreshing, isFalse);
    });

    test('refresh returns false when the download fails', () async {
      final MemoryKvStore store = MemoryKvStore(<String, String>{
        CurrencyRepository.cacheKey: cachedRates().encode(),
      });
      final ProviderContainer c = container(
        store,
        MockClient(
          (http.Request request) async => throw http.ClientException('offline'),
        ),
      );
      await c.read(currencyProvider.future);
      final CurrencyController controller = c.read(currencyProvider.notifier);

      final bool ok = await controller.refresh();

      expect(ok, isFalse);
      expect(c.read(currencyProvider).value!.refreshFailed, isTrue);
    });

    test('refreshIfStale does nothing while the cache is live', () async {
      int calls = 0;
      final MemoryKvStore store = MemoryKvStore(<String, String>{
        CurrencyRepository.cacheKey: cachedRates().encode(),
      });
      final ProviderContainer c = container(
        store,
        success(onCall: () => calls++),
        maxAge: const Duration(days: 3650),
      );
      await c.read(currencyProvider.future);

      final bool ran = await c.read(currencyProvider.notifier).refreshIfStale();

      expect(ran, isFalse);
      expect(calls, 0);
    });

    test('refreshIfStale refreshes after the 6 h window', () async {
      DateTime clock = now;
      int calls = 0;
      final MemoryKvStore store = MemoryKvStore(<String, String>{
        CurrencyRepository.cacheKey: cachedRates().encode(),
      });
      final ProviderContainer c = container(
        store,
        success(onCall: () => calls++),
        clock: () => clock,
      );
      await c.read(currencyProvider.future);
      expect(calls, 0);

      clock = now.add(const Duration(hours: 7));
      final bool ran = await c.read(currencyProvider.notifier).refreshIfStale();

      expect(ran, isTrue);
      expect(calls, 1);
      expect(c.read(currencyProvider).value!.status, CurrencyStatus.live);
      expect(c.read(currencyProvider).value!.rates!.fetchedAt, clock);
    });
  });
}
