import 'kv_store.dart';

/// In-memory [KvStore] for tests, previews and provider overrides.
///
/// Values are not persisted; two instances never share data.
class MemoryKvStore implements KvStore {
  MemoryKvStore([Map<String, String>? initialValues])
    : _values = <String, String>{...?initialValues};

  final Map<String, String> _values;

  @override
  Future<String?> getString(String key) async => _values[key];

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }
}
