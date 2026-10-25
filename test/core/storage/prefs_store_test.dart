import 'package:calculator/core/storage/prefs_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrefsStore', () {
    test('persists, reads and removes values', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'existing': 'value',
      });
      final PrefsStore store = PrefsStore();

      expect(await store.getString('existing'), 'value');
      expect(await store.getString('missing'), isNull);

      await store.setString('new', 'stored');
      expect(await store.getString('new'), 'stored');

      await store.remove('existing');
      expect(await store.getString('existing'), isNull);
    });

    test('new instances read values written by an earlier instance', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final PrefsStore first = PrefsStore();

      await first.setString('lastPair', 'km>mi');

      final PrefsStore second = PrefsStore();
      expect(await second.getString('lastPair'), 'km>mi');
    });
  });
}
