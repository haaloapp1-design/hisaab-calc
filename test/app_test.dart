import 'package:calculator/app.dart';
import 'package:calculator/features/shell/shell_page.dart';
import 'package:calculator/shared/widgets/bottom_nav.dart';
import 'package:calculator/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots inside a ProviderScope', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CalculatorApp()));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(ShellPage), findsOneWidget);
  });

  testWidgets('app shows the shell, its theme and the four nav items', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: CalculatorApp()));

    final MaterialApp app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.colorScheme.primary, AppColors.primary);

    final Scaffold scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.background);

    expect(find.byType(BottomNav), findsOneWidget);
    for (final String label in <String>[
      'Calculator',
      'Convert',
      'Tools',
      'History',
    ]) {
      expect(
        find.descendant(
          of: find.byType(BottomNav),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
  });
}
