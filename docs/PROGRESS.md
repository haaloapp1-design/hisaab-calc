# PROGRESS — the agent's memory

Append-only. Never edit old entries. Newest at the BOTTOM.
At the start of each session, read the "Decisions" section and the last 3 log entries.

## Decisions
(Choices not covered by the docs. One line each: date — decision — why.)

- 2026-10-25 — Flutter + Riverpod + decimal; engine is pure Dart in lib/core — testable, keeps UI dumb.
- 2026-10-25 — Project is `calculator` / org `com.hisaab` in this `hisaab/` folder (Android + iOS) — docs call the app "Calculator", org was unspecified.
- 2026-10-25 — `kotlin.incremental=false` in `android/gradle.properties` — pub cache is on C: and the project on D:, which breaks Kotlin's incremental caches ("different roots").
- 2026-10-25 — Ubuntu bundled in `assets/fonts/` (400/500/700 + UFL.txt) instead of using `google_fonts`, which was removed — fonts must work offline and in widget tests; DESIGN.md allows bundling.
- 2026-10-25 — `MemoryKvStore` lives in `lib/core/storage/` and `kvStoreProvider` in its own file `kv_store_provider.dart` — shared by every future test/provider override instead of test-only code.
- 2026-10-25 — Token model: `FunctionToken` owns its `(`, hidden `×` is `OperatorToken(multiply, implicit: true)`, and `CalcError.domain` displays "Undefined" — matches §1 ("sin( is ONE token") and §7; T05/T06 tokenize into this.
- 2026-10-25 — Leading `+`/`−` becomes a `UnaryToken` in the tokenizer, not a parser-only decision — T05 requires it and the parser can use precedence level 4 directly.
- 2026-10-25 — Function tokens use display names (`sin⁻¹`, `eˣ`, `10ˣ`, `√`, `∛`) and consume their `(`; hidden `×` is added in a post-pass over the token list — keeps `sin(` one token (§1) and makes implicit-multiplication rules one place.
- 2026-10-25 — AST `NumberNode` stores a `Decimal` (trailing `.` trimmed), not the raw string — the evaluator needs exact arithmetic while expression display keeps using tokens.

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

### T03 — Storage layer — 2026-10-25
Status: DONE
Changed: `lib/core/storage/kv_store.dart` (interface), `memory_kv_store.dart`, `prefs_store.dart` (only file importing shared_preferences), `kv_store_provider.dart`; tests `test/core/storage/{memory_kv_store,prefs_store,kv_store_provider}_test.dart`.
Tests: memory get/set/overwrite/remove/seed-copy (5), prefs persistence + new-instance reads (2), provider default + override (2); `flutter test` 15/15 pass; `flutter analyze` clean; `flutter build apk --debug` builds.
Notes for next session: `kvStoreProvider` defaults to `PrefsStore()` (lazy — no async init in `main`), override it with `MemoryKvStore` in tests. `PrefsStore` accepts an optional `SharedPreferences` positionally for tests. No JSON helpers yet; settings/history will store JSON strings themselves.
Next: T04 Results and errors

### T04 — Results and errors — 2026-10-25
Status: DONE
Changed: `lib/core/engine/calc_result.dart` (sealed `CalcResult` = `Success(Decimal)` / `Failure(CalcError)`), `lib/core/engine/token.dart` (token model), `test/core/engine/calc_result_test.dart`, `test/core/engine/token_test.dart`.
Tests: §7 display texts + all five errors, Success/Failure equality, exhaustive switch (4), token equality incl. hidden × (4); `flutter test` 25/25 pass; `flutter analyze` clean.
Notes for next session: T05 tokenizes into the existing `Token` classes — `FunctionToken('sin')` already represents `sin(`, closing bracket is a separate `RightParenToken`; `NumberToken.value` is unsigned raw digits; operators are `OperatorType` (add/subtract/multiply/divide/power/mod); postfix is `PostfixType` (factorial/percent/square/cube); constants pi/e; `AnsToken`. `CalcError.domain` shows "Undefined"; §7's "Invalid input" variant uses `syntax`.
Next: T05 Tokenizer: numbers, operators, brackets

### T05 — Tokenizer: numbers, operators, brackets — 2026-10-25
Status: DONE
Changed: `lib/core/engine/tokenizer.dart` (top-level `tokenize`, whitespace/aliases/postfix/mod, `FormatException` on unknown text), `lib/core/engine/token.dart` (added `UnaryToken`), `test/core/engine/tokenizer_test.dart`, `test/core/engine/token_test.dart`.
Tests: §3 sample `12.5+3×(4−1)`, empty input, decimals/leading zeros, `* / ^` aliases, `mod`, postfix `! % ² ³`, whitespace, unary at start / after operator / after `(` / after `−`, binary after value or `)`, unknown chars throw; `flutter test` 40/40 pass; `flutter analyze` clean.
Notes for next session: T06 must extend the word branch in `tokenize` (today only `mod` is known, everything else throws) with functions/constants, and insert hidden `×` before `(`/function/constant/`Ans`. `expectsValue` already tracks unary context. Numbers keep trailing dots (`12.`) — parser must normalise before `Decimal.parse`.
Next: T06 Tokenizer: functions, constants, implicit ×

### T06 — Tokenizer: functions, constants, implicit × — 2026-10-25
Status: DONE
Changed: `lib/core/engine/tokenizer.dart` (function set `sin cos tan sin⁻¹ cos⁻¹ tan⁻¹ ln log √ ∛ eˣ 10ˣ`, constants `π`/`pi`/`e`, `Ans`/`ans`, hidden-× post-pass), `test/core/engine/tokenizer_test.dart`.
Tests: `2π`, `3(4)`, `(1)(2)`, `2sin(30)`, `5!2`, `πe`, `2Ans`, `(2)3` all get `OperatorToken(multiply, implicit: true)`; functions keep their bracket; roots/inverse/`eˣ`/`10ˣ`; no × inside `sin(30)`; `flutter test` 52/52 pass; `flutter analyze` clean.
Notes for next session: T07 parser receives `FunctionToken` where a `(` would be (it already consumed the bracket) — treat it as opening a bracket and auto-close it in T08. `π`/`e` arrive as `ConstantToken`, `Ans` as `AnsToken`; unary is `UnaryToken`. No whitespace is allowed between a function name and its `(`.
Next: T07 Parser core

### T07 — Parser core — 2026-10-25
Status: DONE
Changed: `lib/core/engine/ast.dart` (NumberNode, ConstNode, UnaryNode, BinaryNode, FuncNode, PostfixNode with structural equality), `lib/core/engine/parser.dart` (precedence climbing), `test/core/engine/parser_test.dart`.
Tests: `2+3×4` tree, `2^3^2` right-assoc, `−2^2` = −(2^2), signed exponent, unary vs ×, brackets, left-assoc − ÷ ×, implicit × precedence (incl. `1÷2π`), exact decimals, trailing dot, constants, syntax errors; 18 parser tests; `flutter test` 70/70 pass; `flutter analyze` clean.
Notes for next session: parser still rejects `FunctionToken`, `PostfixToken` and `AnsToken` — T08 adds postfix (precedence 6) + functions + auto-close. Precedence constants live in `Parser`; implicit × is `OperatorToken.implicit` at level 3. `FuncNode`/`PostfixNode` already exist. `_parsePrimary` currently throws when `)` is missing, which T08 must relax for auto-closing.
Next: T08 Parser: postfix, functions, auto-close
