import 'dart:convert';

import 'package:calculator/core/currency/currency_repository.dart';
import 'package:calculator/core/currency/rates.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 10, 26, 12);
  final DateTime stale = now.subtract(const Duration(hours: 7));

  Rates rates({DateTime? fetchedAt, String pkr = '250', String eur = '0.5'}) =>
      Rates(
        base: 'USD',
        rates: <String, Decimal>{
          'USD': Decimal.one,
          'PKR': Decimal.parse(pkr),
          'EUR': Decimal.parse(eur),
        },
        fetchedAt: fetchedAt ?? now,
      );

  String body({
    String result = 'success',
    String base = 'USD',
    Map<String, Object?>? values,
  }) => jsonEncode(<String, Object?>{
    'result': result,
    'base_code': base,
    'rates': values ?? <String, Object?>{'USD': 1, 'PKR': 278.5, 'EUR': 0.92},
  });

  CurrencyRepository repository(
    MemoryKvStore store,
    http.Client client, {
    Duration maxAge = CurrencyRepository.defaultMaxAge,
  }) => CurrencyRepository(
    store: store,
    client: client,
    clock: () => now,
    maxAge: maxAge,
  );

  group('load', () {
    test(
      'starts as none without a cache and does not use the network',
      () async {
        int calls = 0;
        final MemoryKvStore store = MemoryKvStore();
        final CurrencyRepository repo = repository(
          store,
          MockClient((http.Request request) async {
            calls++;
            return http.Response(body(), 200);
          }),
        );

        final CurrencySnapshot snapshot = await repo.load();

        expect(calls, 0);
        expect(snapshot.rates, isNull);
        expect(snapshot.status, CurrencyStatus.none);
        expect(snapshot.refreshFailed, isFalse);
        expect(snapshot.isEmpty, isTrue);
      },
    );

    test('reads a fresh cache as live', () async {
      final MemoryKvStore store = MemoryKvStore(<String, String>{
        CurrencyRepository.cacheKey: rates().encode(),
      });
      final CurrencyRepository repo = repository(
        store,
        MockClient((http.Request request) async => http.Response('', 500)),
      );

      final CurrencySnapshot snapshot = await repo.load();

      expect(snapshot.rates, rates());
      expect(snapshot.status, CurrencyStatus.live);
      expect(snapshot.refreshFailed, isFalse);
      expect(snapshot.isEmpty, isFalse);
    });

    test('reads an old cache as cached', () async {
      final MemoryKvStore store = MemoryKvStore(<String, String>{
        CurrencyRepository.cacheKey: rates(fetchedAt: stale).encode(),
      });

      final CurrencySnapshot snapshot = await repository(
        store,
        MockClient((http.Request request) async => http.Response('', 500)),
      ).load();

      expect(snapshot.status, CurrencyStatus.cached);
      expect(snapshot.rates!.fetchedAt, stale);
    });

    test('reads corrupt cache data as none', () async {
      final MemoryKvStore store = MemoryKvStore(<String, String>{
        CurrencyRepository.cacheKey: 'not json',
      });

      final CurrencySnapshot snapshot = await repository(
        store,
        MockClient((http.Request request) async => http.Response('', 500)),
      ).load();

      expect(snapshot.rates, isNull);
      expect(snapshot.status, CurrencyStatus.none);
    });
  });

  group('refresh', () {
    test('downloads, saves and returns live rates', () async {
      final MemoryKvStore store = MemoryKvStore();
      Uri? requested;
      final CurrencyRepository repo = repository(
        store,
        MockClient((http.Request request) async {
          requested = request.url;
          return http.Response(body(), 200);
        }),
      );

      final CurrencySnapshot snapshot = await repo.refresh();

      expect(requested, Uri.parse(CurrencyRepository.defaultApiUrl));
      expect(snapshot.rates!.rateFor('PKR'), Decimal.parse('278.5'));
      expect(snapshot.rates!.fetchedAt, now);
      expect(snapshot.status, CurrencyStatus.live);
      expect(snapshot.refreshFailed, isFalse);

      final Rates cached = Rates.decode(
        await store.getString(CurrencyRepository.cacheKey),
      )!;
      expect(cached, snapshot.rates);
    });

    test('replaces an old cache with the new response', () async {
      final MemoryKvStore store = MemoryKvStore(<String, String>{
        CurrencyRepository.cacheKey: rates(
          fetchedAt: stale,
          pkr: '200',
        ).encode(),
      });

      final CurrencySnapshot snapshot = await repository(
        store,
        MockClient(
          (http.Request request) async => http.Response(
            body(values: <String, Object?>{'USD': 1, 'PKR': 278.5}),
            200,
          ),
        ),
      ).refresh();

      expect(snapshot.status, CurrencyStatus.live);
      expect(snapshot.rates!.rateFor('PKR'), Decimal.parse('278.5'));
      expect(
        Rates.decode(await store.getString(CurrencyRepository.cacheKey))!
            .fetchedAt,
        now,
      );
    });

    test(
      'an HTTP error keeps the cached rates and flags the refresh',
      () async {
        final MemoryKvStore store = MemoryKvStore(<String, String>{
          CurrencyRepository.cacheKey: rates(fetchedAt: stale).encode(),
        });

        final CurrencySnapshot snapshot = await repository(
          store,
          MockClient(
            (http.Request request) async => http.Response('server error', 500),
          ),
        ).refresh();

        expect(snapshot.rates, rates(fetchedAt: stale));
        expect(snapshot.status, CurrencyStatus.cached);
        expect(snapshot.refreshFailed, isTrue);
        expect(
          await store.getString(CurrencyRepository.cacheKey),
          rates(fetchedAt: stale).encode(),
        );
      },
    );

    test(
      'a network error keeps the cached rates and flags the refresh',
      () async {
        final MemoryKvStore store = MemoryKvStore(<String, String>{
          CurrencyRepository.cacheKey: rates(fetchedAt: stale).encode(),
        });

        final CurrencySnapshot snapshot = await repository(
          store,
          MockClient(
            (http.Request request) async =>
                throw http.ClientException('offline'),
          ),
        ).refresh();

        expect(snapshot.rates, rates(fetchedAt: stale));
        expect(snapshot.status, CurrencyStatus.cached);
        expect(snapshot.refreshFailed, isTrue);
      },
    );

    test('bad JSON keeps the cached rates and flags the refresh', () async {
      final MemoryKvStore store = MemoryKvStore(<String, String>{
        CurrencyRepository.cacheKey: rates(fetchedAt: stale).encode(),
      });

      final CurrencySnapshot snapshot = await repository(
        store,
        MockClient(
          (http.Request request) async => http.Response('not json', 200),
        ),
      ).refresh();

      expect(snapshot.rates, rates(fetchedAt: stale));
      expect(snapshot.refreshFailed, isTrue);
    });

    test('an API error result keeps the cache', () async {
      final MemoryKvStore store = MemoryKvStore(<String, String>{
        CurrencyRepository.cacheKey: rates(fetchedAt: stale).encode(),
      });

      final CurrencySnapshot snapshot = await repository(
        store,
        MockClient(
          (http.Request request) async =>
              http.Response(body(result: 'error'), 200),
        ),
      ).refresh();

      expect(snapshot.rates, rates(fetchedAt: stale));
      expect(snapshot.status, CurrencyStatus.cached);
      expect(snapshot.refreshFailed, isTrue);
    });

    test('a failed first download is none with the failure flag', () async {
      final MemoryKvStore store = MemoryKvStore();
      final CurrencySnapshot snapshot = await repository(
        store,
        MockClient(
          (http.Request request) async => throw http.ClientException('offline'),
        ),
      ).refresh();

      expect(snapshot.rates, isNull);
      expect(snapshot.status, CurrencyStatus.none);
      expect(snapshot.refreshFailed, isTrue);
      expect(snapshot.isEmpty, isTrue);
      expect(await store.getString(CurrencyRepository.cacheKey), isNull);
    });

    test('uses a custom endpoint and max age', () async {
      Uri? requested;
      final MemoryKvStore store = MemoryKvStore();
      final CurrencyRepository repo = CurrencyRepository(
        store: store,
        client: MockClient((http.Request request) async {
          requested = request.url;
          return http.Response(body(), 200);
        }),
        clock: () => now,
        apiUrl: 'https://example.test/rates',
        maxAge: const Duration(minutes: 1),
      );

      final CurrencySnapshot snapshot = await repo.refresh();

      expect(requested, Uri.parse('https://example.test/rates'));
      expect(snapshot.status, CurrencyStatus.live);
      expect(
        currencyStatus(
          snapshot.rates,
          now: now.add(const Duration(minutes: 1)),
          maxAge: const Duration(minutes: 1),
        ),
        CurrencyStatus.cached,
      );
    });
  });

  group('policy helpers', () {
    test('needsRefresh is false only for live rates', () async {
      final MemoryKvStore store = MemoryKvStore();
      final CurrencyRepository repo = repository(
        store,
        MockClient((http.Request request) async => http.Response('', 500)),
      );

      expect(repo.needsRefresh(null), isTrue);
      expect(repo.needsRefresh(rates()), isFalse);
      expect(repo.needsRefresh(rates(fetchedAt: stale)), isTrue);
    });

    test('clear removes the cache', () async {
      final MemoryKvStore store = MemoryKvStore(<String, String>{
        CurrencyRepository.cacheKey: rates().encode(),
      });
      final CurrencyRepository repo = repository(
        store,
        MockClient((http.Request request) async => http.Response('', 500)),
      );

      await repo.clear();

      expect(await store.getString(CurrencyRepository.cacheKey), isNull);
      expect((await repo.load()).status, CurrencyStatus.none);
    });
  });
}
