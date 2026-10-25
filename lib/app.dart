import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'theme/app_tokens.dart';

/// Root widget. The tab shell (T19) and calculator (T23) replace the temporary
/// home below.
class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const _ThemeProbePage(),
    );
  }
}

/// Temporary screen: proves the theme renders the blue top area and the white
/// sheet from the design tokens.
class _ThemeProbePage extends StatelessWidget {
  const _ThemeProbePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Expanded(
              child: Center(
                child: Text(
                  'Calculator',
                  style: AppTypography.hubTitle.copyWith(
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
            Container(
              key: const Key('theme-probe-sheet'),
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppSizes.sheetPaddingSide,
                AppSizes.sheetPaddingTop,
                AppSizes.sheetPaddingSide,
                AppSizes.sheetPaddingBottom,
              ),
              decoration: const BoxDecoration(
                color: AppColors.sheet,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadii.sheet),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: AppSizes.handleWidth,
                    height: AppSizes.handleHeight,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppRadii.handle),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.sheetPaddingTop),
                  Text(
                    'Theme ready',
                    style: AppTypography.body.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
