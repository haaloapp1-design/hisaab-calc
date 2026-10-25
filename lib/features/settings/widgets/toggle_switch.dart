import 'package:flutter/material.dart';

import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// The 50×30 Settings switch from `05-settings.html`: a white 24 px knob on a
/// `primary` track when on and on `switchOff` when off.
///
/// It is a pure view; the caller owns the stored value.
class ToggleSwitch extends StatelessWidget {
  const ToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  /// Screen-reader name of the setting this switch controls.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Semantics(
      toggled: value,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: AppMotion.toggle,
          width: AppSizes.switchWidth,
          height: AppSizes.switchHeight,
          padding: const EdgeInsets.all(AppSizes.switchPadding),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: value ? palette.primary : palette.switchOff,
            borderRadius: BorderRadius.circular(AppSizes.switchHeight / 2),
          ),
          child: Container(
            key: const Key('toggle-knob'),
            width: AppSizes.switchKnob,
            height: AppSizes.switchKnob,
            decoration: BoxDecoration(
              color: palette.onPrimary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
