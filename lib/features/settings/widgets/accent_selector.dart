import 'package:flutter/material.dart';

import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';
import '../accent_colors.dart';
import '../settings_model.dart';

/// The four 28 px accent dots from the Settings design (screen 05).
///
/// The selected dot keeps its swatch colour, gets a 3 px white border and a
/// 2 px ring in the same colour (the design's CSS `outline`).
class AccentSelector extends StatelessWidget {
  const AccentSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AccentSwatch value;
  final ValueChanged<AccentSwatch> onChanged;

  static const Map<AccentSwatch, String> labels = <AccentSwatch, String>{
    AccentSwatch.cobalt: 'Cobalt',
    AccentSwatch.teal: 'Teal',
    AccentSwatch.violet: 'Violet',
    AccentSwatch.rust: 'Rust',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final AccentSwatch swatch in AccentSwatch.values) ...<Widget>[
          if (swatch != AccentSwatch.values.first)
            const SizedBox(width: AppSizes.accentDotGap),
          _AccentDot(
            key: Key('accent-${swatch.name}'),
            color: swatch.color,
            label: labels[swatch]!,
            selected: swatch == value,
            onTap: () => onChanged(swatch),
          ),
        ],
      ],
    );
  }
}

/// Maps a stored swatch choice to its design colour (see
/// `settings/accent_colors.dart`).
class _AccentDot extends StatelessWidget {
  const _AccentDot({
    super.key,
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: AppSizes.accentDot,
          height: AppSizes.accentDot,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: selected
                ? Border.all(
                    color: palette.onPrimary,
                    width: AppSizes.accentSelectedBorder,
                  )
                : null,
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: color,
                      blurRadius: 0,
                      spreadRadius: AppSizes.accentRing,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
