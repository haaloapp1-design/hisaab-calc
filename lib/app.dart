import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/settings/accent_colors.dart';
import 'features/settings/settings_controller.dart';
import 'features/settings/settings_model.dart';
import 'features/shell/shell_page.dart';
import 'theme/app_theme.dart';

/// Root widget: the four-tab shell inside the settings-driven theme.
///
/// It watches `settingsProvider`, so changing the theme mode or accent in
/// Settings rebuilds [MaterialApp] with the new [AppTheme] immediately.
class CalculatorApp extends ConsumerWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Settings settings = ref.watch(settingsProvider);
    final Color accent = settings.accent.color;

    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(accent: accent),
      darkTheme: AppTheme.dark(accent: accent),
      themeMode: _themeMode(settings.themeMode),
      home: const ShellPage(),
    );
  }

  static ThemeMode _themeMode(AppThemeMode mode) => switch (mode) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.system => ThemeMode.system,
  };
}
