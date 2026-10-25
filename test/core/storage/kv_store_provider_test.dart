import 'package:calculator/core/storage/kv_store.dart';
import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/core/storage/prefs_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to persistent storage', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(kvStoreProvider), isA<PrefsStore>());
  });

  test('can be overridden with an in-memory store', () async {
    final MemoryKvStore store = MemoryKvStore();
    final ProviderContainer container = ProviderContainer(
      overrides: [kvStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    final KvStore resolved = container.read(kvStoreProvider);
    await resolved.setString('key', 'value');

    expect(await store.getString('key'), 'value');
  });
}
