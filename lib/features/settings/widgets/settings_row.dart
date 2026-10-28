import 'package:flutter/material.dart';

import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// One line of a Settings card: a 15 px label on the left and an optional
/// control on the right, with the 10 px vertical padding of `05-settings.html`.
///
/// Rows whose whole line is the control (Angle unit, Keep history for) pass
/// [onTap]; the card owns the 1 px dividers between rows.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    this.trailing,
    this.onTap,
  });

  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.settingsRowPaddingV,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(color: palette.ink),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// The blue 15/500 value at the right of a row (design: "Degrees", "30 days").
class SettingsValue extends StatelessWidget {
  const SettingsValue(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      style: AppTypography.settingsValue.copyWith(
        color: AppPalette.of(context).primaryText,
      ),
    );
  }
}
