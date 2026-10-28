import 'package:flutter/material.dart';

import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';
import '../../settings/widgets/toggle_switch.dart';

/// A titled switch inside a tool's bordered card.
///
/// The tip page's round-up option and the date difference page's include-end
/// option share this look: a 15 px title, a 12 px muted line and the Settings
/// [ToggleSwitch]. The page owns the value.
class ToolToggleRow extends StatelessWidget {
  const ToolToggleRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.switchKey,
    required this.semanticLabel,
  });

  /// The bold line, e.g. `Round up per person`.
  final String title;

  /// The muted explanation under it.
  final String subtitle;

  final bool value;
  final ValueChanged<bool> onChanged;

  /// The key on the switch, used by the tests.
  final Key switchKey;

  /// The screen-reader name of the switch.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSizes.toolBreakdownPadding),
      decoration: BoxDecoration(
        border: Border.all(
          color: palette.keyNumberBorder,
          width: AppSizes.borderWidth,
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.toolBreakdownTotal.copyWith(
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: AppSizes.toolScheduleTitleGap),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.toolSubtitle.copyWith(
                    color: palette.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          ToggleSwitch(
            key: switchKey,
            value: value,
            onChanged: onChanged,
            semanticLabel: semanticLabel,
          ),
        ],
      ),
    );
  }
}
