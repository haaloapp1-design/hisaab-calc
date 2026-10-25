import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MemoryKvStore', () {
    test('returns null for a missing key', () async {
      final MemoryKvStore store = MemoryKvStore();

      expect(await store.getString('missing'), isNull);
    });

    test('stores and reads a value', () async {
      final MemoryKvStore store = MemoryKvStore();

      await store.setString('angle', 'RAD');

      expect(await store.getString('angle'), 'RAD');
    });

    test('overwrites an existing value', () async {
      final MemoryKvStore store = MemoryKvStore(<String, String>{
        'decimals': '2',
      });

      await store.setString('decimals', '6');

      expect(await store.getString('decimals'), '6');
    });

    test('removes a value and tolerates a missing key', () async {
      final MemoryKvStore store = MemoryKvStore(<String, String>{
        'theme': 'dark',
      });

      await store.remove('theme');
      await store.remove('theme');

      expect(await store.getString('theme'), isNull);
    });

    test('keeps keys independent and copies initial values', () async {
      final Map<String, String> seed = <String, String>{'a': '1'};
      final MemoryKvStore store = MemoryKvStore(seed);

      await store.setString('b', '2');

      expect(await store.getString('a'), '1');
      expect(await store.getString('b'), '2');
      expect(seed, <String, String>{'a': '1'});
    });
  });
}
