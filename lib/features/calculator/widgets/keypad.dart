import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'calc_key_button.dart';

/// One cell of a [Keypad] spec: the visible [label], its [kind] and what a tap
/// does. Keys that need an action outside the calculator buffer (2nd, DEG/RAD,
/// base switches) simply pass their own [onTap].
final class KeypadEntry {
  const KeypadEntry({
    required this.label,
    this.kind = CalcKeyKind.number,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
  });

  final String label;
  final CalcKeyKind kind;
  final VoidCallback? onTap;

  /// Secondary action such as long-pressing `⌫` to clear (SPEC §1.2).
  final VoidCallback? onLongPress;

  /// Screen-reader label when the visible glyph is not a word ("÷" → "Divide").
  final String? semanticLabel;
}

/// A fixed-column keypad grid built from [spec] (DESIGN "Components").
///
/// Keys share the width evenly and sit on the density's gap. A short last row
/// keeps its column widths by padding the row with invisible cells, so a 4×5
/// Basic spec and an incomplete converter grid both line up.
class Keypad extends StatelessWidget {
  const Keypad({
    super.key,
    required this.spec,
    required this.columns,
    this.density = CalcKeyDensity.basic,
    this.haptics = true,
  }) : assert(columns > 0, 'a keypad needs at least one column');

  final List<KeypadEntry> spec;
  final int columns;
  final CalcKeyDensity density;

  /// SPEC §7 haptic tick; T25/T27 pass the user's setting.
  final bool haptics;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int start = 0; start < spec.length; start += columns) {
      if (start > 0) {
        rows.add(SizedBox(height: density.keyGap));
      }
      rows.add(_row(start));
    }

    return Column(
      key: const Key('keypad'),
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }

  Widget _row(int start) {
    final int end = math.min(start + columns, spec.length);
    final List<Widget> cells = <Widget>[];

    for (int index = start; index < end; index++) {
      if (index > start) {
        cells.add(SizedBox(width: density.keyGap));
      }
      final KeypadEntry entry = spec[index];
      cells.add(
        Expanded(
          child: CalcKeyButton(
            label: entry.label,
            kind: entry.kind,
            onTap: entry.onTap,
            onLongPress: entry.onLongPress,
            semanticLabel: entry.semanticLabel,
            density: density,
            haptics: haptics,
          ),
        ),
      );
    }

    // Fill the rest of a short row so its keys keep the shared column width.
    for (int index = end; index < start + columns; index++) {
      cells.add(SizedBox(width: density.keyGap));
      cells.add(const Expanded(child: SizedBox.shrink()));
    }

    return Row(children: cells);
  }
}
