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
- 2026-10-25 — `AngleMode` lives in `lib/core/engine/angle_mode.dart` as a pure-Dart enum, and `evaluate` takes it as `{AngleMode angleMode = AngleMode.deg}` — SPEC says DEG is the default; T14 can pass the settings value straight through without the engine importing settings.
- 2026-10-25 — Trig results use `double.toStringAsPrecision(15)` then `Decimal.parse` — the string route applies the §2 15-significant-digit rule directly and parses exactly; a raw double-to-Decimal conversion would keep binary noise.
- 2026-10-25 — `0^negative` returns `divideByZero` (e.g. `0^−1`) — the docs do not name this case; `1/0` is the closest rule, and `Decimal.pow` would otherwise throw from a zero denominator.
- 2026-10-25 — Factorial accepts `n ≤ 170` per §6, but the §2 `1e300` cap still applies to the result, so factorials above 166! report `overflow` — the two rules overlap; §2 is the global safety limit.
- 2026-10-25 — `mod` stays a programmer-mode (integer `Word`) operator and returns `Failure(syntax)` in the Decimal engine — §11 defines it on signed integers, and no scientific keypad emits it.
- 2026-10-25 — Auto formatting uses §8's 12 significant digits, not the "up to 10 significant decimals" wording in SPEC's settings screen — BUSINESS_LOGIC is the engine-rules doc and T13 reads §8; the settings UI can still describe it loosely.
- 2026-10-25 — In scientific notation a fixed decimal setting keeps its zeros (`1.00E+18`) while Auto strips them (`1E+18`) — §8.1 says fixed keeps trailing zeros and §8.2 caps the mantissa at 10 digits; both rules are honoured.
- 2026-10-25 — `formatTypedNumber` lives in the formatter for the expression line (§8.6) — it groups typed digits without rounding, so the display layer never re-implements separator logic.
- 2026-10-25 — `CalcEngine` is an `abstract final class` with static `evaluate`/`evaluateSource` in `lib/core/engine/calc_engine.dart` — the engine is stateless and T14 names `CalcEngine.evaluate(tokens, …)`; no instance/provider is needed.
- 2026-10-25 — The facade catches only `FormatException` (tokenizer/parser) and maps it to `CalcError.syntax`; evaluator code is written to return `Failure` for every bad case, so other exceptions stay visible as bugs instead of being silently swallowed.
- 2026-10-25 — The §2–§8 acceptance table asserts the final display string (evaluate → `formatNumber`) rather than only `CalcResult` — it is the contract the UI shows, and it keeps formatter regressions visible.
- 2026-10-25 — `InputBuffer` is immutable: every key returns a new buffer, and a no-op returns `this` — the T17 Notifier can skip rebuilds by identity, and the rules stay pure and testable.
- 2026-10-25 — `InputBuffer` inserts the hidden `OperatorToken(multiply, implicit: true)` itself when a digit or dot starts after a value — the buffer bypasses the tokenizer, so §3's implicit-× post-pass would otherwise be lost.
- 2026-10-25 — `appendOperator` takes `startValue` (default `NumberToken('0')`) instead of reading `Ans` — `lib/core/input/` is pure and stateless; T17 passes `NumberToken(ans.toString())` to honour §5's "start from Ans".
- 2026-10-25 — A trailing `UnaryToken` is dropped before an operator is applied, and non-minus operators after a function/`(` are ignored — §5 does not define these incomplete states; dropping the sign makes `5×−` + `+` become `5+`, and ignoring avoids invalid `sin(+` / `(+` buffers.

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

