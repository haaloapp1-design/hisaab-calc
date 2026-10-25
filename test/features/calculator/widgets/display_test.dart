import 'package:calculator/core/engine/calc_result.dart';
import 'package:calculator/features/calculator/widgets/display.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:calculator/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Display display, {double width = 390}) => MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      backgroundColor: AppColors.primary,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(width: width, child: display),
      ),
    ),
  );

  Rect displayRect(WidgetTester tester) =>
      tester.getRect(find.byKey(const Key('display')));

  Rect dividerRect(WidgetTester tester) =>
      tester.getRect(find.byKey(const Key('display-divider')));

  TextStyle resultStyle(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('display-result'))).style!;

  testWidgets(
    'renders the expression, divider and result with design metrics',
    (tester) async {
      await tester.pumpWidget(
        wrap(const Display(expression: '1800 + 21 + 88', result: '1,909')),
      );

      final Text expression = tester.widget<Text>(
        find.byKey(const Key('display-expression')),
      );
      expect(expression.data, '1800 + 21 + 88');
      expect(expression.style?.fontSize, 20);
      expect(expression.style?.fontWeight, AppTypography.regular);
      expect(expression.style?.letterSpacing, 0.5);
      expect(expression.style?.color, AppColors.onPrimaryMuted);

      final Container divider = tester.widget<Container>(
        find.byKey(const Key('display-divider')),
      );
      expect(divider.color, AppColors.dividerOnPrimary);
      expect(dividerRect(tester).height, AppSizes.borderWidth);

      final Text result = tester.widget<Text>(
        find.byKey(const Key('display-result')),
      );
      expect(result.data, '1,909');
      expect(result.textAlign, TextAlign.right);
      expect(resultStyle(tester).fontSize, 60);
      expect(resultStyle(tester).fontWeight, AppTypography.medium);
      expect(resultStyle(tester).color, AppColors.onPrimary);

      // 24 px side padding, 22 px under the result, 10 px around the divider.
      final Rect display = displayRect(tester);
      expect(
        display.right -
            tester.getRect(find.byKey(const Key('display-result'))).right,
        AppSizes.displayPaddingSide,
      );
      expect(
        display.bottom -
            tester.getRect(find.byKey(const Key('display-result'))).bottom,
        AppSizes.displayPaddingBottom,
      );
      expect(
        dividerRect(tester).top -
            tester.getRect(find.byKey(const Key('display-expression'))).bottom,
        AppSizes.displayGap,
      );
      expect(
        tester.getRect(find.byKey(const Key('display-result'))).top -
            dividerRect(tester).bottom,
        AppSizes.displayGap,
      );
    },
  );

  testWidgets('the result auto-shrinks from 60 px down to 32 px', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const Display(result: '42')));
    expect(resultStyle(tester).fontSize, 60);

    await tester.pumpWidget(wrap(const Display(result: '1234567890')));
    expect(resultStyle(tester).fontSize, lessThan(60));
    expect(resultStyle(tester).fontSize, greaterThanOrEqualTo(32));

    await tester.pumpWidget(
      wrap(const Display(result: '123456789012345678901234567890')),
    );
    expect(resultStyle(tester).fontSize, 32);
  });

  testWidgets('a preview uses the lighter colour and the answer is white', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const Display(expression: '5 + 3', result: '8', preview: true)),
    );
    expect(resultStyle(tester).color, AppColors.onPrimaryMuted);

    await tester.pumpWidget(
      wrap(const Display(expression: '5 + 3', result: '8')),
    );
    expect(resultStyle(tester).color, AppColors.onPrimary);
  });

  testWidgets('an error replaces the result with its plain words', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const Display(
          expression: '5 ÷ 0',
          result: '5',
          error: CalcError.divideByZero,
        ),
      ),
    );

    expect(find.text("Can't divide by zero"), findsOneWidget);
    expect(find.text('5'), findsNothing);
    expect(resultStyle(tester).color, AppColors.warning);
    expect(resultStyle(tester).fontWeight, AppTypography.medium);
  });

  testWidgets('the memory chip shows only when memory is set', (tester) async {
    await tester.pumpWidget(
      wrap(const Display(expression: '2 + 3', result: '5', memory: '128')),
    );

    final Finder chip = find.byKey(const Key('display-memory'));
    expect(chip, findsOneWidget);
    expect(find.text('M = 128'), findsOneWidget);

    final Container box = tester.widget<Container>(chip);
    expect(
      box.padding,
      const EdgeInsets.symmetric(
        vertical: AppSizes.chipPaddingV,
        horizontal: AppSizes.chipPaddingH,
      ),
    );
    final BoxDecoration decoration = box.decoration! as BoxDecoration;
    expect(
      (decoration.border! as Border).top.color,
      AppColors.dividerOnPrimary,
    );
    expect(decoration.borderRadius, BorderRadius.circular(AppRadii.chip));
    expect(
      tester.widget<Text>(find.text('M = 128')).style?.color,
      AppColors.onPrimaryFaint,
    );
    expect(tester.widget<Text>(find.text('M = 128')).style?.fontSize, 13);

    await tester.pumpWidget(wrap(const Display(result: '0')));
    expect(find.byKey(const Key('display-memory')), findsNothing);
  });

  testWidgets('long-pressing the memory chip opens the menu callback', (
    tester,
  ) async {
    int opened = 0;
    await tester.pumpWidget(
      wrap(
        Display(result: '5', memory: '128', onMemoryLongPress: () => opened++),
      ),
    );

    await tester.longPress(find.byKey(const Key('display-memory')));
    await tester.pump();

    expect(opened, 1);
  });

  testWidgets('the expression scrolls and keeps its end in view', (
    tester,
  ) async {
    const String long =
        '1800 + 21 + 88 + 12 + 99 + 1 + 400 + 500 + 600 + 700 + 800 + 900';

    await tester.pumpWidget(
      wrap(const Display(expression: long, result: '1'), width: 300),
    );

    final SingleChildScrollView scroll = tester.widget<SingleChildScrollView>(
      find.byKey(const Key('display-expression-scroll')),
    );
    expect(scroll.scrollDirection, Axis.horizontal);
    expect(scroll.reverse, isTrue);

    ScrollableState scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const Key('display-expression-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    expect(scrollable.position.pixels, 0);

    // Dragging right reveals the start of the expression.
    await tester.drag(
      find.byKey(const Key('display-expression-scroll')),
      const Offset(120, 0),
    );
    await tester.pumpAndSettle();
    scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const Key('display-expression-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.pixels, greaterThan(0));

    // Typing more re-anchors the line to its end.
    await tester.pumpWidget(
      wrap(const Display(expression: '$long + 55', result: '1'), width: 300),
    );
    await tester.pump();
    await tester.pump();

    scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const Key('display-expression-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.pixels, 0);
  });

  testWidgets('empty expressions still occupy their line', (tester) async {
    await tester.pumpWidget(wrap(const Display(result: '0')));

    final Text expression = tester.widget<Text>(
      find.byKey(const Key('display-expression')),
    );
    expect(expression.data, '');
    expect(
      tester.getSize(find.byKey(const Key('display-expression'))).height,
      greaterThan(0),
    );
  });

  testWidgets('the scientific density uses 52/19 px and tighter spacing', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const Display(
          expression: 'sin(30) + √144',
          result: '48.5',
          density: DisplayDensity.scientific,
        ),
      ),
    );

    expect(resultStyle(tester).fontSize, 52);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('display-expression')))
          .style
          ?.fontSize,
      19,
    );

    expect(
      displayRect(tester).bottom -
          tester.getRect(find.byKey(const Key('display-result'))).bottom,
      AppSizes.displayScientificPaddingBottom,
    );

    expect(
      tester.getRect(find.byKey(const Key('display-result'))).top -
          dividerRect(tester).bottom,
      AppSizes.displayScientificGap,
    );
  });
}
