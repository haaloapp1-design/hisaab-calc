import 'package:flutter/material.dart';

import '../../shared/widgets/bottom_nav.dart';
import '../../theme/app_tokens.dart';
import '../calculator/calculator_page.dart';

/// The app shell: four tabs kept alive in an [IndexedStack] with the shared
/// bottom navigation (ARCHITECTURE "Navigation").
///
/// The converter hub (T36), tools hub (T41) and history (T29) replace the
/// placeholders below.
class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: <Widget>[
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: const <Widget>[
                CalculatorPage(),
                _HubPlaceholder(title: 'Convert'),
                _HubPlaceholder(title: 'Tools'),
                _HubPlaceholder(title: 'History'),
              ],
            ),
          ),
          ColoredBox(
            color: AppColors.sheet,
            child: SafeArea(
              top: false,
              child: BottomNav(
                currentIndex: _currentIndex,
                onSelected: (int index) =>
                    setState(() => _currentIndex = index),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Temporary hub/history tab until the real pages land.
class _HubPlaceholder extends StatelessWidget {
  const _HubPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: Text(
            title,
            style: AppTypography.hubTitle.copyWith(color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}