### T11 — Trig functions — 2026-10-25
Status: DONE
Changed: new `lib/core/engine/angle_mode.dart` (`enum AngleMode { deg, rad }`), `lib/core/engine/evaluator.dart` (`evaluate(..., {angleMode = AngleMode.deg})`, sin/cos/tan + inverses, DEG/RAD conversion, tan domain rules, §2 15-digit rounding + 1e-12 snap), `test/core/engine/evaluator_test.dart`.
Tests: DEG `sin(30)`=0.5, `sin(180)`/`sin(360)`/`cos(90)` snap to 0, `cos(60)`=0.5, `cos(180)`=−1, `tan(45)`=1, `tan(180)`=0, `tan(90/270/−90)`→domain, `sin⁻¹(0.5)`=30, `cos⁻¹(0.5)`=60, `tan⁻¹(1)`=45, `sin⁻¹(1)`=90, `cos⁻¹(−1)`=180, `sin⁻¹(2)`/`sin⁻¹(−2)`/`cos⁻¹(1.5)`→domain, trig inside expressions; RAD `cos(π)`=−1, `sin(π÷2)`=1, `tan(π÷2)`→domain, `sin⁻¹(1)`=π/2, `sin(30)` and `2×sin(30)` prove the mode threads through the tree; 12 trig tests; `flutter test` 113/113 pass; `flutter analyze` clean.
Notes for next session: `evaluate` takes `AngleMode` as an optional named parameter and every recursive call forwards it; T14's facade can pass `settings.angle` straight through. Transcendental results go through `_fromDouble` (NaN→domain, infinite→overflow, `toStringAsPrecision(15)`, snap `<1e-12` to 0). `tan` DEG checks `x % 180 == 90` on the Decimal (covers ±90, 270…); RAD checks `|cos(x)| < 1e-12`. `ln log eˣ 10ˣ √ ∛`, `^`, `mod`, `!`, `x²`/`x³` still return `Failure(CalcError.syntax)` (T12).
Next: T12 Other functions

### T12 — Other functions — 2026-10-25
Status: DONE
Changed: `lib/core/engine/evaluator.dart` (`ln`, `log`, `eˣ`, `10ˣ`, `√`, `∛`, `xʸ` with exact integer exponents, `n!` via BigInt, `x²`/`x³`), `test/core/engine/evaluator_test.dart`.
Tests: `ln(1)`=0, `ln(e)`=1, `ln(0)`/`ln(−1)`→domain, `log(1000)`=3, `log(0.001)`=−3, `log(−10)`→domain, `eˣ(0)`=1, `eˣ(1)`=2.71828182845905, `10ˣ(2)`=100, `10ˣ(−2)`=0.01, `eˣ(710)`→overflow; `√144`=12 exact, `√2.25`=1.5, `√(9+16)`=5, `∛27`=3, `∛−8`=−2, `√2`=1.41421356237310, `√(−4)`→domain; `2^10`, `2^100` (31 digits), `(−2)^3`, `2^−2`, `0^0`=1, `0^−1`→divideByZero, `3^−1` truncates at 32 places, `2^3^2`=512, `2^0.5`, `(−2)^0.5`→domain, `10^400`→overflow; `0!`/`1!`/`5!`/`10!`/`20!` exact, `5.5!`/`(−3)!`→domain, `171!`→overflow; `5²`/`5³`/`(−3)²`/`(−3)³`; 15 new tests; `flutter test` 128/128 pass; `flutter analyze` clean.
Notes for next session: integer `xʸ` (|y| ≤ 1000) uses `Decimal.pow` → `Rational.toDecimal(scaleOnInfinitePrecision: 32)`, so negative integer exponents truncate like `÷`; non-integer `y` goes through `math.pow` and `_fromDouble`, and a negative base there is `domain`. `√`/`∛` rely on the 15-digit rounding to return perfect squares/cubes exactly (`√144` → `12`). `mod` is deliberately still `Failure(syntax)`: it is a programmer-mode integer operator (§11), not a Decimal-engine one. `1/x` is a keypad input (`1÷…`), not a function. T13 is the formatter next.
Next: T13 Formatter

