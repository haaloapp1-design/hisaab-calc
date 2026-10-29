# TASKS — do them in order, ONE per session

How to use: find the first `- [ ]`, read only what its **Read** line says, do it, meet **Done when**,
tick it `- [x]`, log it in PROGRESS.md, commit, stop.
If a task is too big, split it into `T07a`, `T07b` right here and do the first part.

---

## Phase 0 — Setup

- [x] **T01 Packages and skeleton** — Read: ARCHITECTURE (Packages, Folder structure).
  Add packages; create every folder in `lib/` and `test/` with an empty placeholder where needed; `main.dart` shows a blank `ProviderScope` app.
  Done when: `flutter analyze` clean, app runs, folders match ARCHITECTURE.
- [x] **T02 Theme tokens** — Read: DESIGN.md.
  Create `app_tokens.dart` (all colours, radii, sizes) and `app_theme.dart` (light theme, Ubuntu font).
  Done when: app shows a test screen using primary + sheet colours; no hard-coded colours outside theme/.
- [x] **T03 Storage layer** — Read: ARCHITECTURE (State, `kvStoreProvider`).
  `KvStore` interface (getString/setString/remove), `PrefsStore`, `MemoryKvStore` for tests, `kvStoreProvider`.
  Done when: tests for MemoryKvStore pass.

## Phase 1 — Calculation engine (pure Dart)

- [x] **T04 Results and errors** — Read: BUSINESS_LOGIC §1, §7. Files: `calc_result.dart`, `token.dart`.
  Done when: `CalcResult` sealed class + `CalcError` enum with display texts; tests.
- [x] **T05 Tokenizer: numbers, operators, brackets** — Read: §3.
  Done when: `"12.5+3×(4−1)"` → correct tokens; `−` after operator/`(` becomes unary; tests.
- [x] **T06 Tokenizer: functions, constants, implicit ×** — Read: §3.
  Done when: `2π`, `3(4)`, `(1)(2)`, `2sin(30)`, `5!2` tokenize with hidden ×; tests.
- [x] **T07 Parser core** — Read: §3 (precedence table). Files: `ast.dart`, `parser.dart`.
  Done when: `2+3×4`→14 tree, `2^3^2` right-assoc, `−2^2` = −(2^2), brackets; tests on AST shape.
- [x] **T08 Parser: postfix, functions, auto-close** — Read: §3, §4.
  Done when: `5!`, `50%`, `x²`, `sin(30`, `((2+3` (auto-closed) parse; tests.
- [x] **T09 Evaluator: arithmetic with Decimal** — Read: §2.
  Done when: `0.1+0.2`=`0.3`, `1÷3×3`=`1`, `5÷0`→divideByZero; tests.
- [x] **T10 Percent rules** — Read: §4.
  Done when: all 5 rows of the §4 table pass as tests.
- [x] **T11 Trig functions** — Read: §2 (snap), §6.
  Done when: DEG `sin(30)`=0.5, `sin(180)`=0, `tan(90)`→Undefined, `sin⁻¹(2)`→domain; RAD `cos(π)`=−1; tests.
- [x] **T12 Other functions** — Read: §6.
  Done when: `ln`, `log`, `eˣ`, `10ˣ`, `√144`=12 exact, `∛−8`=−2, `xʸ` rules, `5!`=120, `171!`→overflow, `1/0`→error; tests.
- [x] **T13 Formatter** — Read: §8.
  Done when: separators, auto vs fixed decimals, sci notation thresholds, trailing zero strip, `−` sign; tests.
- [x] **T14 Engine facade + big test table** — Read: §1.
  `CalcEngine.evaluate(tokens, {angleMode})` → CalcResult. Add a 40+ row table test covering §2–§8.
  Done when: all pass.

## Phase 2 — Input rules

- [x] **T15 InputBuffer: digits, decimal, operators** — Read: §5 (rows digit, `.`, operator).
  Done when: leading-zero, one-dot, operator-replace, negative-after-× rules tested.
