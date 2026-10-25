import 'package:calculator/shared/widgets/white_sheet.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:calculator/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(theme: AppTheme.light(), home: Scaffold(body: child));

  Container sheetBox(WidgetTester tester) =>
      tester.widget<Container>(find.byKey(const Key('white-sheet')));

  testWidgets('renders the design surface, padding and handle', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const WhiteSheet(
          child: SizedBox(height: 100, child: Text('keys')),
        ),
      ),
    );

    final Container sheet = sheetBox(tester);
    final BoxDecoration decoration = sheet.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.sheet);
    expect(
      decoration.borderRadius,
      const BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
    );
    expect(
      sheet.padding,
      const EdgeInsets.fromLTRB(
        AppSizes.sheetPaddingSide,
        AppSizes.sheetPaddingTop,
        AppSizes.sheetPaddingSide,
        AppSizes.sheetPaddingBottom,
      ),
    );
    expect(tester.getSize(find.byKey(const Key('white-sheet'))).width, 800);

    expect(find.text('keys'), findsOneWidget);

    final Container handle = tester.widget<Container>(
      find.byKey(const Key('white-sheet-handle')),
    );
    expect(
      tester.getSize(find.byKey(const Key('white-sheet-handle'))),
      Size(AppSizes.handleWidth, AppSizes.handleHeight),
    );
    expect((handle.decoration! as BoxDecoration).color, AppColors.primary);
    expect(
      tester.getCenter(find.byKey(const Key('white-sheet-handle'))).dx,
      400,
    );
  });

  testWidgets('the handle is optional and the gap disappears with it', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const WhiteSheet(
          showHandle: false,
          child: SizedBox(height: 20, child: Text('content')),
        ),
      ),
    );

    expect(find.byKey(const Key('white-sheet-handle')), findsNothing);
    expect(find.text('content'), findsOneWidget);

    // 20 (top) + 20 (child) + 14 (bottom), no handle or gap.
    expect(
      tester.getSize(find.byKey(const Key('white-sheet'))).height,
      AppSizes.sheetPaddingTop +
          AppSizes.sheetPaddingBottom +
          20,
    );
  });

  testWidgets('a custom padding replaces the default one', (tester) async {
    await tester.pumpWidget(
      wrap(
        const WhiteSheet(
          padding: EdgeInsets.all(8),
          child: SizedBox(height: 10, child: Text('custom')),
        ),
      ),
    );

    expect(sheetBox(tester).padding, const EdgeInsets.all(8));
  });
}
