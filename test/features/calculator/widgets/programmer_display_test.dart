import 'package:calculator/core/engine/calc_result.dart';
import 'package:calculator/core/engine/formatter.dart';
import 'package:calculator/core/programmer/base_format.dart';
import 'package:calculator/core/programmer/word.dart';
import 'package:calculator/features/calculator/prog_state.dart';
import 'package:calculator/features/calculator/widgets/programmer_display.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:calculator/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(ProgrammerDisplay display, {double width = 390}) => MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      backgroundColor: AppColors.primary,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(width: width, child: display),
      ),
    ),
  );

  ProgrammerDisplay display(
    ProgState state, {
    ValueChanged<NumberBase>? onBaseSelected,
    VoidCallback? onWordSizeTap,
    NumberFormatOptions options = const NumberFormatOptions(),
  }) => ProgrammerDisplay(
    state: state,
    options: options,
    onBaseSelected: onBaseSelected ?? (NumberBase base) {},
    onWordSizeTap: onWordSizeTap ?? () {},
  );

  ProgState state({
    String source = '',
    Word? value,
    NumberBase base = NumberBase.dec,
    WordSize size = WordSize.standard,
    CalcError? error,
    bool justEvaluated = false,
  }) => ProgState(
    source: source,
    value: value ?? Word(BigInt.from(2021), size: size),
    base: base,
    size: size,
    error: error,
    justEvaluated: justEvaluated,
  );

  Text valueText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('programmer-value')));

  Text baseText(WidgetTester tester, NumberBase base) =>
      tester.widget<Text>(find.byKey(Key('base-value-${base.name}')));

  TextStyle baseStyle(WidgetTester tester, NumberBase base) =>
      tester.widget<Text>(find.byKey(Key('base-name-${base.name}'))).style!;

  Container rowBox(WidgetTester tester, NumberBase base) =>
      tester.widget<Container>(
        find.descendant(
          of: find.byKey(Key('base-${base.name}')),
          matching: find.byType(Container),
        ),
      );

  testWidgets('renders the chip, the big value and the four base rows', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(display(state(source: '2021'))));

    expect(
      tester.widget<Text>(find.text('32-bit')).style?.fontSize,
      AppTypography.small.fontSize,
    );
    expect(find.byKey(const Key('word-size-chip')), findsOneWidget);

    expect(valueText(tester).data, '2,021');
    expect(valueText(tester).textAlign, isNull);
    expect(valueText(tester).maxLines, 1);

    for (final NumberBase base in NumberBase.values) {
      expect(find.byKey(Key('base-${base.name}')), findsOneWidget);
    }
    expect(baseText(tester, NumberBase.hex).data, '7E5');
    expect(baseText(tester, NumberBase.dec).data, '2,021');
    expect(baseText(tester, NumberBase.oct).data, '3745');
    expect(baseText(tester, NumberBase.bin).data, '0111 1110 0101');

    // The typed expression sits above the chip (SPEC §1.1).
    expect(
      tester.widget<Text>(find.byKey(const Key('programmer-expression'))).data,
      '2021',
    );
  });

  testWidgets('the active base row is a white pill with primary text', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(display(state(base: NumberBase.hex))));

    final BoxDecoration selected =
        rowBox(tester, NumberBase.hex).decoration! as BoxDecoration;
    expect(selected.color, AppColors.sheet);
    expect(selected.borderRadius, BorderRadius.circular(AppRadii.chip));

    for (final NumberBase base in <NumberBase>[
      NumberBase.dec,
      NumberBase.oct,
      NumberBase.bin,
    ]) {
      final BoxDecoration inactive =
          rowBox(tester, base).decoration! as BoxDecoration;
      expect(inactive.color, Colors.transparent, reason: base.label);
    }

    expect(baseStyle(tester, NumberBase.hex).color, AppColors.primary);
    expect(
      baseStyle(tester, NumberBase.dec).color,
      AppColors.segmentedInactive,
    );
    expect(baseText(tester, NumberBase.hex).style?.color, AppColors.primary);
    expect(
      baseText(tester, NumberBase.dec).style?.color,
      AppColors.segmentedInactive,
    );

    // 6 px vertical, 12 px horizontal padding inside the row; the value is
    // right aligned because the row scrolls to keep its end in view.
    final Rect row = tester.getRect(find.byKey(const Key('base-hex')));
    final Rect name = tester.getRect(find.byKey(const Key('base-name-hex')));
    expect(name.left - row.left, AppSizes.baseRowPaddingH);
    expect(name.width, AppSizes.baseRowNameWidth);
  });

  testWidgets('tapping a row reports the base it stands for', (tester) async {
    final List<NumberBase> picked = <NumberBase>[];
    await tester.pumpWidget(wrap(display(state(), onBaseSelected: picked.add)));

    await tester.tap(find.byKey(const Key('base-oct')));
    await tester.tap(find.byKey(const Key('base-bin')));

    expect(picked, <NumberBase>[NumberBase.oct, NumberBase.bin]);
  });

  testWidgets('tapping the chip opens the word-size menu', (tester) async {
    int taps = 0;
    await tester.pumpWidget(
      wrap(display(state(), onWordSizeTap: () => taps++)),
    );

    await tester.tap(find.byKey(const Key('word-size-chip')));

    expect(taps, 1);
  });

  testWidgets('BIN shows the value smaller so the bit pattern fits', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(display(state(base: NumberBase.bin))));

    expect(valueText(tester).data, '0111 1110 0101');
    expect(valueText(tester).style?.fontSize, 28);
    expect(
      valueText(tester).style?.fontSize,
      AppTypography.programmerValueBinary.fontSize,
    );
  });

  testWidgets('other bases use the 44 px value style', (tester) async {
    await tester.pumpWidget(wrap(display(state())));

    expect(valueText(tester).style?.fontSize, 44);
    expect(
      valueText(tester).style?.fontSize,
      AppTypography.programmerValue.fontSize,
    );
  });

  testWidgets('a live preview is lighter, a committed result is white', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(display(state(source: '2021'))));
    expect(valueText(tester).style?.color, AppColors.onPrimaryMuted);

    await tester.pumpWidget(
      wrap(display(state(source: '2021', justEvaluated: true))),
    );
    expect(valueText(tester).style?.color, AppColors.onPrimary);
    expect(
      tester.widget<Text>(find.byKey(const Key('programmer-expression'))).data,
      '',
    );
  });

  testWidgets('an error takes over the big line in the warning colour', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(display(state(source: '5 ÷ 0', error: CalcError.divideByZero))),
    );

    expect(valueText(tester).data, CalcError.divideByZero.displayText);
    expect(valueText(tester).style?.color, AppColors.warning);
    expect(
      tester.widget<Text>(find.byKey(const Key('programmer-expression'))).data,
      '5 ÷ 0',
    );
  });

  testWidgets('the DEC row honours the Settings grouping switch', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        display(
          state(),
          options: const NumberFormatOptions(useGrouping: false),
        ),
      ),
    );

    expect(valueText(tester).data, '2021');
    expect(baseText(tester, NumberBase.dec).data, '2021');
  });

  testWidgets('sits on the blue area with the design side padding', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(display(state())));

    final Rect area = tester.getRect(
      find.byKey(const Key('programmer-display')),
    );
    final Rect chip = tester.getRect(find.byKey(const Key('word-size-chip')));

    expect(chip.left - area.left, AppSizes.programmerDisplaySide);
    expect(area.width, 390);
    expect(
      area.bottom - tester.getRect(find.byKey(const Key('base-bin'))).bottom,
      AppSizes.programmerDisplayBottom,
    );
  });
}
