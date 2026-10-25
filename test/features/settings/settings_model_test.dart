import 'dart:convert';

import 'package:calculator/core/engine/angle_mode.dart';
import 'package:calculator/features/settings/settings_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('defaults', () {
    test('match SPEC §3 and the 05-settings design', () {
      const Settings settings = Settings();

      expect(settings.themeMode, AppThemeMode.system);
      expect(settings.accent, AccentSwatch.cobalt);
      expect(settings.angleMode, AngleMode.deg);
      expect(settings.decimalPlaces, isNull);
      expect(settings.thousandsSeparator, isTrue);
      expect(settings.haptics, isTrue);
      expect(settings.keySounds, isFalse);
      expect(settings.historyRetention, HistoryRetention.days30);
    });
  });

  group('copyWith', () {
    test('replaces only the named fields', () {
      const Settings settings = Settings();
      final Settings next = settings.copyWith(
        themeMode: AppThemeMode.dark,
        accent: AccentSwatch.rust,
        angleMode: AngleMode.rad,
        thousandsSeparator: false,
        haptics: false,
        keySounds: true,
        historyRetention: HistoryRetention.forever,
      );

      expect(next.themeMode, AppThemeMode.dark);
      expect(next.accent, AccentSwatch.rust);
      expect(next.angleMode, AngleMode.rad);
      expect(next.decimalPlaces, isNull);
      expect(next.thousandsSeparator, isFalse);
      expect(next.haptics, isFalse);
      expect(next.keySounds, isTrue);
      expect(next.historyRetention, HistoryRetention.forever);
    });

    test('sets a fixed decimal count and clears it back to Auto', () {
      const Settings settings = Settings(decimalPlaces: 4);

      expect(settings.copyWith().decimalPlaces, 4);
      expect(settings.copyWith(decimalPlaces: () => 2).decimalPlaces, 2);
      expect(settings.copyWith(decimalPlaces: () => null).decimalPlaces, isNull);
    });
  });

  group('JSON', () {
    test('writes the documented keys', () {
      const Settings settings = Settings(
        themeMode: AppThemeMode.light,
        accent: AccentSwatch.teal,
        angleMode: AngleMode.rad,
        decimalPlaces: 3,
        thousandsSeparator: false,
        haptics: false,
        keySounds: true,
        historyRetention: HistoryRetention.days90,
      );

      expect(settings.toJson(), <String, Object?>{
        'theme': 'light',
        'accent': 'teal',
        'angle': 'rad',
        'decimalPlaces': 3,
        'thousandsSeparator': false,
        'haptics': false,
        'keySounds': true,
        'historyRetention': 'days90',
      });
    });

    test('round-trips through encode and decode', () {
      const Settings settings = Settings(
        themeMode: AppThemeMode.dark,
        accent: AccentSwatch.violet,
        angleMode: AngleMode.rad,
        decimalPlaces: 0,
        thousandsSeparator: false,
        haptics: false,
        keySounds: true,
        historyRetention: HistoryRetention.days7,
      );

      expect(Settings.decode(settings.encode()), settings);
    });

    test('fromJson falls back per field for missing or unknown values', () {
      final Settings settings = Settings.fromJson(<String, Object?>{
        'theme': 'purple',
        'accent': 42,
        'angle': 'grad',
        'decimalPlaces': 11,
        'thousandsSeparator': 'yes',
        'haptics': null,
        'historyRetention': 'days365',
      });

      expect(settings, const Settings());
    });

    test('accepts the ends of the 0–10 decimal range', () {
      expect(
        Settings.fromJson(<String, Object?>{'decimalPlaces': 0}).decimalPlaces,
        0,
      );
      expect(
        Settings.fromJson(<String, Object?>{'decimalPlaces': 10}).decimalPlaces,
        10,
      );
      expect(
        Settings.fromJson(
          <String, Object?>{'decimalPlaces': -1},
        ).decimalPlaces,
        isNull,
      );
      expect(
        Settings.fromJson(
          <String, Object?>{'decimalPlaces': '4'},
        ).decimalPlaces,
        isNull,
      );
    });

    test('decode returns the defaults for corrupt or non-object JSON', () {
      expect(Settings.decode('not json'), const Settings());
      expect(Settings.decode('[1,2,3]'), const Settings());
      expect(Settings.decode('null'), const Settings());
    });

    test('decode ignores whitespace and extra keys', () {
      final String source = jsonEncode(<String, Object?>{
        'theme': 'light',
        'futureSetting': true,
      });

      expect(Settings.decode(source).themeMode, AppThemeMode.light);
      expect(Settings.decode(source).accent, AccentSwatch.cobalt);
    });
  });

  group('HistoryRetention', () {
    test('reports the day count used by history cleanup', () {
      expect(HistoryRetention.days7.days, 7);
      expect(HistoryRetention.days30.days, 30);
      expect(HistoryRetention.days90.days, 90);
      expect(HistoryRetention.forever.days, isNull);
    });
  });

  group('equality', () {
    test('two equal settings share a hash and differ from a changed one', () {
      const Settings a = Settings(decimalPlaces: 2);
      const Settings b = Settings(decimalPlaces: 2);
      final Settings c = a.copyWith(haptics: false);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}
