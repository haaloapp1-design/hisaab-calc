/// Angle unit used by the trigonometric functions (BUSINESS_LOGIC §6).
///
/// DEG is the app default (SPEC §1.3). The settings screen stores the user's
/// choice later; the engine only needs the value.
enum AngleMode {
  deg,
  rad;

  /// True when the mode needs the `× π / 180` conversion.
  bool get isDegrees => this == AngleMode.deg;
}
