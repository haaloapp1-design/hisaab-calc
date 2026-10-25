# SPEC — Features, screen by screen

App name: **Calculator**. Platforms: Android first, iOS second. Portrait phone layout (390×844 design size).
Works fully offline except live currency rates. Navigation: bottom bar with 4 tabs
(Calculator, Convert, Tools, History) + Settings from the gear/sliders icon on Calculator.

Screens (designs: the "Advanced Calculator — App Screens" canvas):
01 Basic · 02 Scientific · 03 Programmer · 04 History & Memory · 05 Settings ·
06 Converter hub · 07 Unit converter · 08 Currency · 09 Tools hub · 10 Loan/EMI (template for every tool)

---

## 1. Calculator tab (screens 01–03)

Shared layout: blue top area (title, mode switcher, display) + white rounded bottom sheet (keypad + nav).
Mode switcher: segmented control **Basic | Scientific | Programmer**. Last used mode is remembered.

### 1.1 Display
- Line 1 (small): the expression being typed, e.g. `1800 + 21 + 88`. Scrolls horizontally if long; auto-scrolls to the end.
- Line 2 (large): result. While typing it shows a **live preview** of the result (lighter colour).
  After `=` the result becomes bold/white and the expression moves to history.
- Font auto-shrinks (60 → 32 px) so the number always fits on one line.
- Thousands separators per Settings. Very large/small numbers switch to scientific notation (`1.23E+18`).
- Errors shown in the result line in plain words: "Can't divide by zero", "Invalid input", "Number too large".
- Memory chip (`M = 128`) shows when memory is not empty.
- Long-press display → Copy result / Paste number.

### 1.2 Basic mode keys (4×5)
`C ⌫ % ÷ / 7 8 9 × / 4 5 6 − / 1 2 3 + / ± 0 . =`
- `C` clears all. Long-press `⌫` also clears all.
- `±` toggles the sign of the current number.
- `%` behaviour: see BUSINESS_LOGIC §4.
- Operators can be chained; pressing an operator twice replaces the previous operator.
- Pressing `=` repeatedly repeats the last operation (`5 + 3 = = =` → 8, 11, 14).

### 1.3 Scientific mode keys (5×7)
`2nd sin cos tan π / x² xʸ √x ln log / ( ) n! 1/x e / 7 8 9 C ⌫ / 4 5 6 × ÷ / 1 2 3 + − / ± 0 . Ans =`
- **DEG / RAD** toggle chip above the display (default DEG; stored in Settings).
- **2nd** toggles alternate functions: sin→sin⁻¹, cos→cos⁻¹, tan→tan⁻¹, x²→x³, √x→∛x, ln→eˣ, log→10ˣ, xʸ→ʸ√x.
  When 2nd is on the key labels change and the 2nd key is highlighted.
- Brackets: open bracket count shown as a small badge; missing `)` are auto-closed on `=`.
- Implicit multiplication: `2π`, `3(4+1)`, `(2)(3)`, `2sin(30)` work.
- `Ans` inserts the last result.
- Functions insert with an open bracket: tapping `sin` inserts `sin(`.

### 1.4 Programmer mode (5×7)
- Base list: **HEX, DEC, OCT, BIN** rows always show the current value in all four bases; tapping a row makes it the input base.
- Digits not valid in the active base are disabled (e.g. A–F and 8–9 in OCT).
- Word size chip: 8 / 16 / 32 / 64-bit (default 32). Values wrap using two's complement.
- Keys: `AND OR XOR NOT NAND / A << >> AC ⌫ / B ( ) mod ÷ / C 7 8 9 × / D 4 5 6 − / E 1 2 3 + / F ± 0 . =`
- Integers only: `.` is always disabled; division truncates toward zero.
- BIN shown in groups of 4 bits.

## 2. History & Memory (screen 04)
- Tabs: **History | Memory**.
- History grouped by day (Today, Yesterday, date). Each entry: expression + result + mode.
- Tap entry → loads the expression into the calculator. Long-press → copy / delete.
- Search history (by number or text). "Copy all", "Clear history" (with confirm dialog).
- Stored on device; kept for the number of days set in Settings (default 30); max 500 entries.
- Memory: up to 10 slots (M1…). Each slot: MR (recall), M+ , M−. Keys MS/MC available via long-press on the memory chip.
- Converter and tool results can also be saved to history ("5 km → mi = 3.10686").