- [x] **T16 InputBuffer: brackets, ±, backspace** — Read: §5 (rows `(`, `)`, `±`, `⌫`, `C`).
  Done when: `)` only when valid, `±` wrap/unwrap, ⌫ removes `sin(` in one step; tests.
- [x] **T17 CalculatorController + live preview** — Read: §5 (live preview), ARCHITECTURE (State).
  Riverpod Notifier with `onKey(CalcKey)`; preview rule. Done when: controller tests with MemoryKvStore pass.
- [x] **T18 Equals, repeat =, Ans, after-= behaviour** — Read: §5 (rows `=`, after `=`, `Ans`), §9 (Ans).
  Done when: `5+3===`→14; digit after `=` starts new; operator after `=` continues; Ans persists; tests.

## Phase 3 — Calculator UI

- [x] **T19 App shell and bottom nav** — Read: DESIGN (BottomNav), ARCHITECTURE (Navigation).
  Done when: 4 tabs switch with IndexedStack; placeholder pages; matches design nav.
- [x] **T20 Shared widgets** — Read: DESIGN (Components). `BlueHeader`, `WhiteSheet`, `Segmented`.
  Done when: used on a placeholder page; widget test renders them.
- [x] **T21 Keys and keypad grid** — Read: DESIGN (Shape, Type, key colours).
  `CalcKeyButton(kind)` (number/function/operator/equals/disabled), `Keypad(spec, columns)`; press animation; semantic labels.
  Done when: widget test renders a 4×5 spec.
- [x] **T22 Display widget** — Read: SPEC §1.1, DESIGN (Type).
  Done when: expression line scrolls, result auto-shrinks, preview colour, error text, memory chip.
- [x] **T23 Basic mode wired** — Read: SPEC §1.2.
  Done when: tapping keys on device calculates correctly end to end (`docs/screens/01-basic.html`).
- [x] **T24 Scientific mode** — Read: SPEC §1.3, §6.
  Done when: 5×7 keypad, DEG/RAD chip, 2nd toggles labels, bracket badge, mode switcher remembers mode (`docs/screens/02-scientific.html`).

## Phase 4 — Settings

- [x] **T25 Settings model and persistence** — Read: SPEC §3.
  Done when: `Settings` (immutable, copyWith, toJson/fromJson) saved via KvStore; tests.
- [x] **T26 Settings page** - Read: SPEC §3, DESIGN. Screen 05 (`docs/screens/05-settings.html`).
  Done when: every row works and persists; opened from Calculator header icon.
- [x] **T27 Apply settings** — Theme mode, accent colour, formatter options, angle default, haptics/sound.
  Done when: changing each setting visibly changes the app.

## Phase 5 — History and memory

- [x] **T28 History store** — Read: §10.
  Done when: add/skip-duplicate/max 500/retention cleanup/grouping helpers tested.
- [x] **T29 History page** — Read: SPEC §2. Screen 04 (`docs/screens/04-history-memory.html`).
  Done when: `=` adds entries; grouped list; tap loads into calculator; search; copy all; clear with confirm.
- [x] **T30 Memory** — Read: §9, SPEC §2.
  Done when: M1..M10 persisted; Memory tab with MR/M+/M−; memory chip on display; tests.

## Phase 6 — Programmer mode

- [x] **T31 Word and base formatting** — Read: §11.
  Done when: mask/signed view/two's complement/HEX-OCT-BIN strings (BIN grouped) tested, incl. 8/16/32/64-bit.
- [x] **T32 Programmer evaluation** — Read: §11 (ops, precedence).
  Done when: AND/OR/XOR/NOT/NAND/shifts/mod/÷ truncation/overflow wrap tested.
- [x] **T33 Programmer UI** — Read: SPEC §1.4. Screen 03 (`docs/screens/03-programmer.html`).
  Done when: base rows tap to switch, invalid digits disabled, word size chip, keys work.

## Phase 7 — Unit converter

- [x] **T34 Unit catalog** — Read: §12, SPEC §4 (units list).
  Done when: all categories/units as const data with factors; test that every unit converts 1 → base → 1 unchanged.
