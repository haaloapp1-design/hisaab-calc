import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/features/tools/pages/equation_page.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app() => ProviderScope(
    overrides: [kvStoreProvider.overrideWithValue(MemoryKvStore())],
    child: MaterialApp(theme: AppTheme.light(), home: const EquationPage()),
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

  Future<void> enter(WidgetTester tester, Key key, String text) async {
    await tester.enterText(find.byKey(key), text);
    await tester.pump();
  }

  testWidgets('opens on 2x − 8 = 0 with the root 4', (tester) async {
    await pumpPage(tester);

    expect(find.text('Equation solver'), findsOneWidget);
    expect(textOf(tester, const Key('tool-result-value')), '4.00');
    expect(find.text('Linear equation'), findsOneWidget);
    expect(fieldText(tester, const Key('equation-a')), '2');
    expect(fieldText(tester, const Key('equation-b')), '-8');
    expect(find.byKey(const Key('equation-c')), findsNothing);

    expect(textOf(tester, const Key('equation-value-a')), '2');
    expect(textOf(tester, const Key('equation-value-b')), '−8');
    expect(textOf(tester, const Key('equation-solution')), '4.00');
  });

  testWidgets('3x + 1 = 0 shows a negative decimal root', (tester) async {
    await pumpPage(tester);

    await enter(tester, const Key('equation-a'), '3');
    await enter(tester, const Key('equation-b'), '1');

    expect(textOf(tester, const Key('tool-result-value')), '−0.33');
  });

  testWidgets('a = 0 reports no solution or every x', (tester) async {
    await pumpPage(tester);

    await enter(tester, const Key('equation-a'), '0');
    await enter(tester, const Key('equation-b'), '5');

    expect(textOf(tester, const Key('tool-result-value')), 'No solution');
    expect(find.text('a = 0 and b ≠ 0'), findsOneWidget);
    expect(textOf(tester, const Key('equation-solution')), 'No solution');

    await enter(tester, const Key('equation-b'), '0');

    expect(textOf(tester, const Key('tool-result-value')), 'Every x');
    expect(find.text('a = 0 and b = 0'), findsOneWidget);
  });

  testWidgets('the quadratic chips show x² − 3x + 2 = 0', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('equation-mode-1')));
    await tester.pump();

    expect(fieldText(tester, const Key('equation-a')), '1');
    expect(fieldText(tester, const Key('equation-b')), '-3');
    expect(fieldText(tester, const Key('equation-c')), '2');
    expect(textOf(tester, const Key('tool-result-value')), '1.00, 2.00');
    expect(find.text('D = 1 · two real roots'), findsOneWidget);
    expect(textOf(tester, const Key('equation-value-c')), '2');
    expect(textOf(tester, const Key('equation-discriminant')), '1');
    expect(textOf(tester, const Key('equation-solution')), '1.00, 2.00');
  });

  testWidgets('D = 0 shows one repeated root', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('equation-mode-1')));
    await tester.pump();
    await enter(tester, const Key('equation-b'), '-2');
    await enter(tester, const Key('equation-c'), '1');

    expect(textOf(tester, const Key('tool-result-value')), '1.00');
    expect(find.text('D = 0 · one real root'), findsOneWidget);
    expect(textOf(tester, const Key('equation-discriminant')), '0');
  });

  testWidgets('D < 0 shows a compact complex pair', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('equation-mode-1')));
    await tester.pump();
    await enter(tester, const Key('equation-c'), '2.5');

    expect(textOf(tester, const Key('tool-result-value')), '1.50 ± 0.50i');
    expect(find.text('D = −1 · complex roots'), findsOneWidget);
    expect(textOf(tester, const Key('equation-discriminant')), '−1');
  });

  testWidgets('a = 0 in the quadratic mode falls back to linear', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('equation-mode-1')));
    await tester.pump();
    await enter(tester, const Key('equation-a'), '0');
    await enter(tester, const Key('equation-b'), '2');
    await enter(tester, const Key('equation-c'), '-8');

    expect(textOf(tester, const Key('tool-result-value')), '4.00');
    expect(find.text('a = 0 → solved as linear'), findsOneWidget);
    expect(find.byKey(const Key('equation-discriminant')), findsNothing);
  });

  testWidgets('each mode keeps its own coefficients', (tester) async {
    await pumpPage(tester);

    await enter(tester, const Key('equation-b'), '-10');
    await tester.tap(find.byKey(const Key('equation-mode-1')));
    await tester.pump();
    expect(textOf(tester, const Key('tool-result-value')), '1.00, 2.00');

    await tester.tap(find.byKey(const Key('equation-mode-0')));
    await tester.pump();

    expect(fieldText(tester, const Key('equation-b')), '-10');
    expect(textOf(tester, const Key('tool-result-value')), '5.00');
  });

  testWidgets('share copies the coefficients and the answer', (tester) async {
    await pumpPage(tester);
    final List<String> copied = captureClipboard(tester);

    await tester.tap(find.byTooltip('Share result'));
    await tester.pump();

    expect(copied, hasLength(1));
    expect(copied.single, contains('Equation solver'));
    expect(copied.single, contains('Type: Linear'));
    expect(copied.single, contains('a: 2'));
    expect(copied.single, contains('b: −8'));
    expect(copied.single, contains('Root: 4.00'));
  });

  testWidgets('the action copies just the root', (tester) async {
    await pumpPage(tester);
    final List<String> copied = captureClipboard(tester);

    await tester.ensureVisible(find.byKey(const Key('tool-action')));
    await tester.tap(find.byKey(const Key('tool-action')));
    await tester.pump();

    expect(copied, <String>['4.00']);
    expect(find.text('Copied'), findsOneWidget);
  });
}