### T13 — Formatter — 2026-10-25
Status: DONE
Changed: new `lib/core/engine/formatter.dart` (`NumberFormatOptions`, `formatNumber`, `formatNumberForCopy`, `formatTypedNumber`, `numberFormatOptionsFor`), new `test/core/engine/formatter_test.dart`.
Tests: Auto keeps `0.3`, strips `1.2300`→`1.23`, rounds to 12 significant digits (`1.234567890123456`→`1.23456789012`, 32-nines→`1`), groups `1234567.891`→`1,234,567.891`; fixed 0/2/10 places with half-up (`1.005`→`1.01`) and trailing zeros (`1.5`→`1.50`, `2`→`2.00`); grouping off; de locale `1.234.567,891`; `numberFormatOptionsFor` en_US/de_DE; sci thresholds `1e14` plain vs `1e15`→`1E+15`, `1e-9` plain vs `1e-10`→`1E-10`, 10-digit mantissa `1.23456789E+18`, `2.5E-11`, fixed 2 `1.00E+18`; display `−` vs copy `-`; typed expression numbers keep digits (`12.50`, `12.`) and group; 15 tests; `flutter test` 143/143 pass; `flutter analyze` clean.
Notes for next session: the formatter is pure Dart and takes separators as strings, so T14/T20 can call `numberFormatOptionsFor(Locale.toString(), decimalPlaces: settings.decimals, useGrouping: settings.separators)` without importing Flutter. `formatTypedNumber` is for the expression line (§8.6) and never rounds. Auto uses §8's 12 significant digits (SPEC's settings text says "up to 10 significant decimals" — §8 wins for the engine; logged). Sci notation rounds/keeps zeros based on the fixed setting: Auto strips, fixed keeps (`1.00E+18`). T14 builds `CalcEngine` on top of tokenize→parse→evaluate→format.
Next: T14 Engine facade + big test table

### T14 — Engine facade + big test table — 2026-10-25
Status: DONE
Changed: new `lib/core/engine/calc_engine.dart` (`abstract final class CalcEngine` with static `evaluate(List<Token>, {angleMode})` and `evaluateSource(String, {angleMode})`), new `test/core/engine/calc_engine_test.dart` (70-row table).
Tests: 70 rows covering §2 exact arithmetic/division, powers/`x²`/`x³`, unary/constants, §4 percent, §6 trig/logs/roots/factorial, §8 grouping/rounding/sci thresholds, auto-close and §7 errors — all source→display strings; plus `evaluateSource` = `evaluate(tokens)`, unknown text/empty input → `Invalid input` (no throw), and angle-mode forwarding; `flutter test` 147/147 pass; `flutter analyze` clean.
Notes for next session: `CalcEngine` catches `FormatException` from the tokenizer/parser and returns `Failure(CalcError.syntax)`; the evaluator itself never throws. `evaluate` takes the `List<Token>` from the input buffer, `evaluateSource` is for paste/history/tests. The table formats with default `formatNumber` (grouping on, Auto 12 digits), so any future formatter change must keep these rows green. Phase 1 (engine) is complete — T15 starts the input buffer.
Next: T15 InputBuffer: digits, decimal, operators

### T15 — InputBuffer: digits, decimal, operators — 2026-10-25
Status: DONE
Changed: new `lib/core/input/input_buffer.dart` (immutable `InputBuffer`, `appendDigit`, `appendDecimalPoint`, `appendOperator`, `maxDigits`, token equality), new `test/core/input/input_buffer_test.dart`.
Tests: digits append/leading-zero (`05`→`5`, `000`→`0`, `007`→`7`), 15-digit cap, implicit × after `π`/`)`, new number after an operator; one dot per number, leading `.`→`0.`, dot after a value→implicit ×; operator append/replace (`+` then `×`→`×`), `−` after `×`/`÷`→`UnaryToken`, `−` after `+` replaces, empty buffer→`0+`/`0−` and custom start value, dangling sign replacement, operator after a value, no operator after a function except `−`; 17 tests; `flutter test` 164/164 pass; `flutter analyze` clean.
Notes for next session: `InputBuffer` is immutable and returns `this` for no-ops; T16 adds `(`, `)`, `±`, `⌫`, `C` on the same class. The buffer inserts the hidden `×` itself because it bypasses the tokenizer. `appendOperator` takes `startValue` (default `NumberToken('0')`); T17 passes `NumberToken(ans.toString())` for §5's "start from Ans". `RightParenToken`/`ConstantToken`/`PostfixToken`/`AnsToken` already count as value-ending for implicit ×, so T16 only needs the bracket rules.
Next: T16 InputBuffer: brackets, ±, backspace
