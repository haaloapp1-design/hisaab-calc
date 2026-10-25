import 'package:calculator/features/settings/widgets/toggle_switch.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:calculator/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: Center(child: child)),
  );

  AnimatedContainer track(WidgetTester tester) =>
      tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));

  BoxDecoration decoration(WidgetTester tester) =>
      track(tester).decoration! as BoxDecoration;

  testWidgets('off is a 50×30 switchOff track with the knob on the left', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ToggleSwitch(
          value: false,
          onChanged: (bool value) {},
          semanticLabel: 'Thousands separator',
        ),
      ),
    );

    expect(tester.getSize(find.byType(ToggleSwitch)), const Size(50, 30));
    expect(decoration(tester).color, AppColors.switchOff);
    expect(
      decoration(tester).borderRadius,
      BorderRadius.circular(AppSizes.switchHeight / 2),
    );
    expect(track(tester).alignment, Alignment.centerLeft);
    expect(track(tester).duration, AppMotion.toggle);

    expect(
      tester.getSize(find.byKey(const Key('toggle-knob'))),
      const Size(AppSizes.switchKnob, AppSizes.switchKnob),
    );
  });

  testWidgets('on uses the primary track and puts the knob on the right', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ToggleSwitch(
          value: true,
          onChanged: (bool value) {},
          semanticLabel: 'Key sounds',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(decoration(tester).color, AppColors.primary);
    expect(track(tester).alignment, Alignment.centerRight);
  });

  testWidgets('tapping reports the opposite value', (tester) async {
    bool? reported;
    await tester.pumpWidget(
      wrap(
        ToggleSwitch(
          value: false,
          onChanged: (bool value) => reported = value,
          semanticLabel: 'Vibrate on key press',
        ),
      ),
    );

    await tester.tap(find.byType(ToggleSwitch));

    expect(reported, isTrue);
  });

  testWidgets('exposes its label and on/off state to screen readers', (
    tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(
      wrap(
        ToggleSwitch(
          value: true,
          onChanged: (bool value) {},
          semanticLabel: 'Vibrate on key press',
        ),
      ),
    );

    expect(find.bySemanticsLabel('Vibrate on key press'), findsOneWidget);
    handle.dispose();
  });
}
