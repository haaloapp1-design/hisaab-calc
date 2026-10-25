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
- 2026-10-25 — `origin` = https://github.com/haaloapp1-design/hisaab-calc and every task ends with `git push` — user asked for the repo to be kept in sync.
- 2026-10-25 — Parser auto-closes missing `)` at the end of the token list (not only on `=`) — live preview and `=` share one code path; a missing `)` anywhere else stays a syntax error.
- 2026-10-25 — `x²`/`x³` are parsed in the postfix loop (tightest) instead of at power level 5 — `2²^3` then means `(2²)^3`, the usual calculator reading.
- 2026-10-25 — §4 percent-of-left is implemented in the evaluator (`_binary` sees `right is PostfixNode(percent)`), not in the parser as the doc suggests — the rule needs the *evaluated* left operand; the parser still emits plain `PostfixNode(percent, …)`.

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

### T08 — Parser: postfix, functions, auto-close — 2026-10-25
Status: DONE
Changed: `lib/core/engine/parser.dart` (postfix loop, `FunctionToken` → `FuncNode`, `_closeBracket` auto-close), `test/core/engine/parser_test.dart`.
Tests: `5!`, `50%`, `5²`, `5³`, postfix vs `^`/unary, repeated postfix, postfix on brackets, `sin(30)`, nested functions, `2sin(30)`, `√(144)`, `(2+3`, `((2+3`, `2(3`, `sin(30`, `sin(30^2`, `sin((2+3`; 29 parser tests; `flutter test` 81/81 pass; `flutter analyze` clean.
Notes for next session: §4 percent is an *evaluation* rule — parser produces `add(200, PostfixNode(percent, 10))`, so T10 must special-case `+`/`−` with a percent right operand. `AnsToken` still unsupported (T18). Auto-close only at end of input; `sin(30))` is a syntax error.
Next: T09 Evaluator: arithmetic with Decimal

### T09 — Evaluator: arithmetic with Decimal — 2026-10-25
Status: DONE
Changed: `lib/core/engine/evaluator.dart` (`evaluate(Node)`, exact `+ − × ÷`, unary, constants, division-by-zero, 1e300 overflow), `test/core/engine/evaluator_test.dart`.
Tests: `0.1+0.2` exactly `0.3`, `1÷3×3` rounds to 1 at 12 places, `5÷0`/`0÷0` → divideByZero + propagation, unary, exact halves, π/e at 20 dp, overflow at 1e300; 11 tests; `flutter test` 92/92 pass; `flutter analyze` clean.
Notes for next session: the *exact* `1÷3×3` value is 0.999…9 (32 nines) — T13 must round to 12 significant digits for display. `evaluate` returns `Failure(CalcError.syntax)` for power/mod/postfix/functions until T10–T12. T14's facade must catch `FormatException` from tokenizer/parser and return `Failure(CalcError.syntax)`. Division uses `toDecimal(scaleOnInfinitePrecision: 32)`.
Next: T10 Percent rules

### T10 — Percent rules — 2026-10-25
Status: DONE
Changed: `lib/core/engine/evaluator.dart` (`PostfixType.percent` → `value × 0.01`, §4 percent-of-left special case for `+`/`−`), `test/core/engine/evaluator_test.dart`.
Tests: all 5 §4 rows (`50%`→0.5, `200+10%`→220, `200−10%`→180, `200×10%`→20, `200÷10%`→2000), left operand as expression (`(100+100)+10%`→220), percent amount as expression (`200+(10+5)%`→230), rule only on the right of `+`/`−` (`10%+200`→200.1, `10%×200`→20), left-assoc chains (`200+10%+5`→225, `200−10%−5`→175), `50%%`→0.005, failure propagation; 9 percent tests; `flutter test` 101/101 pass; `flutter analyze` clean.
Notes for next session: §4 lives in the evaluator, not the parser — the special case needs the *evaluated* left value, so `_binary` inspects `right is PostfixNode(percent)` before evaluating the right side. Percent binds as a postfix, so `200+10%` parses as `add(200, PostfixNode(percent, 10))`. Factorial/square/cube still return `Failure(CalcError.syntax)` (T12).
Next: T11 Trig functions
