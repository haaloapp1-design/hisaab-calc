import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/engine/angle_mode.dart';
import '../../shared/widgets/blue_header.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_tokens.dart';
import '../calculator/calculator_controller.dart';
import 'settings_controller.dart';
import 'settings_model.dart';
import 'widgets/accent_selector.dart';
import 'widgets/clear_data_button.dart';
import 'widgets/decimal_stepper.dart';
import 'widgets/settings_row.dart';
import 'widgets/settings_section.dart';
import 'widgets/theme_selector.dart';
import 'widgets/toggle_switch.dart';

/// The Settings screen (SPEC §3, `05-settings.html`).
///
/// It only renders [settingsProvider] and forwards every change to
/// [SettingsController]; the values are applied to the app later (T27). The
/// rows, pills, dots, switches and paddings follow the screen exactly.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  /// Shown at the bottom of the screen. The app has no `package_info` package,
  /// so this constant is kept in step with `pubspec.yaml` by hand.
  static const String version = '1.0.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final Settings settings = ref.watch(settingsProvider);
    final SettingsController controller = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            BlueHeader(
              title: 'Settings',
              rounded: true,
              bottomPadding: AppSizes.headerSettingsPaddingBottom,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: SafeArea(
                top: false,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.screenPadding,
                    AppSizes.settingsPaddingTop,
                    AppSizes.screenPadding,
                    AppSizes.settingsPaddingTop,
                  ),
                  children: <Widget>[
                    SettingsSection(
                      title: 'Appearance',
                      children: <Widget>[
                        SettingsRow(
                          label: 'Theme',
                          trailing: ThemeSelector(
                            value: settings.themeMode,
                            onChanged: controller.setThemeMode,
                          ),
                        ),
                        SettingsRow(
                          label: 'Accent colour',
                          trailing: AccentSelector(
                            value: settings.accent,
                            onChanged: controller.setAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.settingsSectionGap),
                    SettingsSection(
                      title: 'Calculation',
                      children: <Widget>[
                        SettingsRow(
                          label: 'Angle unit',
                          onTap: () => controller.setAngleMode(
                            settings.angleMode.isDegrees
                                ? AngleMode.rad
                                : AngleMode.deg,
                          ),
                          trailing: SettingsValue(
                            angleLabel(settings.angleMode),
                          ),
                        ),
                        SettingsRow(
                          label: 'Decimal places',
                          trailing: DecimalStepper(
                            value: settings.decimalPlaces,
                            onChanged: controller.setDecimalPlaces,
                          ),
                        ),
                        SettingsRow(
                          label: 'Thousands separator',
                          trailing: ToggleSwitch(
                            key: const Key('switch-thousands'),
                            value: settings.thousandsSeparator,
                            onChanged: controller.setThousandsSeparator,
                            semanticLabel: 'Thousands separator',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.settingsSectionGap),
                    SettingsSection(
                      title: 'Feel',
                      children: <Widget>[
                        SettingsRow(
                          label: 'Vibrate on key press',
                          trailing: ToggleSwitch(
                            key: const Key('switch-haptics'),
                            value: settings.haptics,
                            onChanged: controller.setHaptics,
                            semanticLabel: 'Vibrate on key press',
                          ),
                        ),
                        SettingsRow(
                          label: 'Key sounds',
                          trailing: ToggleSwitch(
                            key: const Key('switch-sounds'),
                            value: settings.keySounds,
                            onChanged: controller.setKeySounds,
                            semanticLabel: 'Key sounds',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.settingsSectionGap),
                    SettingsSection(
                      title: 'Data',
                      children: <Widget>[
                        SettingsRow(
                          label: 'Keep history for',
                          onTap: () => controller.setHistoryRetention(
                            _nextRetention(settings.historyRetention),
                          ),
                          trailing: SettingsValue(
                            retentionLabel(settings.historyRetention),
                          ),
                        ),
                        SettingsRow(
                          label: 'Clear all saved data',
                          trailing: ClearDataButton(
                            onTap: () => _confirmClear(context, ref),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.settingsSectionGap),
                    Text(
                      'Version $version',
                      textAlign: TextAlign.center,
                      style: AppTypography.small.copyWith(
                        color: palette.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// SPEC §3 angle row text.
  static String angleLabel(AngleMode mode) =>
      mode.isDegrees ? 'Degrees' : 'Radians';

  /// SPEC §3 retention row text.
  static String retentionLabel(HistoryRetention retention) =>
      switch (retention) {
        HistoryRetention.days7 => '7 days',
        HistoryRetention.days30 => '30 days',
        HistoryRetention.days90 => '90 days',
        HistoryRetention.forever => 'Forever',
      };

  /// Tapping the row walks the four choices and wraps around.
  static HistoryRetention _nextRetention(HistoryRetention current) {
    final List<HistoryRetention> values = HistoryRetention.values;
    return values[(current.index + 1) % values.length];
  }

  /// SPEC §3 "Clear all saved data (confirm dialog)".
  ///
  /// The settings and calculator controllers own their own keys; later
  /// features (history, memory, currency) add their clears here too.
  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final SettingsController settings = ref.read(settingsProvider.notifier);
    final CalculatorController calculator = ref.read(
      calculatorProvider.notifier,
    );

    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            key: const Key('clear-dialog'),
            title: const Text('Clear all saved data?'),
            content: const Text(
              'This removes your settings, history and saved answers from '
              'this device. It cannot be undone.',
            ),
            actions: <Widget>[
              TextButton(
                key: const Key('clear-cancel'),
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                key: const Key('clear-confirm'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  'Clear',
                  style: AppTypography.body.copyWith(
                    color: AppPalette.of(context).danger,
                    fontWeight: AppTypography.medium,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }

    await settings.clearSavedData();
    await calculator.clearSavedData();
  }
}
