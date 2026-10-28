import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/features/tools/pages/statistics_page.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app() => ProviderScope(
    overrides: [kvStoreProvider.overrideWithValue(MemoryKvStore())],
    child: MaterialApp(theme: AppTheme.light(), home: const StatisticsPage()),
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

  Future<void> enter(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('statistics-values')), text);
    await tester.pump();
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

  testWidgets('opens on the six-number list', (tester) async {
    await pumpPage(tester);

    expect(find.text('Statistics'), findsOneWidget);
    expect(textOf(tester, const Key('tool-result-value')), '18.00');
    expect(find.text('6 values · sum 108.00'), findsOneWidget);
    expect(
      fieldText(tester, const Key('statistics-values')),
      '4, 8, 15, 16, 23, 42',
    );

    expect(textOf(tester, const Key('statistics-count')), '6');
    expect(textOf(tester, const Key('statistics-sum')), '108.00');
    expect(textOf(tester, const Key('statistics-median')), '15.50');
    expect(textOf(tester, const Key('statistics-mode')), 'None');
    expect(textOf(tester, const Key('statistics-min')), '4.00');
    expect(textOf(tester, const Key('statistics-max')), '42.00');
    expect(textOf(tester, const Key('statistics-range')), '38.00');
    expect(textOf(tester, const Key('statistics-population-sd')), '12.32');
    expect(textOf(tester, const Key('statistics-sample-sd')), '13.49');
  });

  testWidgets('a tied mode lists every winning value', (tester) async {
    await pumpPage(tester);

    await enter(tester, '1, 2, 2, 3, 3');

    expect(textOf(tester, const Key('tool-result-value')), '2.20');
    expect(find.text('5 values · sum 11.00'), findsOneWidget);
    expect(textOf(tester, const Key('statistics-count')), '5');
    expect(textOf(tester, const Key('statistics-median')), '2.00');
    expect(textOf(tester, const Key('statistics-mode')), '2.00, 3.00');
    expect(textOf(tester, const Key('statistics-population-sd')), '0.75');
    expect(textOf(tester, const Key('statistics-sample-sd')), '0.84');
  });

  testWidgets('a single value has no sample SD', (tester) async {
    await pumpPage(tester);

    await enter(tester, '5');

    expect(textOf(tester, const Key('tool-result-value')), '5.00');
    expect(textOf(tester, const Key('statistics-count')), '1');
    expect(textOf(tester, const Key('statistics-median')), '5.00');
    expect(textOf(tester, const Key('statistics-mode')), 'None');
    expect(textOf(tester, const Key('statistics-population-sd')), '0.00');
    expect(textOf(tester, const Key('statistics-sample-sd')), '—');
  });

  testWidgets('negative values keep min, max and range right', (tester) async {
    await pumpPage(tester);

    await enter(tester, '-5, 0, 5, 10');

    expect(textOf(tester, const Key('tool-result-value')), '2.50');
    expect(textOf(tester, const Key('statistics-min')), '−5.00');
    expect(textOf(tester, const Key('statistics-max')), '10.00');
    expect(textOf(tester, const Key('statistics-range')), '15.00');
  });

  testWidgets('an invalid token shows a dash and hides the summary', (
    tester,
  ) async {
    await pumpPage(tester);

    await enter(tester, '1, x, 3');

    expect(textOf(tester, const Key('tool-result-value')), '—');
    expect(find.text('Enter numbers separated by commas'), findsOneWidget);
    expect(find.byKey(const Key('statistics-count')), findsNothing);
  });

  testWidgets('an empty list shows a dash', (tester) async {
    await pumpPage(tester);

    await enter(tester, '');

    expect(textOf(tester, const Key('tool-result-value')), '—');
    expect(find.byKey(const Key('statistics-sum')), findsNothing);
  });

  testWidgets('share copies every statistic', (tester) async {
    await pumpPage(tester);
    final List<String> copied = captureClipboard(tester);

    await tester.tap(find.byTooltip('Share result'));
    await tester.pump();

    expect(copied, hasLength(1));
    expect(copied.single, contains('Statistics'));
    expect(copied.single, contains('Count: 6'));
    expect(copied.single, contains('Sum: 108.00'));
    expect(copied.single, contains('Mean: 18.00'));
    expect(copied.single, contains('Median: 15.50'));
    expect(copied.single, contains('Mode: None'));
    expect(copied.single, contains('Min: 4.00'));
    expect(copied.single, contains('Max: 42.00'));
    expect(copied.single, contains('Range: 38.00'));
    expect(copied.single, contains('Population SD: 12.32'));
    expect(copied.single, contains('Sample SD: 13.49'));
  });

  testWidgets('the action copies just the mean', (tester) async {
    await pumpPage(tester);
    final List<String> copied = captureClipboard(tester);

    await tester.ensureVisible(find.byKey(const Key('tool-action')));
    await tester.tap(find.byKey(const Key('tool-action')));
    await tester.pump();

    expect(copied, <String>['18.00']);
    expect(find.text('Copied'), findsOneWidget);
  });
}
