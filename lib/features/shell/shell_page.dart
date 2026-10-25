import 'package:flutter/material.dart';

import '../../shared/widgets/blue_header.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/segmented.dart';
import '../../shared/widgets/white_sheet.dart';
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

/// Temporary calculator tab until T23 builds the real page.
///
/// It is the first user of the shared [BlueHeader], [Segmented] and
/// [WhiteSheet], so T20's widgets are exercised on a real screen.
class _CalculatorPlaceholder extends StatefulWidget {
  const _CalculatorPlaceholder();

  @override
  State<_CalculatorPlaceholder> createState() => _CalculatorPlaceholderState();
}

class _CalculatorPlaceholderState extends State<_CalculatorPlaceholder> {
  static const List<String> _modes = <String>[
    'Basic',
    'Scientific',
    'Programmer',
  ];

  int _mode = 0;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            BlueHeader(
              title: 'Calculator',
              actionIcon: Icons.tune_rounded,
              actionTooltip: 'Settings',
              onAction: () {},
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                AppSizes.segmentedTopGap,
                AppSizes.screenPadding,
                0,
              ),
              child: Segmented(
                labels: _modes,
                selectedIndex: _mode,
                onSelected: (int index) => setState(() => _mode = index),
              ),
            ),
            const Spacer(),
            WhiteSheet(
              child: SizedBox(
                height: AppSizes.keyHeightBasic * 2,
                child: Center(
                  child: Text(
                    '${_modes[_mode]} mode',
                    style: AppTypography.body.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],
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
