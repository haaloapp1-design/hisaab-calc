import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/currency/currency_repository.dart';
import '../../core/storage/kv_store_provider.dart';

/// The currency repository, sharing the app's [KvStore] and one HTTP client.
///
/// T40's `currencyProvider` reads this; the Settings clear action uses it to
/// remove `currency_cache_v1` with the other saved data.
final Provider<CurrencyRepository> currencyRepositoryProvider =
    Provider<CurrencyRepository>((Ref ref) {
      final CurrencyRepository repository = CurrencyRepository(
        store: ref.watch(kvStoreProvider),
        client: http.Client(),
      );
      ref.onDispose(repository.close);
      return repository;
    }, name: 'currencyRepository');
