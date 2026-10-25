import 'package:calculator/features/calculator/widgets/calc_key_button.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:calculator/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: Center(child: SizedBox(width: 90, child: child)),
    ),
  );

  BoxDecoration decorationOf(WidgetTester tester) =>
      tester
              .widget<AnimatedContainer>(find.byType(AnimatedContainer))
              .decoration!
          as BoxDecoration;

  TextStyle styleOf(WidgetTester tester, String label) =>
      tester.widget<Text>(find.text(label)).style!;

  testWidgets('a basic number key uses the design colour, radius and type', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(CalcKeyButton(label: '7', kind: CalcKeyKind.number, onTap: () {})),
    );

    final BoxDecoration decoration = decorationOf(tester);
    expect(decoration.color, AppColors.keyNumber);
    expect((decoration.border! as Border).top.color, AppColors.keyNumberBorder);
    expect((decoration.border! as Border).top.width, AppSizes.borderWidth);
    expect(decoration.borderRadius, BorderRadius.circular(AppRadii.keyBasic));

    expect(tester.getSize(find.byType(AnimatedContainer)).height, 60);

    final TextStyle style = styleOf(tester, '7');
    expect(style.fontSize, 26);
    expect(style.fontWeight, AppTypography.regular);
    expect(style.color, AppColors.ink);
  });

  testWidgets('function, operator and equals keys use their own styles', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(CalcKeyButton(label: '%', kind: CalcKeyKind.function, onTap: () {})),
    );

    BoxDecoration decoration = decorationOf(tester);
    expect(decoration.color, AppColors.keyNumber);
    expect(styleOf(tester, '%').fontSize, 22);
    expect(styleOf(tester, '%').fontWeight, AppTypography.bold);
    expect(styleOf(tester, '%').color, AppColors.primary);

    await tester.pumpWidget(
      wrap(CalcKeyButton(label: '÷', kind: CalcKeyKind.operator, onTap: () {})),
    );

    decoration = decorationOf(tester);
    expect(decoration.color, AppColors.keyOperator);
    expect(
      (decoration.border! as Border).top.color,
      AppColors.keyOperatorBorder,
    );
    expect(styleOf(tester, '÷').fontSize, 28);
    expect(styleOf(tester, '÷').color, AppColors.primary);

    await tester.pumpWidget(
      wrap(CalcKeyButton(label: '=', kind: CalcKeyKind.equals, onTap: () {})),
    );

    decoration = decorationOf(tester);
    expect(decoration.color, AppColors.primary);
    expect(decoration.border, isNull);
    expect(styleOf(tester, '=').fontSize, 30);
    expect(styleOf(tester, '=').color, AppColors.onPrimary);
  });

  testWidgets('the scientific density uses the compact 46 px keys', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        CalcKeyButton(
          label: '8',
          kind: CalcKeyKind.number,
          density: CalcKeyDensity.scientific,
          onTap: () {},
        ),
      ),
    );

    BoxDecoration decoration = decorationOf(tester);
    expect(decoration.color, AppColors.keyNumberScientific);
    expect(
      decoration.borderRadius,
      BorderRadius.circular(AppRadii.keyScientific),
    );
    expect(tester.getSize(find.byType(AnimatedContainer)).height, 46);
    expect(styleOf(tester, '8').fontSize, 22);
    expect(styleOf(tester, '8').color, AppColors.ink);

    await tester.pumpWidget(
      wrap(
        CalcKeyButton(
          label: 'sin',
          kind: CalcKeyKind.function,
          density: CalcKeyDensity.scientific,
          onTap: () {},
        ),
      ),
    );
    expect(decorationOf(tester).color, AppColors.keyFunction);
    expect(styleOf(tester, 'sin').fontSize, 16);
    expect(styleOf(tester, 'sin').fontWeight, AppTypography.medium);
    expect(styleOf(tester, 'sin').color, AppColors.primary);

    await tester.pumpWidget(
      wrap(
        CalcKeyButton(
          label: '×',
          kind: CalcKeyKind.operator,
          density: CalcKeyDensity.scientific,
          onTap: () {},
        ),
      ),
    );
    expect(styleOf(tester, '×').fontSize, 24);

    await tester.pumpWidget(
      wrap(
        CalcKeyButton(
          label: '=',
          kind: CalcKeyKind.equals,
          density: CalcKeyDensity.scientific,
          onTap: () {},
        ),
      ),
    );
    expect(styleOf(tester, '=').fontSize, 26);
  });

  testWidgets('a tap fires the callback and a selection haptic', (
    tester,
  ) async {
    final List<MethodCall> calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    int taps = 0;
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      wrap(
        CalcKeyButton(
          label: '÷',
          kind: CalcKeyKind.operator,
          semanticLabel: 'Divide',
          onTap: () => taps++,
        ),
      ),
    );

    await tester.tap(find.byType(CalcKeyButton));
    await tester.pump();

    expect(taps, 1);
    expect(
      calls.any(
        (MethodCall call) =>
            call.method == 'HapticFeedback.vibrate' &&
            call.arguments == 'HapticFeedbackType.selectionClick',
      ),
      isTrue,
    );

    expect(
      tester.getSemantics(find.byType(CalcKeyButton)),
      matchesSemantics(
        label: 'Divide',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('a long press fires the secondary action only', (tester) async {
    int taps = 0;
    int holds = 0;
    await tester.pumpWidget(
      wrap(
        CalcKeyButton(
          label: '⌫',
          kind: CalcKeyKind.function,
          semanticLabel: 'Backspace',
          onTap: () => taps++,
          onLongPress: () => holds++,
        ),
      ),
    );

    await tester.longPress(find.byType(CalcKeyButton));
    await tester.pump();

    expect(holds, 1);
    expect(taps, 0);
  });

  testWidgets('haptics can be turned off, for example from Settings', (
    tester,
  ) async {
    final List<MethodCall> calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      wrap(
        CalcKeyButton(
          label: '5',
          kind: CalcKeyKind.number,
          haptics: false,
          onTap: () {},
        ),
      ),
    );

    await tester.tap(find.byType(CalcKeyButton));
    await tester.pump();

    expect(
      calls.where((MethodCall call) => call.method == 'HapticFeedback.vibrate'),
      isEmpty,
    );
  });

  testWidgets('pressing scales to 0.96 and darkens the background', (
    tester,
  ) async {
    int taps = 0;
    await tester.pumpWidget(
      wrap(
        CalcKeyButton(
          label: '5',
          kind: CalcKeyKind.number,
          onTap: () => taps++,
        ),
      ),
    );

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(CalcKeyButton)),
    );
    // TapGestureRecognizer fires onTapDown after its 100 ms deadline.
    await tester.pump(const Duration(milliseconds: 120));

    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      AppMotion.keyPressScale,
    );
    expect(
      decorationOf(tester).color,
      Color.lerp(AppColors.keyNumber, Colors.black, AppMotion.keyPressDarken),
    );

    await gesture.up();
    await tester.pump();

    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    expect(decorationOf(tester).color, AppColors.keyNumber);
    expect(taps, 1);
  });

  testWidgets('the equals key darkens to primaryDeep while pressed', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(CalcKeyButton(label: '=', kind: CalcKeyKind.equals, onTap: () {})),
    );

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(CalcKeyButton)),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(decorationOf(tester).color, AppColors.primaryDeep);

    await gesture.up();
    await tester.pump();
  });

  testWidgets('a disabled key is dashed, dimmed and not tappable', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();

    int taps = 0;
    await tester.pumpWidget(
      wrap(
        CalcKeyButton(
          label: 'A',
          kind: CalcKeyKind.disabled,
          onTap: () => taps++,
        ),
      ),
    );

    final BoxDecoration decoration = decorationOf(tester);
    expect(decoration.color, AppColors.sheet);
    expect(decoration.border, isNull);
    expect(styleOf(tester, 'A').color, AppColors.disabled);
    expect(
      find.descendant(
        of: find.byType(CalcKeyButton),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byType(CalcKeyButton));
    await tester.pump();
    expect(taps, 0);

    expect(
      tester.getSemantics(find.byType(CalcKeyButton)),
      matchesSemantics(
        label: 'A',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );

    semantics.dispose();
  });

  testWidgets('key sounds play the platform click only when enabled', (
    tester,
  ) async {
    final List<MethodCall> calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      wrap(
        CalcKeyButton(
          label: '5',
          kind: CalcKeyKind.number,
          sounds: true,
          haptics: false,
          onTap: () {},
        ),
      ),
    );
    await tester.tap(find.byType(CalcKeyButton));
    await tester.pump();

    expect(
      calls.where(
        (MethodCall call) =>
            call.method == 'SystemSound.play' &&
            call.arguments == 'SystemSoundType.click',
      ),
      hasLength(1),
    );

    calls.clear();
    await tester.pumpWidget(
      wrap(
        CalcKeyButton(
          label: '5',
          kind: CalcKeyKind.number,
          haptics: false,
          onTap: () {},
        ),
      ),
    );
    await tester.tap(find.byType(CalcKeyButton));
    await tester.pump();

    expect(calls.where((MethodCall call) => call.method == 'SystemSound.play'), isEmpty);
  });
}
