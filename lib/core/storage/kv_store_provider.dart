import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'kv_store.dart';
import 'prefs_store.dart';

/// The app's key-value store.
///
/// Defaults to persistent storage; tests override it with `MemoryKvStore`.
final Provider<KvStore> kvStoreProvider = Provider<KvStore>(
  (Ref ref) => PrefsStore(),
  name: 'kvStore',
);