## 3. Settings (screen 05)
- Theme: Light / Dark / System. Accent colour: 4 swatches (cobalt default).
- Angle unit: Degrees / Radians.
- Decimal places: Auto (up to 10 significant decimals) or fixed 0–10.
- Thousands separator on/off. Decimal separator follows device locale (`.` or `,`).
- Vibrate on key press, Key sounds.
- Keep history for: 7 / 30 / 90 days / Forever.
- Clear all saved data (confirm dialog). Version number.

## 4. Converter (screens 06–07)
- Hub: search box (searches unit names and symbols across all categories) + Currency card + category grid.
- Categories and units (minimum set):
  - Length: mm, cm, m, km, in, ft, yd, mi, nmi
  - Area: mm², cm², m², hectare, km², in², ft², yd², acre, marla, kanal
  - Volume: mL, L, m³, tsp, tbsp, cup (US), fl oz (US), gal (US), gal (UK)
  - Mass: mg, g, kg, tonne, oz, lb, stone, tola, maund
  - Temperature: °C, °F, K
  - Speed: m/s, km/h, mph, knot
  - Time: ms, s, min, h, day, week, year (365 d)
  - Data: bit, byte, KB, MB, GB, TB (decimal) and KiB, MiB, GiB (binary)
  - Pressure: Pa, kPa, bar, psi, atm, mmHg
  - Energy: J, kJ, cal, kcal, Wh, kWh
  - Power: W, kW, hp
  - Angle: degree, radian, gradian
- Converter screen: From card (unit picker + value) / swap button / To card / conversion rule line
  ("1 km = 0.621371 mi") / "is also" list with 4 other common units / numeric keypad
  (`7 8 9 ⌫ / 4 5 6 C / 1 2 3 ± / 00 0 . Copy`).
- Conversion is live as you type. Last used category and unit pair are remembered. Star = favourite pair (shown at top of hub).

## 5. Currency (screen 08)
- Base currency + amount at top; list of target currencies below with value and rate line.
- Default base PKR; defaults list USD, EUR, GBP, AED, SAR. Add / remove / reorder currencies.
- Rates fetched from a free API, cached on device with timestamp. Offline → use cached rates and show "Rates from <date>".
- Status dot + line under the amount: Live / Cached (date) / No rates yet.
- Pull-to-refresh and refresh icon. Auto refresh at most once every 6 hours.

## 6. Tools (screens 09–10)
Every tool uses the Loan/EMI screen pattern: blue header with the main result, white sheet with labelled inputs,
a breakdown card, and one primary action. Results update live. Each tool has its own test file.
- **Loan / EMI**: amount, annual rate, tenure (years/months) → EMI, total interest, total payable, principal/interest bar, monthly schedule table.
- **Percentage**: X% of Y · X is what % of Y · % change from X to Y.
- **Discount and tax**: price, discount %, tax/GST % → you save, final price.
- **Tip and split**: bill, tip %, people → tip, total, per person (rounded up option).
- **Age**: date of birth, "on date" (default today) → years, months, days; total days; next birthday in N days.
- **Date difference**: two dates → days, weeks+days, months+days; option to include end date. Also add/subtract days from a date.
- **BMI**: height (cm or ft+in), weight (kg or lb) → BMI value + WHO category.
- **GPA / grades**: list of (course, credits, grade points) → weighted GPA; percentage → grade.
- **Equation solver**: linear `ax + b = 0`; quadratic `ax² + bx + c = 0` with real or complex roots and discriminant.
- **Statistics**: list of numbers → count, sum, mean, median, mode, min, max, range, population & sample SD.

## 7. Cross-cutting
- Haptic tick on key press (Settings). Optional key click sound.
- Accessibility: every key has a semantic label ("Divide", "Square root"); min tap target 44 px; supports text scale up to 1.3 without overflow.
- Copy/share result. Paste a number into display (validate it).
- No ads, no login, no analytics in v1.
