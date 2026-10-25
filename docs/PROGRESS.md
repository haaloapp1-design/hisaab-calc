# PROGRESS — the agent's memory

Append-only. Never edit old entries. Newest at the BOTTOM.
At the start of each session, read the "Decisions" section and the last 3 log entries.

## Decisions
(Choices not covered by the docs. One line each: date — decision — why.)

- 2026-10-25 — Flutter + Riverpod + decimal; engine is pure Dart in lib/core — testable, keeps UI dumb.
- 2026-10-25 — Project is `calculator` / org `com.hisaab` in this `hisaab/` folder (Android + iOS) — docs call the app "Calculator", org was unspecified.
- 2026-10-25 — `kotlin.incremental=false` in `android/gradle.properties` — pub cache is on C: and the project on D:, which breaks Kotlin's incremental caches ("different roots").
- 2026-10-25 — Ubuntu bundled in `assets/fonts/` (400/500/700 + UFL.txt) instead of using `google_fonts`, which was removed — fonts must work offline and in widget tests; DESIGN.md allows bundling.

## Log entry template

```
### T<id> — <title> — <YYYY-MM-DD>
Status: DONE | PARTIAL | BLOCKED: <reason>
Changed: <files created/edited, short>
Tests: <what was added; flutter test result>
Notes for next session: <anything the next run must know, or "none">
Next: T<id> <title>
```

## Log

### T00 — Planning docs added — 2026-10-25
Status: DONE
Changed: AGENTS.md, docs/SPEC.md, docs/BUSINESS_LOGIC.md, docs/ARCHITECTURE.md, docs/DESIGN.md, docs/TASKS.md, docs/PROGRESS.md
Tests: none yet
Notes for next session: Flutter project already created by the user. Start at T01.
Next: T01 Packages and skeleton

### T01 — Packages and skeleton — 2026-10-25
Status: DONE
Changed: created Flutter project (`calculator`, org `com.hisaab`, android+ios) in the existing folder; added flutter_riverpod, decimal, shared_preferences, http, intl, google_fonts; `lib/main.dart` (ProviderScope) + `lib/app.dart` (blank MaterialApp); all ARCHITECTURE folders under `lib/` and `test/` with `.gitkeep`; `test/app_test.dart`; `android/gradle.properties` (kotlin.incremental=false, see Decisions).
Tests: `test/app_test.dart` pumps the app and finds MaterialApp + Scaffold; `flutter test` 1/1 pass; `flutter analyze` no issues; `flutter build apk --debug` succeeds.
Notes for next session: the repo had only docs/ — the Flutter project did not actually exist yet, so T01 created it. No theme or tokens exist: T02 must add `lib/theme/app_tokens.dart` + `app_theme.dart` and wire `app.dart` to them.
Next: T02 Theme tokens

### T02 — Theme tokens — 2026-10-25
Status: DONE
Changed: `lib/theme/app_tokens.dart` (AppColors, AppRadii, AppSizes, AppTypography), `lib/theme/app_theme.dart` (light ThemeData), `lib/app.dart` (theme + temporary probe screen), `assets/fonts/Ubuntu-{Regular,Medium,Bold}.ttf` + `UFL.txt`, `pubspec.yaml` (Ubuntu font family, google_fonts removed), `test/theme/app_theme_test.dart`, `test/app_test.dart`.
Tests: theme colours, sheet shape, type scale and accent swatches; app renders blue top + white sheet; `flutter test` 6/6 pass; `flutter analyze` clean; `flutter build apk --debug` builds.
Notes for next session: no hard-coded colours/sizes outside `lib/theme/`. Accent derivation (DESIGN "changing accent replaces primary") is NOT implemented yet — T27 needs it, possibly via an accent-aware palette. No dark theme yet (T49). The probe page in `app.dart` is temporary until T19/T23.
Next: T03 Storage layer
