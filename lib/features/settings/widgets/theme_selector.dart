import 'package:flutter/material.dart';

import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';
import '../settings_model.dart';

/// The Light / Dark / System pills from the Theme row (screen 05).
///
/// The selected pill is white with 13/700 `primary` text; the others are
/// transparent with 13/400 `inkMuted` text, all on the 10 px-radius track.
class ThemeSelector extends StatelessWidget {
  const ThemeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AppThemeMode value;
  final ValueChanged<AppThemeMode> onChanged;

  static const Map<AppThemeMode, String> labels = <AppThemeMode, String>{
    AppThemeMode.light: 'Light',
    AppThemeMode.dark: 'Dark',
    AppThemeMode.system: 'System',
  };

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSizes.settingsTrackPadding),
      decoration: BoxDecoration(
        color: palette.selectorTrack,
        borderRadius: BorderRadius.circular(AppRadii.settingsTrack),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final AppThemeMode mode in AppThemeMode.values) ...<Widget>[
            if (mode != AppThemeMode.values.first)
              const SizedBox(width: AppSizes.settingsPillGap),
            _ThemePill(
              key: Key('theme-${mode.name}'),
              label: labels[mode]!,
              selected: mode == value,
              onTap: () => onChanged(mode),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThemePill extends StatelessWidget {
  const _ThemePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: '$label theme',
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.settingsPillPaddingV,
            horizontal: AppSizes.settingsPillPaddingH,
          ),
          decoration: BoxDecoration(
            color: selected ? palette.onPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.settingsPill),
          ),
          child: Text(
            label,
            maxLines: 1,
            style: AppTypography.settingsPill.copyWith(
              color: selected ? palette.primary : palette.inkMuted,
              fontWeight: selected ? AppTypography.bold : AppTypography.regular,
            ),
          ),
        ),
      ),
    );
  }
}
