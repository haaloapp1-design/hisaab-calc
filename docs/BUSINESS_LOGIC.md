# BUSINESS LOGIC — how every calculation works

All of this lives in `lib/core/` as pure Dart (no Flutter imports) and is unit tested.
Sections are numbered so tasks can point to them (e.g. "Read: BUSINESS_LOGIC §3").

---

## §1 Engine pipeline

```
key presses ──► InputBuffer (list of tokens the user typed)
                    │  (on every change, for live preview; and on "=")
                    ▼
              Tokenizer  →  Parser (precedence climbing)  →  AST  →  Evaluator  →  Formatter  →  display string
```

- `InputBuffer` holds **tokens**, not characters. `sin(` is ONE token, so ⌫ removes it in one tap.
- `Tokenizer` turns a string into tokens too (used for paste and for loading history).
- `Parser` builds an AST (`NumberNode`, `ConstNode`, `UnaryNode`, `BinaryNode`, `FuncNode`, `PostfixNode`).
- `Evaluator` walks the AST and returns `CalcResult` = `Success(Decimal value)` or `Failure(CalcError)`.
- `Formatter` turns a `Decimal` into the display string using Settings (§8).
- Nothing throws to the UI. Every failure is a `CalcError` (§7).

## §2 Number representation

- Use `Decimal` (package `decimal`) for: `+ − × ÷ %`, `±`, `x²`, `xʸ` with integer `y`, `1/x`, `n!`, memory, history.
  This makes `0.1 + 0.2 = 0.3` exactly.
- Division: `a / b` → `(a / b).toDecimal(scaleOnInfinitePrecision: 32)`. Division by zero → `CalcError.divideByZero`.
- Transcendental functions (`sin cos tan`, inverses, `ln log eˣ 10ˣ`, `√ ∛`, `xʸ` with non-integer `y`, `π`, `e`)
  use `dart:math` on `double`, then convert back:
  1. `d = math.sin(x.toDouble())`
  2. if `d.isNaN` → `CalcError.domain`; if `d.isInfinite` → `CalcError.overflow`
  3. round to 15 significant digits: `Decimal.parse(d.toStringAsPrecision(15))`
  4. **snap**: if `|value| < 1e-12` → `0` (so `sin(180°)` shows `0`, not `1.2E-16`).
- `√x`: if `x` is a perfect square of a small Decimal (e.g. 144) return the exact Decimal (12).
- Overflow: any result whose absolute value ≥ `1e300` → `CalcError.overflow` ("Number too large").

## §3 Grammar, precedence and implicit multiplication

Precedence (high → low):

| Level | Operators | Associativity | Notes |
|---|---|---|---|
| 6 | `!` `%` (postfix) | left | `5!`, `50%` |
| 5 | `^` (xʸ), `x²` `x³` (postfix power) | **right** | `2^3^2 = 2^9 = 512` |
| 4 | unary `−` `+` | right | `−2^2 = −4` (power binds first, like most scientific calculators) |
| 3 | implicit multiplication | left | `2π`, `3(4)` |
| 2 | `×` `÷` `mod` | left | |
| 1 | `+` `−` | left | |

Functions (`sin(`, `ln(`, `√(` …) are prefix with their bracket; argument is the full bracket content.
Constants: `π = 3.14159265358979323846`, `e = 2.71828182845904523536` (keep as Decimal strings).

**Implicit multiplication** — the tokenizer inserts a hidden `×` between A and B when:
- A is a number, constant, `)`, `!`, `%`, `Ans`, or postfix power, AND
- B is a number, constant, `(`, a function, or `Ans`.
So `2π` → `2×π`, `(1+2)(3)` → `(1+2)×(3)`, `2sin(30)` → `2×sin(30)`. (Number followed by number never happens: digits merge.)

**Auto-closing brackets**: on `=`, append the missing `)`. Extra `)` typed by the user is ignored by the input rules (§5).

## §4 Percent rules (what `%` means)

Matches common phone calculators:

| Input | Meaning | Result |
|---|---|---|
| `50%` alone | 50 / 100 | `0.5` |
| `200 + 10%` | 200 + (200 × 10/100) | `220` |
| `200 − 10%` | 200 − (200 × 10/100) | `180` |
| `200 × 10%` | 200 × (10/100) | `20` |
| `200 ÷ 10%` | 200 ÷ (10/100) | `2000` |

