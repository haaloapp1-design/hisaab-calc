import 'dart:convert';

import '../../core/engine/angle_mode.dart';

/// The Light / Dark / System choice from Settings (SPEC §3).
///
/// Named `AppThemeMode` so it never collides with Flutter's `ThemeMode`; the
/// theme layer maps it in T27.
enum AppThemeMode { light, dark, system }

/// The four accent swatches from DESIGN "Colour" (SPEC §3 has no names).
///
/// The colour values stay in the theme layer: Settings only remembers which
/// swatch is chosen, so this model has no Flutter dependency.
enum AccentSwatch { cobalt, teal, violet, rust }

/// How long history entries are kept (SPEC §3).
enum HistoryRetention {
  days7,
  days30,
  days90,
  forever;

  /// The number of days an entry survives, or null for [forever].
  int? get days => switch (this) {
    HistoryRetention.days7 => 7,
    HistoryRetention.days30 => 30,
    HistoryRetention.days90 => 90,
    HistoryRetention.forever => null,
  };
}

/// Everything the Settings screen stores (SPEC §3, ARCHITECTURE "State").
///
/// Immutable value object: the controller replaces it on every change and
/// persists its JSON form under one KvStore key. Defaults match the design
/// (`05-settings.html`: System theme, cobalt accent, Degrees, Auto decimals,
/// thousands separator on, haptics on, key sounds off, 30-day retention).
final class Settings {
  const Settings({
    this.themeMode = AppThemeMode.system,
    this.accent = AccentSwatch.cobalt,
    this.angleMode = AngleMode.deg,
    this.decimalPlaces,
    this.thousandsSeparator = true,
    this.haptics = true,
    this.keySounds = false,
    this.historyRetention = HistoryRetention.days30,
  }) : assert(
         decimalPlaces == null ||
             (decimalPlaces >= minDecimalPlaces &&
                 decimalPlaces <= maxDecimalPlaces),
         'decimalPlaces must be 0–10 or null for Auto',
       );

  /// SPEC §3: Auto or a fixed 0–10 decimal places.
  static const int minDecimalPlaces = 0;
  static const int maxDecimalPlaces = 10;

  final AppThemeMode themeMode;
  final AccentSwatch accent;
  final AngleMode angleMode;

  /// Fixed decimal places (0–10), or null for Auto.
  final int? decimalPlaces;

  final bool thousandsSeparator;
  final bool haptics;
  final bool keySounds;
  final HistoryRetention historyRetention;

  /// A copy with the named fields replaced.
  ///
  /// [decimalPlaces] is a callback because null means Auto, so a plain null
  /// parameter could not tell "keep the old value" from "switch to Auto";
  /// `copyWith(decimalPlaces: () => null)` clears it.
  Settings copyWith({
    AppThemeMode? themeMode,
    AccentSwatch? accent,
    AngleMode? angleMode,
    int? Function()? decimalPlaces,
    bool? thousandsSeparator,
    bool? haptics,
    bool? keySounds,
    HistoryRetention? historyRetention,
  }) => Settings(
    themeMode: themeMode ?? this.themeMode,
    accent: accent ?? this.accent,
    angleMode: angleMode ?? this.angleMode,
    decimalPlaces: decimalPlaces == null ? this.decimalPlaces : decimalPlaces(),
    thousandsSeparator: thousandsSeparator ?? this.thousandsSeparator,
    haptics: haptics ?? this.haptics,
    keySounds: keySounds ?? this.keySounds,
    historyRetention: historyRetention ?? this.historyRetention,
  );

  /// The persisted form. Enums are stored by `name`.
  Map<String, Object?> toJson() => <String, Object?>{
    'theme': themeMode.name,
    'accent': accent.name,
    'angle': angleMode.name,
    'decimalPlaces': decimalPlaces,
    'thousandsSeparator': thousandsSeparator,
    'haptics': haptics,
    'keySounds': keySounds,
    'historyRetention': historyRetention.name,
  };

  /// Reads stored JSON, falling back field by field to the defaults.
  ///
  /// A value written by a newer/older build must never crash the app, so an
  /// unknown enum name, a missing key or an out-of-range decimal count keeps
  /// the default instead of throwing.
  factory Settings.fromJson(Map<String, Object?> json) {
    final Object? places = json['decimalPlaces'];
    final int? decimals =
        places is int &&
            places >= minDecimalPlaces &&
            places <= maxDecimalPlaces
        ? places
        : null;

    return Settings(
      themeMode: _enumByName(
        AppThemeMode.values,
        json['theme'],
        AppThemeMode.system,
      ),
      accent: _enumByName(
        AccentSwatch.values,
        json['accent'],
        AccentSwatch.cobalt,
      ),
      angleMode: _enumByName(
        AngleMode.values,
        json['angle'],
        AngleMode.deg,
      ),
      decimalPlaces: decimals,
      thousandsSeparator: _boolOr(json['thousandsSeparator'], true),
      haptics: _boolOr(json['haptics'], true),
      keySounds: _boolOr(json['keySounds'], false),
      historyRetention: _enumByName(
        HistoryRetention.values,
        json['historyRetention'],
        HistoryRetention.days30,
      ),
    );
  }

  /// Parses the string stored under the settings key; bad JSON → defaults.
  static Settings decode(String source) {
    try {
      final Object? json = jsonDecode(source);
      if (json is Map<String, Object?>) {
        return Settings.fromJson(json);
      }
    } on FormatException {
      // Fall through to the defaults for corrupt data.
    }
    return const Settings();
  }

  /// The string the controller stores.
  String encode() => jsonEncode(toJson());

  static T _enumByName<T extends Enum>(
    List<T> values,
    Object? raw,
    T fallback,
  ) {
    for (final T value in values) {
      if (value.name == raw) {
        return value;
      }
    }
    return fallback;
  }

  static bool _boolOr(Object? raw, bool fallback) =>
      raw is bool ? raw : fallback;

  @override
  bool operator ==(Object other) =>
      other is Settings &&
      other.themeMode == themeMode &&
      other.accent == accent &&
      other.angleMode == angleMode &&
      other.decimalPlaces == decimalPlaces &&
      other.thousandsSeparator == thousandsSeparator &&
      other.haptics == haptics &&
      other.keySounds == keySounds &&
      other.historyRetention == historyRetention;

  @override
  int get hashCode => Object.hash(
    themeMode,
    accent,
    angleMode,
    decimalPlaces,
    thousandsSeparator,
    haptics,
    keySounds,
    historyRetention,
  );

  @override
  String toString() =>
      'Settings(theme: ${themeMode.name}, accent: ${accent.name}, '
      'angle: ${angleMode.name}, decimalPlaces: $decimalPlaces, '
      'thousandsSeparator: $thousandsSeparator, haptics: $haptics, '
      'keySounds: $keySounds, retention: ${historyRetention.name})';
}
