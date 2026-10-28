import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/features/tools/pages/date_difference_page.dart';
import 'package:calculator/features/tools/widgets/tool_date_field.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app({DateTime? today, ToolDatePicker? picker}) => ProviderScope(
    overrides: [kvStoreProvider.overrideWithValue(MemoryKvStore())],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: DateDifferencePage(
        today: today ?? DateTime.utc(2026, 10, 28),
        picker: picker,
      ),
    ),
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

  Future<void> pumpPage(WidgetTester tester, Widget widget) async {
    designSurface(tester);
    await tester.pumpWidget(widget);
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

  ToolDatePicker queuePicker(List<DateTime?> picks) =>
      (
        BuildContext context,
        DateTime initial,
        DateTime first,
        DateTime last,
      ) async => picks.isEmpty ? null : picks.removeAt(0);

  testWidgets('opens on the last 30 days', (tester) async {
    await pumpPage(tester, app());

    expect(find.text('Date difference'), findsOneWidget);
    expect(textOf(tester, const Key('tool-result-value')), '30');
    expect(find.text('28 Sep 2026 → 28 Oct 2026'), findsOneWidget);
    expect(find.text('28 Sep 2026'), findsOneWidget);
    expect(find.text('28 Oct 2026'), findsWidgets);

    expect(textOf(tester, const Key('date-weeks')), '4 weeks 2 days');
    expect(textOf(tester, const Key('date-months')), '1 month 0 days');
    expect(textOf(tester, const Key('date-include')), 'No');
    expect(textOf(tester, const Key('date-total-days')), '30');
  });

  testWidgets('including the end date adds a day', (tester) async {
    await pumpPage(tester, app());

    await tester.tap(find.byKey(const Key('date-include-end')));
    await tester.pump();

    expect(textOf(tester, const Key('tool-result-value')), '31');
    expect(textOf(tester, const Key('date-weeks')), '4 weeks 3 days');
    expect(textOf(tester, const Key('date-include')), 'Yes');
    expect(textOf(tester, const Key('date-total-days')), '31');
  });

  testWidgets('a picked end date recalculates the rows', (tester) async {
    await pumpPage(
      tester,
      app(picker: queuePicker(<DateTime?>[DateTime.utc(2026, 11, 27)])),
    );

    await tester.tap(find.byKey(const Key('date-end')));
    await tester.pumpAndSettle();

    expect(find.text('27 Nov 2026'), findsWidgets);
    expect(textOf(tester, const Key('tool-result-value')), '60');
    expect(find.text('28 Sep 2026 → 27 Nov 2026'), findsOneWidget);
    expect(textOf(tester, const Key('date-weeks')), '8 weeks 4 days');
    expect(textOf(tester, const Key('date-months')), '1 month 30 days');
  });

  testWidgets('a reversed range shows a negative day count', (tester) async {
    await pumpPage(
      tester,
      app(picker: queuePicker(<DateTime?>[DateTime.utc(2026, 9, 1)])),
    );

    await tester.tap(find.byKey(const Key('date-end')));
    await tester.pumpAndSettle();

    expect(textOf(tester, const Key('tool-result-value')), '−27');
    expect(
      find.text('28 Sep 2026 → 1 Sep 2026 · end is before start'),
      findsOneWidget,
    );
    expect(textOf(tester, const Key('date-weeks')), '−3 weeks 6 days');
  });

  testWidgets('the shift panel adds and subtracts days', (tester) async {
    await pumpPage(tester, app());

    expect(find.text('27 Nov 2026'), findsOneWidget);
    expect(textOf(tester, const Key('shift-result-day')), 'Friday');

    await tester.ensureVisible(find.byKey(const Key('shift-mode-1')));
    await tester.tap(find.byKey(const Key('shift-mode-1')));
    await tester.pump();

    expect(textOf(tester, const Key('shift-result-date')), '28 Sep 2026');
    expect(textOf(tester, const Key('shift-result-day')), 'Monday');

    await tester.enterText(find.byKey(const Key('shift-days')), '1');
    await tester.pump();

    expect(textOf(tester, const Key('shift-result-date')), '27 Oct 2026');
    expect(textOf(tester, const Key('shift-result-day')), 'Tuesday');

    await tester.tap(find.byKey(const Key('shift-mode-0')));
    await tester.pump();

    expect(textOf(tester, const Key('shift-result-date')), '29 Oct 2026');
    expect(textOf(tester, const Key('shift-result-day')), 'Thursday');
  });

  testWidgets('share copies the difference summary', (tester) async {
    await pumpPage(tester, app());
    final List<String> copied = captureClipboard(tester);

    await tester.tap(find.byTooltip('Share result'));
    await tester.pump();

    expect(copied, hasLength(1));
    expect(copied.single, contains('Date difference'));
    expect(copied.single, contains('Start: 28 Sep 2026'));
    expect(copied.single, contains('End: 28 Oct 2026'));
    expect(copied.single, contains('Include end date: No'));
    expect(copied.single, contains('Days: 30'));
    expect(copied.single, contains('Weeks + days: 4 weeks 2 days'));
    expect(copied.single, contains('Months + days: 1 month 0 days'));
  });

  testWidgets('the action copies just the day count', (tester) async {
    await pumpPage(tester, app());
    final List<String> copied = captureClipboard(tester);

    await tester.ensureVisible(find.byKey(const Key('tool-action')));
    await tester.tap(find.byKey(const Key('tool-action')));
    await tester.pump();

    expect(copied, <String>['30']);
    expect(find.text('Copied'), findsOneWidget);
  });
}
