import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/features/tools/pages/tip_page.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app() => ProviderScope(
    overrides: [kvStoreProvider.overrideWithValue(MemoryKvStore())],
    child: MaterialApp(theme: AppTheme.light(), home: const TipPage()),
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

  testWidgets('opens on 1000 with a 10% tip for 3 people', (tester) async {
    await pumpPage(tester);

    expect(find.text('Tip and split'), findsOneWidget);
    expect(textOf(tester, const Key('tool-result-value')), '366.67');
    expect(find.text('1,100.00 total for 3 people'), findsOneWidget);
    expect(fieldText(tester, const Key('tip-bill')), '1,000');
    expect(fieldText(tester, const Key('tip-percent')), '10');
    expect(fieldText(tester, const Key('tip-people')), '3');

    expect(textOf(tester, const Key('tip-tip')), '100.00');
    expect(textOf(tester, const Key('tip-total')), '1,100.00');
    expect(textOf(tester, const Key('tip-per-person')), '366.67');
  });

  testWidgets('round up switches the per-person value', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('tip-round-up')));
    await tester.pump();

    expect(textOf(tester, const Key('tool-result-value')), '367.00');
    expect(
      find.text('1,100.00 total for 3 people · rounded up'),
      findsOneWidget,
    );
    expect(textOf(tester, const Key('tip-per-person')), '367.00');

    await tester.tap(find.byKey(const Key('tip-round-up')));
    await tester.pump();
    expect(textOf(tester, const Key('tool-result-value')), '366.67');
  });

  testWidgets('people and tip edits recalculate the split', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('tip-round-up')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('tip-people')), '4');
    await tester.pump();

    expect(textOf(tester, const Key('tool-result-value')), '275.00');
    expect(textOf(tester, const Key('tip-per-person')), '275.00');

    await tester.enterText(find.byKey(const Key('tip-percent')), '15');
    await tester.pump();

    expect(textOf(tester, const Key('tool-result-value')), '288.00');
    expect(textOf(tester, const Key('tip-tip')), '150.00');
    expect(textOf(tester, const Key('tip-total')), '1,150.00');
    expect(
      find.text('1,150.00 total for 4 people · rounded up'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('tip-round-up')));
    await tester.pump();
    expect(textOf(tester, const Key('tool-result-value')), '287.50');
  });

  testWidgets('an empty people field counts as one person', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byKey(const Key('tip-people')), '');
    await tester.pump();

    expect(textOf(tester, const Key('tool-result-value')), '1,100.00');
    expect(find.text('1,100.00 total for 1 person'), findsOneWidget);
  });

  testWidgets('share copies the bill, tip and split', (tester) async {
    await pumpPage(tester);
    final List<String> copied = captureClipboard(tester);

    await tester.tap(find.byTooltip('Share result'));
    await tester.pump();

    expect(copied, hasLength(1));
    expect(copied.single, contains('Tip and split'));
    expect(copied.single, contains('Bill: 1,000.00'));
    expect(copied.single, contains('Tip: 10%'));
    expect(copied.single, contains('People: 3'));
    expect(copied.single, contains('Tip: 100.00'));
    expect(copied.single, contains('Total: 1,100.00'));
    expect(copied.single, contains('Per person: 366.67'));
  });

  testWidgets('the action copies the per-person value', (tester) async {
    await pumpPage(tester);
    final List<String> copied = captureClipboard(tester);

    await tester.ensureVisible(find.byKey(const Key('tool-action')));
    await tester.tap(find.byKey(const Key('tool-action')));
    await tester.pump();

    expect(copied, <String>['366.67']);
    expect(find.text('Copied'), findsOneWidget);
  });
}
