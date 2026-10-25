# Screens — the design reference

Each `.html` file is the exact design of one screen (390×844 phone).
Read the inline `style="…"` values for exact colours, sizes, radii, gaps and font sizes.
The `<script>` block at the bottom holds the sample data and key layouts (e.g. the `spec` arrays = keypad order).
Ignore the design-tool parts (`support.js`, `x-dc`, `sc-for`, `sc-if`, `{{…}}`, `DCLogic`): they are NOT Flutter code.
Rebuild the look in Flutter widgets using the tokens in `lib/theme/app_tokens.dart`.

Optional: `png/` holds screenshots of the same screens (for humans and vision models).

| File | Screen |
|---|---|
| 01-basic.html | Basic mode |
| 02-scientific.html | Scientific mode |
| 03-programmer.html | Programmer mode |
| 04-history-memory.html | History & Memory |
| 05-settings.html | Settings |
| 06-converter-hub.html | Converter hub |
| 07-unit-converter.html | Unit converter (Length example) |
| 08-currency.html | Currency |
| 09-tools-hub.html | Tools hub |
| 10-loan-emi.html | Loan / EMI (template for all tools) |
