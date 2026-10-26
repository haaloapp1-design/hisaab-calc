import 'package:calculator/features/tools/tool_scaffold.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:calculator/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(theme: AppTheme.light(), home: child);

  /// The screens in `docs/screens/` are 390×844.
  void designSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('lays out the header, result, sheet and action of screen 10', (
    tester,
  ) async {
    designSurface(tester);
    int shares = 0;
    int actions = 0;

    await tester.pumpWidget(
      wrap(
        ToolScaffold(
          title: 'Loan / EMI',
          resultLabel: 'Monthly instalment',
          resultValue: '22,244.45',
          resultCaption: 'PKR for 60 months',
          onShare: () => shares++,
          actionLabel: 'Show monthly schedule',
          onAction: () => actions++,
          children: const <Widget>[Text('Loan amount (PKR)')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Loan / EMI'), findsOneWidget);
    expect(find.text('Monthly instalment'), findsOneWidget);
    expect(find.text('PKR for 60 months'), findsOneWidget);
    expect(find.text('Loan amount (PKR)'), findsOneWidget);

    final Text value = tester.widget<Text>(
      find.byKey(const Key('tool-result-value')),
    );
    expect(value.style?.fontSize, 48);
    expect(value.style?.fontWeight, AppTypography.medium);
    expect(value.style?.color, AppColors.onPrimary);

    final Text label = tester.widget<Text>(find.text('Monthly instalment'));
    expect(label.style?.fontSize, 14);
    expect(label.style?.color, AppColors.onPrimaryMuted);

    expect(
      tester.widget<Padding>(find.byKey(const Key('tool-result'))).padding,
      const EdgeInsets.fromLTRB(
        AppSizes.toolResultPaddingSide,
        AppSizes.toolResultPaddingTop,
        AppSizes.toolResultPaddingSide,
        AppSizes.toolResultPaddingBottom,
      ),
    );

    final Container sheet = tester.widget<Container>(
      find.byKey(const Key('tool-sheet')),
    );
    final BoxDecoration decoration = sheet.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.sheet);
    expect(
      decoration.borderRadius,
      const BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
    );
    expect(
      sheet.padding,
      const EdgeInsets.fromLTRB(
        AppSizes.toolSheetPaddingSide,
        AppSizes.toolSheetPaddingTop,
        AppSizes.toolSheetPaddingSide,
        AppSizes.toolSheetPaddingBottom,
      ),
    );
    expect(
      tester.getSize(find.byKey(const Key('tool-sheet-handle'))),
      const Size(AppSizes.handleWidth, AppSizes.handleHeight),
    );

    expect(
      tester.getSize(find.byKey(const Key('tool-action'))).height,
      AppSizes.toolActionHeight,
    );
    final Text action = tester.widget<Text>(find.text('Show monthly schedule'));
    expect(action.style?.fontSize, 16);
    expect(action.style?.fontWeight, AppTypography.medium);
    expect(action.style?.color, AppColors.onPrimary);

    await tester.tap(find.byTooltip('Share result'));
    await tester.tap(find.byKey(const Key('tool-action')));

    expect(shares, 1);
    expect(actions, 1);
  });

  testWidgets('hides the share action and the primary action when unset', (
    tester,
  ) async {
    designSurface(tester);
    await tester.pumpWidget(
      wrap(
        const ToolScaffold(
          title: 'BMI',
          resultLabel: 'Body mass index',
          resultValue: '—',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Share result'), findsNothing);
    expect(find.byKey(const Key('tool-action')), findsNothing);
    expect(find.byKey(const Key('blue-header-back')), findsOneWidget);
    expect(find.text('Body mass index'), findsOneWidget);
  });

  testWidgets('the back button pops the tool page', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const ToolScaffold(
                  title: 'Age',
                  resultLabel: 'Years, months, days',
                  resultValue: '—',
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Age'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Age'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });
}
