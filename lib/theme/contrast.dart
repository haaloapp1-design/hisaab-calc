import 'package:flutter/material.dart';

/// WCAG 2.1 contrast helpers, shared by the theme and the accessibility tests.
///
/// `Color.computeLuminance()` is already the WCAG relative luminance, so the
/// ratio is the two luminances with the standard +0.05 offset. T48 uses this to
/// keep every text/surface pair of the palette at AA.
abstract final class Contrast {
  /// AA for normal text: 4.5:1.
  static const double normalText = 4.5;

  /// AA for large text (>= 24 px, or >= 18.66 px bold) and for graphical
  /// objects such as icons, status dots and control boundaries: 3:1.
  static const double largeText = 3;

  /// The contrast ratio between [a] and [b], from 1 (identical) to 21
  /// (black on white).
  static double ratio(Color a, Color b) {
    final double la = a.computeLuminance();
    final double lb = b.computeLuminance();
    final double high = la > lb ? la : lb;
    final double low = la > lb ? lb : la;
    return (high + 0.05) / (low + 0.05);
  }
}
