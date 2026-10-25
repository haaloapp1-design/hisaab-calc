import 'package:calculator/app.dart';
import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/features/shell/shell_page.dart';
import 'package:calculator/shared/widgets/bottom_nav.dart';
import 'package:calculator/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app() => ProviderScope(
    overrides: [kvStoreProvider.overrideWithValue(MemoryKvStore())],
    child: const CalculatorApp(),
  );

  /// The calculator page needs the 390×844 design height.
  void designSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('app boots inside a ProviderScope', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(ShellPage), findsOneWidget);
  });

  testWidgets('app shows the shell, its theme and the four nav items', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(app());

    final MaterialApp materialApp = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(materialApp.theme?.colorScheme.primary, AppColors.primary);

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
        find.descendant(of: find.byType(BottomNav), matching: find.text(label)),
        findsOneWidget,
      );
    }
  });
}
