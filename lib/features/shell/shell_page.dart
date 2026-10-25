import 'package:flutter/material.dart';

import '../../shared/widgets/bottom_nav.dart';
import '../../theme/app_tokens.dart';

/// The app shell: four tabs kept alive in an [IndexedStack] with the shared
/// bottom navigation (ARCHITECTURE "Navigation").
///
/// The calculator (T23), converter hub (T36), tools hub (T41) and history
/// (T29) replace the placeholders below.
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
                _CalculatorPlaceholder(),
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

/// Temporary blue-top calculator tab until T23 builds the real page.
class _CalculatorPlaceholder extends StatelessWidget {
  const _CalculatorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Calculator',
                style: AppTypography.hubTitle.copyWith(
                  color: AppColors.onPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.navItemGap * 2),
              Text(
                'Basic · Scientific · Programmer',
                style: AppTypography.small.copyWith(
                  color: AppColors.onPrimaryMuted,
                ),
              ),
            ],
          ),
        ),
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
