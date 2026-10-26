import 'package:flutter/material.dart';

import '../../shared/widgets/bottom_nav.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_tokens.dart';
import '../calculator/calculator_page.dart';
import '../converter/converter_hub_page.dart';
import '../history/history_page.dart';

/// The app shell: four tabs kept alive in an [IndexedStack] with the shared
/// bottom navigation (ARCHITECTURE "Navigation").
///
/// The converter hub (T36) is live; the tools hub (T41) replaces the
/// placeholder below.
class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: Column(
        children: <Widget>[
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: <Widget>[
                const CalculatorPage(),
                const ConverterHubPage(),
                const _HubPlaceholder(title: 'Tools'),
                HistoryPage(
                  onOpenCalculator: () => setState(() => _currentIndex = 0),
                ),
              ],
            ),
          ),
          ColoredBox(
            color: palette.sheet,
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
    final AppPalette palette = AppPalette.of(context);

    return ColoredBox(
      color: palette.background,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: Text(
            title,
            style: AppTypography.hubTitle.copyWith(color: palette.ink),
          ),
        ),
      ),
    );
  }
}
