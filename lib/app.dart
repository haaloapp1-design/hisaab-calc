import 'package:flutter/material.dart';

import 'features/shell/shell_page.dart';
import 'theme/app_theme.dart';

/// Root widget: the four-tab shell inside the app theme.
class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const ShellPage(),
    );
  }
}
