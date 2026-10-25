# ARCHITECTURE — structure, packages, state

## Packages (add with `flutter pub add <name>`; let pub pick current versions)

| Package | Why |
|---|---|
| `flutter_riverpod` | State management (Notifier / AsyncNotifier). |
| `decimal` | Exact arithmetic (BUSINESS_LOGIC §2). |
| `shared_preferences` | Settings, history, memory, currency cache. |
| `http` | Currency rates. |
| `intl` | Number/date formatting, locale separators. |
| `google_fonts` | Ubuntu font (or bundle the font files in `assets/fonts/`). |
| dev: `flutter_lints`, `flutter_test` | Lints + tests (already in a new project). |

No other packages without a logged Decision.

## Folder structure

```
calculator/
├─ AGENTS.md                      ← agent rules (read first, every session)
├─ docs/
│  ├─ TASKS.md                    ← checklist; agent ticks tasks
│  ├─ PROGRESS.md                 ← append-only log + decisions (agent memory)
│  ├─ SPEC.md                     ← features
│  ├─ BUSINESS_LOGIC.md           ← engine rules
│  ├─ ARCHITECTURE.md             ← this file
│  └─ DESIGN.md                   ← tokens
├─ lib/
│  ├─ main.dart                   ← ProviderScope + App
│  ├─ app.dart                    ← MaterialApp, theme, ShellPage (bottom nav)
│  ├─ theme/
│  │  ├─ app_tokens.dart          ← colours, radii, spacing, text sizes (from DESIGN.md)
│  │  └─ app_theme.dart           ← light/dark ThemeData built from tokens + accent
│  ├─ core/                       ← PURE DART. No Flutter imports.
│  │  ├─ engine/
│  │  │  ├─ token.dart            ← Token types
│  │  │  ├─ tokenizer.dart        ← string → tokens, implicit × insertion
│  │  │  ├─ ast.dart              ← node classes
│  │  │  ├─ parser.dart           ← tokens → AST (precedence climbing)
│  │  │  ├─ evaluator.dart        ← AST → CalcResult (Decimal)
│  │  │  ├─ functions.dart        ← sin/cos/ln/… with domain checks
│  │  │  ├─ calc_result.dart      ← Success / Failure + CalcError
│  │  │  └─ formatter.dart        ← Decimal → display string
│  │  ├─ input/
│  │  │  ├─ input_buffer.dart     ← token list editing rules (BUSINESS_LOGIC §5)
│  │  │  └─ calc_key.dart         ← enum of every key
│  │  ├─ programmer/
│  │  │  ├─ word.dart             ← BigInt + wordSize, masks, signed view
│  │  │  ├─ prog_parser.dart
│  │  │  └─ base_format.dart      ← HEX/DEC/OCT/BIN strings
│  │  ├─ units/
│  │  │  ├─ unit.dart             ← Unit, UnitCategory models
│  │  │  ├─ unit_catalog.dart     ← const data (BUSINESS_LOGIC §12)
│  │  │  └─ unit_converter.dart   ← convert(), temperature formulas
│  │  ├─ currency/
│  │  │  ├─ rates.dart            ← Rates model + crossRate()
│  │  │  └─ currency_repository.dart ← fetch + cache (uses an injected http client)
│  │  ├─ tools/
│  │  │  ├─ loan.dart  percentage.dart  discount.dart  tip.dart  age.dart
│  │  │  ├─ date_diff.dart  bmi.dart  gpa.dart  equation.dart  statistics.dart
│  │  └─ storage/
│  │     ├─ kv_store.dart         ← abstract key-value interface
│  │     └─ prefs_store.dart      ← shared_preferences implementation (only file that imports it)
│  ├─ features/
│  │  ├─ calculator/
│  │  │  ├─ calculator_page.dart  ← mode switcher + display + keypad
│  │  │  ├─ calculator_controller.dart ← Riverpod Notifier wrapping InputBuffer + engine
│  │  │  ├─ widgets/  display.dart  keypad.dart  calc_key_button.dart  mode_switcher.dart
│  │  │  └─ keypads/  basic_keys.dart  scientific_keys.dart  programmer_keys.dart
│  │  ├─ history/   history_page.dart  history_controller.dart  memory_controller.dart  widgets/
│  │  ├─ converter/ converter_hub_page.dart  unit_convert_page.dart  converter_controller.dart  widgets/
│  │  ├─ currency/  currency_page.dart  currency_controller.dart  widgets/
│  │  ├─ tools/     tools_hub_page.dart  tool_scaffold.dart  pages/loan_page.dart …
│  │  └─ settings/  settings_page.dart  settings_controller.dart  settings_model.dart
│  └─ shared/
│     └─ widgets/  bottom_nav.dart  blue_header.dart  white_sheet.dart  segmented.dart  number_field.dart
├─ test/                          ← mirrors lib/ (core tests are the priority)
│  └─ core/engine/evaluator_test.dart …
└─ assets/fonts/ (optional Ubuntu .ttf files)
```

## State (Riverpod)

| Provider | Type | Holds |
|---|---|---|
| `settingsProvider` | `Notifier<Settings>` | theme, accent, angle, decimals, separators, haptics, sound, retention |
| `calculatorProvider` | `Notifier<CalcState>` | mode, buffer tokens, preview, result, error, 2nd, ans |
| `programmerProvider` | `Notifier<ProgState>` | value Word, input base, word size |
| `memoryProvider` | `Notifier<List<Decimal?>>` | M1..M10 |
| `historyProvider` | `Notifier<List<HistoryEntry>>` | entries |
| `converterProvider` | `Notifier<ConvState>` | category, from, to, input, favourites |
| `currencyProvider` | `AsyncNotifier<CurrencyState>` | rates, status, base, list, amount |
| `kvStoreProvider` | `Provider<KvStore>` | storage (overridden in tests with an in-memory store) |

Flow: widget → `ref.read(xProvider.notifier).onKey(key)` → controller updates state using `core/` → widget rebuilds via `ref.watch`.

## Navigation

`ShellPage` with `IndexedStack` of 4 tabs + `NavigationBar`-style custom bottom nav (DESIGN.md).
Push routes (Navigator 2 not needed): Settings, UnitConvert, Currency, each Tool page.

## Testing rules

- Every file in `lib/core/` has a test file. Engine tests use tables: `('2+3×4', '14')`, `('200+10%', '220')`, …
- Widget tests only for: keypad renders all keys for each mode; display shows error text.
- Run `flutter test` before every commit.