- [x] **T35 Converter logic** — Read: §12 (temperature, rule line, "is also").
  Done when: `5 km→mi`=3.10686, `100°C→°F`=212, `−40°C→°F`=−40, below 0 K error; tests.
- [x] **T36 Converter hub page** — Screen 06 (`docs/screens/06-converter-hub.html`). Done when: grid, currency card, search across units works.
- [x] **T37 Unit convert page** — Screen 07 (`docs/screens/07-unit-converter.html`). Done when: live conversion, unit pickers (bottom sheet list), swap, rule line, is-also list, keypad.
- [x] **T38 Favourites and memory of last pair** — Done when: star saves pair (shown on hub), last category/pair restored, "Save to history" works.

## Phase 8 — Currency

- [x] **T39 Rates and repository** — Read: §13.
  Done when: cross-rate maths, cache save/load, 6 h policy, status values; tests use a fake http client.
- [x] **T40 Currency page** — Read: SPEC §5. Screen 08 (`docs/screens/08-currency.html`).
  Done when: base + amount, list, add/remove/reorder, refresh + pull-to-refresh, offline shows cached date.

## Phase 9 — Tools

- [x] **T41 Tool scaffold and hub** — Screens 09–10 (`docs/screens/09-tools-hub.html`, `10-loan-emi.html`; layout only). Done when: hub grid opens each tool page (placeholders).
- [x] **T42 Loan logic** — Read: §14 Loan. Done when: example check (EMI 22,244.45) and r = 0 case and schedule ending at 0 tested.
- [x] **T43 Loan page** — Screen 10 (`docs/screens/10-loan-emi.html`). Done when: live results, rate input, years/months, bar, schedule table.
- [x] **T44 Percentage, Discount and tax, Tip and split** — Read: §14. Done when: logic tested + 3 pages.
- [x] **T45 Age and Date difference** — Read: §14. Done when: 29 Feb, month-borrow, include-end-date tested + 2 pages.
- [x] **T46 BMI and GPA** — Read: §14. Done when: unit conversions, categories, weighted GPA tested + 2 pages.
- [x] **T47 Equation solver and Statistics** — Read: §14. Done when: all quadratic cases, median even/odd, mode, SDs tested + 2 pages.

## Phase 10 — Polish and release

- [x] **T48 Accessibility pass** — Semantic labels on every key/icon button, text scale 1.3 without overflow, contrast check.
- [x] **T49 Dark theme** — Read: DESIGN (Dark theme). Done when: every screen readable in dark.
- [x] **T50 Release prep** — App name, icon, splash, Android release build runs on a real phone; update README.
- [x] **T52 Small-screen fit (T49 follow-up)** — On a real phone (360×736 dp) Scientific mode overflows by 38 px;
  every screen must fit 360×736 with system insets (edge-to-edge status bar / gesture bar), keeping all
  390×844 goldens unchanged at the design size. Add a small-screen layout test and re-verify on the phone.


## Extra

- [x] **T51 App name and icon** — Read: `ICON_README.md`, `flutter_launcher_icons.yaml`.
  Rename the app to **Hisab** everywhere: Android `android:label` in `android/app/src/main/AndroidManifest.xml`,
  iOS `CFBundleDisplayName` and `CFBundleName` in `ios/Runner/Info.plist`, `MaterialApp.title`, the header title in the UI,
  and "Calculator" in docs/SPEC.md. Do NOT change the Dart package name or applicationId.
  Add `flutter_launcher_icons` as a dev dependency, run `dart run flutter_launcher_icons`.
  Done when: `flutter analyze` clean, app installs on a phone showing "Hisab" with the حساب icon.
- [x] **T53 Release internet permission + portrait lock** — The release APK had no `INTERNET` permission (Flutter only
  adds it to the debug/profile manifests), so Currency showed "Offline · No rates yet" on a phone with Wi-Fi.
  Also lock phones to portrait (landscape overflowed on every screen). Done when: release APK on the phone shows live rates
  and stays portrait when rotated.
- [x] **T54 Play upload signing** — Release builds sign with an upload keystore read from git-ignored
  `android/key.properties`; build `app-release.aab`. Done when: the bundle's signer matches the upload key.
