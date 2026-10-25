import 'package:calculator/app.dart';
import 'package:calculator/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots inside a ProviderScope', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CalculatorApp()));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('app renders the blue top and the white sheet from tokens', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: CalculatorApp()));

    final MaterialApp app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.colorScheme.primary, AppColors.primary);

    final Scaffold scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.primary);

    final Container sheet = tester.widget<Container>(
      find.byKey(const Key('theme-probe-sheet')),
    );
    expect((sheet.decoration! as BoxDecoration).color, AppColors.sheet);

    expect(find.text('Calculator'), findsOneWidget);
  });
}
