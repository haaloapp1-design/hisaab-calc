/// Minimal asynchronous key-value storage.
///
/// Used by settings, history, memory slots and the currency cache so those
/// features never touch `shared_preferences` directly.
abstract interface class KvStore {
  /// Returns the stored string for [key], or `null` when it does not exist.
  Future<String?> getString(String key);

  /// Stores [value] under [key], replacing any old value.
  Future<void> setString(String key, String value);

  /// Deletes [key]; deleting a missing key is not an error.
  Future<void> remove(String key);
}