Rule: when `%` follows the right operand of `+` or `−`, the percent is taken **of the left operand**.
Otherwise `x%` = `x / 100`. Implement in the parser: `BinaryNode(+/−, left, PercentNode(right))` → special case.

## §5 Input rules (the keypad state machine)

`InputController` (Riverpod Notifier) owns `InputBuffer`, `lastResult (Ans)`, `justEvaluated` flag, `lastOp` (for repeat `=`).

| Key | Rule |
|---|---|
| digit | Appends to current number. Leading zeros: `0` then `5` → `5` (not `05`). Max 15 digits per number. |
| `.` | Only one per number. `.` at the start of a number inserts `0.` |
| operator `+ − × ÷` | If last token is an operator, **replace** it (except `−` after `×`/`÷`/`(`, which starts a negative number). If buffer is empty, start from `Ans` (or `0`). |
| `(` | Always allowed; implicit × handled by §3. |
| `)` | Only allowed if open count > close count and last token is not an operator or `(`. |
| `±` | Toggles the sign of the **current number** (wraps it: `5` → `(−5)`; pressing again unwraps). |
| `⌫` | Removes the last token (whole function token like `sin(` at once; one digit at a time inside a number). Long-press = `C`. |
| `C` / `AC` | Clears buffer and preview. Does NOT clear memory or Ans. |
| `=` | Evaluate. On success: push to history, set `Ans`, set `justEvaluated=true`, remember `lastOp` (operator + right operand). Pressing `=` again applies `lastOp` to the result (`5 + 3 = = =` → 8, 11, 14). On error: show message, keep buffer so user can fix it. |
| after `=` | Typing a **digit/function/constant** starts a new expression. Typing an **operator** continues from the result (`Ans + …`). |
| `Ans` | Inserts the last result as a number token. |
| `2nd` | Toggles alternate key set (SPEC §1.3); turns itself off after one function is inserted. |

**Live preview**: after every key, try to evaluate (auto-closing brackets). If success and the buffer contains at least one operator or function → show preview. If incomplete or error → show nothing (never show errors in preview).

## §6 Trigonometry and other function rules

- Angle mode DEG: `sin(x)` = `sin(x × π/180)`. Inverse functions return degrees: `sin⁻¹(y) × 180/π`. RAD: no conversion.
- `tan(x)`: in DEG, if `x mod 180 == 90` → `CalcError.domain` ("Undefined"). In RAD use `|cos(x)| < 1e-12` as undefined.
- `sin⁻¹`, `cos⁻¹`: input must be in [−1, 1] else `domain`.
- `ln(x)`, `log(x)`: `x > 0` else `domain`. `√x`: `x ≥ 0` else `domain`. `∛x` accepts negatives.
- `n!`: `n` must be a non-negative integer ≤ 170, computed with BigInt then to Decimal. Else `domain` (non-integer/negative) or `overflow` (>170).
- `1/x`: `x == 0` → `divideByZero`.
- `xʸ`: `0^0 = 1`. Negative base with non-integer `y` → `domain`. Integer `y` (|y| ≤ 1000) uses Decimal `pow` exactly.

## §7 Errors

```dart
enum CalcError { divideByZero, domain, overflow, syntax, tooLong }
```
| Error | Display text |
|---|---|
| divideByZero | Can't divide by zero |
| domain | Undefined (or "Invalid input" for syntax-like domain issues) |
| overflow | Number too large |
| syntax | Invalid input |
| tooLong | Expression too long (limit 200 tokens) |

## §8 Formatting (Decimal → display string)

1. If Settings.decimalPlaces is fixed `n`: round half-up to `n` places, keep trailing zeros.
   If Auto: round to 12 significant digits, then strip trailing zeros and a trailing `.`.
2. Use scientific notation when `|v| ≥ 1e15` or `0 < |v| < 1e-9`: format `1.2345678E+18` (max 10 digits mantissa).
3. Thousands separator (if on) only in the integer part: `1234567.891` → `1,234,567.891`.
4. Locale: decimal and group separators from `intl` `NumberFormat` symbols for the device locale.
5. Negative sign is `−` (U+2212) in the display, `-` in copied text.
6. The expression line shows numbers exactly as typed (with separators), operators as `+ − × ÷`.

