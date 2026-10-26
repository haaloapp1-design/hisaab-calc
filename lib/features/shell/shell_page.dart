import 'package:flutter/material.dart';

import '../../shared/widgets/bottom_nav.dart';
import '../../theme/app_palette.dart';
import '../calculator/calculator_page.dart';
import '../converter/converter_hub_page.dart';
import '../history/history_page.dart';
import '../tools/tools_hub_page.dart';

/// The app shell: four tabs kept alive in an [IndexedStack] with the shared
/// bottom navigation (ARCHITECTURE "Navigation").
///
/// The converter hub (T36) and the tools hub (T41) are live; history is the
/// remaining tab.
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
                const ToolsHubPage(),
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
