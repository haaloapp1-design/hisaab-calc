import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/features/tools/pages/bmi_page.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app() => ProviderScope(
    overrides: [kvStoreProvider.overrideWithValue(MemoryKvStore())],
    child: MaterialApp(theme: AppTheme.light(), home: const BmiPage()),
  );

  /// The screens in `docs/screens/` are 390×844.
  void designSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  String textOf(WidgetTester tester, Key key) =>
      tester.widget<Text>(find.byKey(key)).data!;

  String fieldText(WidgetTester tester, Key key) =>
      tester.widget<TextField>(find.byKey(key)).controller!.text;

  Future<void> pumpPage(WidgetTester tester) async {
    designSurface(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
  }

  List<String> captureClipboard(WidgetTester tester) {
    final List<String> copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'Clipboard.setData') {
          final Map<Object?, Object?> arguments =
              call.arguments as Map<Object?, Object?>;
          copied.add(arguments['text']! as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    return copied;
  }

  testWidgets('opens on 170 cm and 70 kg', (tester) async {
    await pumpPage(tester);

    expect(find.text('BMI'), findsWidgets);
    expect(textOf(tester, const Key('tool-result-value')), '24.22');
    expect(find.text('Normal · for adults'), findsOneWidget);
    expect(fieldText(tester, const Key('bmi-height')), '170');
    expect(fieldText(tester, const Key('bmi-weight')), '70');

    expect(textOf(tester, const Key('bmi-height-m')), '1.70 m');
    expect(textOf(tester, const Key('bmi-weight-kg')), '70.00 kg');
    expect(textOf(tester, const Key('bmi-category')), 'Normal');
  });

  testWidgets('the imperial chips show 5 ft 7 in and 154 lb', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('bmi-unit-1')));
    await tester.pump();

    expect(fieldText(tester, const Key('bmi-feet')), '5');
    expect(fieldText(tester, const Key('bmi-inches')), '7');
    expect(fieldText(tester, const Key('bmi-pounds')), '154');
    expect(textOf(tester, const Key('tool-result-value')), '24.12');
    expect(find.text('Normal · for adults'), findsOneWidget);
    expect(textOf(tester, const Key('bmi-height-m')), '1.70 m');
    expect(textOf(tester, const Key('bmi-weight-kg')), '69.85 kg');
  });

  testWidgets('editing the metric fields recalculates live', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byKey(const Key('bmi-height')), '180');
    await tester.enterText(find.byKey(const Key('bmi-weight')), '81');
    await tester.pump();

    expect(textOf(tester, const Key('tool-result-value')), '25.00');
    expect(find.text('Overweight · for adults'), findsOneWidget);
    expect(textOf(tester, const Key('bmi-category')), 'Overweight');
    expect(textOf(tester, const Key('bmi-height-m')), '1.80 m');
  });

  testWidgets('an empty weight shows a dash and hides the summary', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.enterText(find.byKey(const Key('bmi-weight')), '');
    await tester.pump();

    expect(textOf(tester, const Key('tool-result-value')), '—');
    expect(find.text('Enter a height and weight'), findsOneWidget);
    expect(find.byKey(const Key('bmi-category')), findsNothing);
  });

  testWidgets('each unit mode keeps its own values', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byKey(const Key('bmi-height')), '180');
    await tester.pump();
    await tester.tap(find.byKey(const Key('bmi-unit-1')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('bmi-feet')), '6');
    await tester.enterText(find.byKey(const Key('bmi-inches')), '0');
    await tester.enterText(find.byKey(const Key('bmi-pounds')), '180');
    await tester.pump();

    expect(textOf(tester, const Key('tool-result-value')), '24.41');

    await tester.tap(find.byKey(const Key('bmi-unit-0')));
    await tester.pump();

    expect(fieldText(tester, const Key('bmi-height')), '180');
    expect(textOf(tester, const Key('tool-result-value')), '21.60');
  });

  testWidgets('share copies the conversion and category', (tester) async {
    await pumpPage(tester);
    final List<String> copied = captureClipboard(tester);

    await tester.tap(find.byTooltip('Share result'));
    await tester.pump();

    expect(copied, hasLength(1));
    expect(copied.single, contains('BMI'));
    expect(copied.single, contains('Height: 1.70 m'));
    expect(copied.single, contains('Weight: 70.00 kg'));
    expect(copied.single, contains('BMI: 24.22'));
    expect(copied.single, contains('Category: Normal (adults)'));
  });

  testWidgets('the action copies just the BMI value', (tester) async {
    await pumpPage(tester);
    final List<String> copied = captureClipboard(tester);

    await tester.ensureVisible(find.byKey(const Key('tool-action')));
    await tester.tap(find.byKey(const Key('tool-action')));
    await tester.pump();

    expect(copied, <String>['24.22']);
    expect(find.text('Copied'), findsOneWidget);
  });
}
