# DESIGN — tokens and components

Source of truth: the "Advanced Calculator — App Screens" canvas (10 screens, 390×844).
Put every value below in `lib/theme/app_tokens.dart`.

## Colours (light theme)

| Token | Hex | Use |
|---|---|---|
| `primary` (cobalt) | `#2D46B9` | top area background, `=` key, active states, accents |
| `primaryDeep` | `#1F3391` | pressed state of primary |
| `primaryTrack` | `#3E58C8` | segmented control track, cards on blue |
| `onPrimary` | `#FFFFFF` | main text on blue |
| `onPrimaryMuted` | `#DDE3FF` | expression line, secondary text on blue |
| `dividerOnPrimary` | `#5A72D6` | rule under expression, chip borders on blue |
| `sheet` | `#FFFFFF` | bottom sheet, cards |
| `background` | `#F4F6FD` | pages without blue top (Settings, Convert hub, Tools) |
| `keyNumber` | `#F6F7FD` (border `#E4E8F7`) | number keys |
| `keyFunction` | `#EEF1FB` | scientific/function keys (text `primary`) |
| `keyOperator` | `#E6EBFC` (border `#D6DDF8`) | `+ − × ÷` keys, active nav pill |
| `ink` | `#18224F` | main text on white |
| `inkMuted` | `#5A6487` | labels, inactive nav |
| `disabled` | `#A3ABC7` (dashed border `#DCE1F2`) | disabled keys |
| `warning` | `#F5B971` | interest bar, "cached rates" dot |
| `danger` | `#B4410E` on `#FFF4EE` | destructive buttons |

Accent swatches (Settings): cobalt `#2D46B9`, teal `#0F766E`, violet `#7C3AED`, rust `#C2410C`.
Changing accent replaces `primary`; derive `primaryTrack`/`keyOperator` by mixing with white.

Dark theme (to design in T-later): background `#10142B`, sheet `#181D3A`, keys `#222849`, ink `#E8EBFA`, primary stays the accent.

## Type
Font: **Ubuntu** (400, 500, 700). Fallback: system sans.

| Role | Size / weight |
|---|---|
| Result (Basic) | 60 / 500 (auto-shrink to 32) |
| Result (Scientific, converter) | 52 / 500, converter values 38 / 500 |
| Expression line | 19–20 / 400, `onPrimaryMuted` |
| Number key | 26 (basic) / 22 (scientific) / 400 |
| Function key | 16 / 500 |
| Screen title | 17 / 500 ; hub titles 26 / 500 |
| Body / list | 15 / 400 ; small 13 ; nav label 12 |

## Shape and spacing
- Bottom sheet: top radius 32, handle 44×4 radius 2 in `primary`, padding 12/20/14.
- Keys: radius 18 (basic, 60 high), 14 (scientific/programmer, 46 high), 16 (converter, 52 high). Grid gap 12 / 8 / 10.
- Segmented control: track radius 14, pill radius 10, height 44.
- Cards: radius 18–20, 1 px border `#E4E8F7`, no shadows.
- Screen side padding 20–24. Min touch target 44×44.

## Components
- `BlueHeader` (back button · title · action icon), `ModeSwitcher`, `Display`, `Keypad(grid spec)`, `CalcKeyButton(kind)`,
  `WhiteSheet(handle: true)`, `BottomNav(4 items, active pill)`, `UnitCard`, `SwapButton` (48 circle with 4 px primary ring),
  `ToolScaffold` (header result + sheet of inputs + breakdown card + primary button), `SettingsRow`, `ToggleSwitch`.
- Key press feedback: scale 0.96 for 80 ms + background darken 6 %; haptic `selectionClick` if enabled.