## §9 Memory and Ans

- `Ans` = last successful `=` result (persisted). Starts at `0`.
- Memory slots `M1..M10` (Decimal, persisted). Main memory = `M1`.
  - `MS` store current value into a new slot (or M1 if only one used). `MC` clear slot. `MR` insert slot value as a number token.
  - `M+` / `M−` add/subtract the **current display value** (result if just evaluated, else live preview, else current number).
- Memory chip on display shows `M = <M1>` when M1 ≠ 0 or any slot is set.

## §10 History

```dart
class HistoryEntry { String id; String expression; String result; String mode; // basic|scientific|programmer|converter|tool
                     DateTime createdAt; }
```
- Added on every successful `=` (and on "Save to history" from converters/tools). Skip if identical to the previous entry.
- Stored as a JSON list in `shared_preferences` (key `history_v1`), newest first, max 500. Older than retention (Settings) deleted on app start.
- Grouped in UI by local date: Today / Yesterday / `d MMM yyyy`.
- Tap → `InputController.loadExpression(entry.expression)` (re-tokenize), switch to that mode.

## §11 Programmer mode

- Value type: `BigInt` + `wordSize` (8/16/32/64). `mask = (1 << wordSize) − 1`.
- Store the raw bit pattern `u = value & mask` (unsigned). Signed view: if bit `wordSize−1` is set → `u − (1 << wordSize)`.
- DEC row shows the **signed** value; HEX/OCT/BIN show the unsigned bit pattern.
- Every result is re-masked: `result & mask` (this gives two's-complement wrap-around).
- Ops on signed values: `+ − × ÷` (÷ truncates toward zero; ÷0 → error), `mod` (remainder, sign follows dividend),
  `AND & OR | XOR ^`, `NOT x = ~x & mask`, `NAND = ~(a & b) & mask`, `<< n` (then mask), `>> n` arithmetic (keeps sign).
- Precedence: `NOT` (unary) > `× ÷ mod` > `+ −` > `<< >>` > `AND` > `XOR` > `OR` (same as C).
- Input digits valid per base: BIN 0–1, OCT 0–7, DEC 0–9, HEX 0–9 A–F. Switching base converts the current value, not the text.
- BIN display: pad to a multiple of 4 and group by 4 (`0111 1110 0101`).
- Changing word size re-masks the current value (may truncate; show a short toast "Value truncated to 16-bit").

## §12 Unit conversion

Every unit has a **factor to the category's base unit**: `valueInBase = v × factor`; `result = valueInBase / factorTo`.
Do conversions in Decimal. Data lives in `lib/core/units/unit_catalog.dart` as const data.

Base units: Length m · Area m² · Volume L · Mass kg · Speed m/s · Time s · Data byte · Pressure Pa · Energy J · Power W · Angle rad.

Exact/standard factors to use:

| Unit | Factor to base |
|---|---|
| in / ft / yd / mi / nmi | 0.0254 / 0.3048 / 0.9144 / 1609.344 / 1852 m |
| acre / hectare | 4046.8564224 / 10000 m² |
| marla / kanal | 25.29285264 m² (272.25 ft²) / 20 marla — **traditional, varies by region; make the marla size a Setting later** |
| mL / m³ | 0.001 / 1000 L |
| US gal / UK gal | 3.785411784 / 4.54609 L |
| US cup / US fl oz / tbsp / tsp | 0.2365882365 / 0.0295735295625 / 0.01478676478125 / 0.00492892159375 L |
| lb / oz / stone | 0.45359237 / 0.028349523125 / 6.35029318 kg |
| tola / maund | 0.0116638038 / 37.3242 kg (traditional, label as approximate) |
| km/h / mph / knot | 1/3.6 / 0.44704 / 1852/3600 m/s |
| min / h / day / week / year | 60 / 3600 / 86400 / 604800 / 31536000 s |
| bit / KB / MB / GB / TB | 0.125 / 1e3 / 1e6 / 1e9 / 1e12 byte; KiB/MiB/GiB = 1024 / 1024² / 1024³ |
| kPa / bar / psi / atm / mmHg | 1000 / 100000 / 6894.757293168 / 101325 / 133.322387415 Pa |
| kJ / cal / kcal / Wh / kWh | 1000 / 4.184 / 4184 / 3600 / 3600000 J |
| kW / hp (mechanical) | 1000 / 745.69987158227 W |
| degree / gradian | π/180 / π/200 rad |

**Temperature is not a factor** — use formulas via Kelvin:
`toK: C → C + 273.15; F → (F − 32) × 5/9 + 273.15; K → K`, `fromK` is the inverse. Below 0 K → error "Below absolute zero".

Rule line: show `1 <from> = <convert(1)> <to>`, formatted with 6 significant digits.
"Is also" list: 4 popular units in the same category (defined per category in the catalog), excluding from/to.

## §13 Currency

- Source: a free JSON rates API returning rates relative to one base (e.g. USD). Suggested: `https://open.er-api.com/v6/latest/USD`
  (verify terms before release; keep the URL in one constant so it can be swapped).
- Cross rate: `amount_in_to = amount × rate[to] / rate[from]` (all rates relative to the API base).
- Cache: save the whole response + `fetchedAt` in `shared_preferences` (`currency_cache_v1`).
- Refresh policy: on screen open, if cache older than 6 h and online → fetch in background. Pull-to-refresh forces fetch.
- Status: `live` (fetched < 6 h), `cached` (older; show date), `none` (no data yet → show "Connect once to download rates").
- Display: values 2 decimals (thousands separators per Settings); rate line 4 significant decimals.
- Network errors never crash; they set status and keep the old cache.

## §14 Tools — formulas

**Loan / EMI** (`P` principal, `R` annual %, `n` months):
`r = R / 12 / 100`; if `r == 0` → `EMI = P / n`; else `EMI = P × r × (1+r)^n / ((1+r)^n − 1)`.
Total = `EMI × n`; Interest = Total − P. Schedule: for each month `interest = balance × r`, `principal = EMI − interest`,
`balance −= principal`; last month adjust so balance ends at exactly 0. Round display to 2 dp.
Check: P = 1,000,000, R = 12, n = 60 → EMI 22,244.45, interest 334,666.86.

**Percentage**: `X% of Y = X×Y/100`; `X is what % of Y = X/Y×100` (Y≠0); `% change = (Y−X)/X×100` (X≠0).

**Discount and tax**: `afterDiscount = price × (1 − d/100)`; `final = afterDiscount × (1 + t/100)`; `saved = price − afterDiscount`.

**Tip and split**: `tip = bill × t/100`; `total = bill + tip`; `perPerson = total / people` (people ≥ 1); option "round up" = ceil to whole currency unit.

**Age**: calendar difference: years, then months, then days (borrow days from the previous month's length).
Birthday on 29 Feb → in non-leap years treat as 28 Feb. Also total days = `onDate.difference(dob).inDays`.

**Date difference**: `days = end − start` (+1 if "include end date"). Weeks = days ~/ 7, remainder days. Add/subtract days uses `DateTime.add(Duration(days: n))` on date-only values (use UTC midnight to avoid DST bugs).

**BMI**: `kg / (m²)`. ft+in → `m = (ft×12 + in) × 0.0254`; lb → `kg = lb × 0.45359237`.
Category (WHO adult): < 18.5 Underweight · 18.5–24.9 Normal · 25–29.9 Overweight · ≥ 30 Obese. Show "for adults" note.

**GPA**: `GPA = Σ(credits × points) / Σ credits` (Σ credits > 0). Grade scale is configurable (default 4.0 scale).

**Equation solver**: linear `ax + b = 0` → `x = −b/a` (a = 0: "No solution" if b ≠ 0, "Every x is a solution" if b = 0).
Quadratic `ax² + bx + c = 0` (a ≠ 0, else linear): `D = b² − 4ac`; D > 0 two real roots; D = 0 one root `−b/2a`;
D < 0 complex `−b/2a ± i√(−D)/2a`. Show D.

**Statistics**: count, sum, mean, median (average of two middle values if even), mode (all values with max frequency; "none" if all once),
min, max, range, population SD `√(Σ(x−μ)²/n)`, sample SD `√(Σ(x−x̄)²/(n−1))` (n ≥ 2).
