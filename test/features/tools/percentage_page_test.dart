import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/features/tools/pages/percentage_page.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:calculator/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app() => ProviderScope(
    overrides: [kvStoreProvider.overrideWithValue(MemoryKvStore())],
    child: MaterialApp(theme: AppTheme.light(), home: const PercentagePage()),
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

  testWidgets('opens on X% of Y', (tester) async {
    await pumpPage(tester);

    expect(find.text('Percentage'), findsOneWidget);
    expect(textOf(tester, const Key('tool-result-value')), '30.00');
    expect(find.text('15% of 200'), findsOneWidget);
    expect(fieldText(tester, const Key('percentage-x')), '15');
    expect(fieldText(tester, const Key('percentage-y')), '200');
    expect(textOf(tester, const Key('percentage-result')), '30.00');

    final Text selected = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('percentage-mode-0')),
        matching: find.text('X% of Y'),
      ),
    );
    expect(selected.style?.fontWeight, AppTypography.bold);
  });

  testWidgets('switches to the ratio and change questions', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('percentage-mode-1')));
    await tester.pump();

    expect(fieldText(tester, const Key('percentage-x')), '25');
    expect(fieldText(tester, const Key('percentage-y')), '200');
    expect(textOf(tester, const Key('tool-result-value')), '12.50%');
    expect(find.text('25 is what % of 200'), findsOneWidget);
    expect(textOf(tester, const Key('percentage-result')), '12.50%');

    await tester.tap(find.byKey(const Key('percentage-mode-2')));
    await tester.pump();

    expect(fieldText(tester, const Key('percentage-x')), '200');
    expect(fieldText(tester, const Key('percentage-y')), '250');
    expect(textOf(tester, const Key('tool-result-value')), '25.00%');
    expect(find.text('% change from 200 to 250'), findsOneWidget);
    expect(textOf(tester, const Key('percentage-result')), '25.00%');
  });

  testWidgets('a zero denominator shows a dash', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('percentage-mode-1')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('percentage-y')), '0');
    await tester.pump();

    expect(textOf(tester, const Key('tool-result-value')), '—');
    expect(find.text('Cannot divide by zero'), findsOneWidget);
    expect(textOf(tester, const Key('percentage-result')), '—');
  });

  testWidgets('editing X recalculates the answer live', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byKey(const Key('percentage-x')), '50');
    await tester.pump();

    expect(fieldText(tester, const Key('percentage-x')), '50');
    expect(textOf(tester, const Key('tool-result-value')), '100.00');
    expect(find.text('50% of 200'), findsOneWidget);
  });

  testWidgets('share copies the question and the answer', (tester) async {
    await pumpPage(tester);
    final List<String> copied = captureClipboard(tester);

    await tester.tap(find.byTooltip('Share result'));
    await tester.pump();

    expect(copied, hasLength(1));
    expect(copied.single, contains('Percentage'));
    expect(copied.single, contains('15% of 200'));
    expect(copied.single, contains('Answer: 30.00'));
  });

  testWidgets('the action copies just the result', (tester) async {
    await pumpPage(tester);
    final List<String> copied = captureClipboard(tester);

    await tester.ensureVisible(find.byKey(const Key('tool-action')));
    await tester.tap(find.byKey(const Key('tool-action')));
    await tester.pump();

    expect(copied, <String>['30.00']);
    expect(find.text('Copied'), findsOneWidget);
  });
}
