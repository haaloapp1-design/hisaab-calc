# Hisab (حساب)

An advanced calculator for Android and iOS, built with Flutter. One app for
everyday maths, a full scientific keypad, programmer bases, unit and currency
conversion, ten practical tools, history, memory and a themed settings screen.

## Features

- **Basic** — four-function calculator with `%`, `±`, brackets, `Ans` and a
  running expression line. Decimal arithmetic is exact (`0.1 + 0.2 = 0.3`).
- **Scientific** — DEG/RAD, `2nd` functions, powers and roots, logarithms,
  factorial, constants, memory and open-bracket tracking.
- **Programmer** — HEX/DEC/OCT/BIN input, bitwise operations and 8/16/32/64-bit
  word sizes.
- **Converter** — length, mass, temperature, area, volume, speed, time and data
  categories, favourites and unit search.
- **Currency** — live exchange rates with offline caching, editable base and
  target list, favourites and manual refresh.
- **Tools** — loan, percentage, discount and tax, tip and split, age, date
  difference, BMI, GPA, equation solver and statistics.
- **History and memory** — searchable history, per-entry reuse, and M+/M−/MR/MC
  memory with a display chip.
- **Settings** — light/dark/system theme, four accents, decimal places,
  thousands grouping, decimal mark, angle unit, haptics and key sounds, and a
  "clear all saved data" action.

## Requirements

- Flutter 3.47+ (stable) with Dart 3.13+
- Android SDK 21+ for Android; Xcode for iOS
- The bundled Ubuntu fonts are in `assets/fonts/` — no network is needed to
  render the UI

## Run

```sh
flutter pub get
flutter run
```

## Verify

```sh
flutter analyze          # no issues expected
flutter test             # full unit + widget suite
```

## Build

```sh
flutter build apk --release        # Android, debug-signed for now (see below)
flutter build appbundle --release  # Play Store bundle
flutter build ipa --release        # iOS (needs a signing team)
```

The Android release build currently signs with the debug keystore
(`android/app/build.gradle.kts`), so it installs for testing but is **not**
ready for the Play Store. Replace the `release` `signingConfig` with a real
keystore before publishing. The version comes from `pubspec.yaml`
(`version: 1.0.0+1`).

## Project layout

```
lib/
  app.dart, main.dart      app shell, theme and ProviderScope
  core/                    pure-Dart engines: calculator, converter, currency,
                           tools, storage, formatting (no Flutter imports)
  features/                one folder per screen: calculator, converter,
                           currency, tools, history, settings, shell
  shared/widgets/          blue header, white sheet, bottom nav, segmented
  theme/                   design tokens, palettes, WCAG contrast helper
test/                      mirrors lib/ (core engines, widgets, accessibility,
                           layout) — every engine function has a test
docs/                      specification, business logic, architecture, design,
                           per-screen HTML references, task log
```

## Documentation

- `docs/SPEC.md` — every feature, screen by screen
- `docs/BUSINESS_LOGIC.md` — engine rules and the maths
- `docs/ARCHITECTURE.md` — folders, packages, state management
- `docs/DESIGN.md` — colours, type and sizes
- `docs/TASKS.md` / `docs/PROGRESS.md` — what is built and what is next
