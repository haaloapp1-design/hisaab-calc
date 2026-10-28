import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/features/tools/pages/age_page.dart';
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
      home: AgePage(today: today ?? DateTime.utc(2026, 10, 28), picker: picker),
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

  testWidgets('opens on 1 Jan 1990 and today', (tester) async {
    await pumpPage(tester, app());

    expect(find.text('Age'), findsWidgets);
    expect(textOf(tester, const Key('tool-result-value')), '36y 9m 27d');
    expect(find.text('Next birthday in 65 days'), findsOneWidget);
    expect(find.text('1 Jan 1990'), findsOneWidget);
    expect(find.text('28 Oct 2026'), findsOneWidget);

    expect(textOf(tester, const Key('age-years')), '36');
    expect(textOf(tester, const Key('age-months')), '9');
    expect(textOf(tester, const Key('age-days')), '27');
    expect(textOf(tester, const Key('age-total-days')), '13,449');
    expect(textOf(tester, const Key('age-next-birthday')), '1 Jan 2027');
  });

  testWidgets('a picked 29 Feb birthday recalculates the age', (tester) async {
    await pumpPage(
      tester,
      app(picker: queuePicker(<DateTime?>[DateTime.utc(2000, 2, 29)])),
    );

    await tester.tap(find.byKey(const Key('age-dob')));
    await tester.pumpAndSettle();

    expect(find.text('29 Feb 2000'), findsOneWidget);
    expect(textOf(tester, const Key('tool-result-value')), '26y 7m 29d');
    expect(textOf(tester, const Key('age-total-days')), '9,738');
    expect(textOf(tester, const Key('age-next-birthday')), '28 Feb 2027');
    expect(find.text('Next birthday in 123 days'), findsOneWidget);
  });

  testWidgets('an on date before the birth date shows a dash', (tester) async {
    await pumpPage(
      tester,
      app(picker: queuePicker(<DateTime?>[DateTime.utc(1989, 12, 31)])),
    );

    await tester.tap(find.byKey(const Key('age-on')));
    await tester.pumpAndSettle();

    expect(find.text('31 Dec 1989'), findsOneWidget);
    expect(textOf(tester, const Key('tool-result-value')), '—');
    expect(find.text('On date is before the date of birth'), findsOneWidget);
    expect(find.byKey(const Key('age-total-days')), findsNothing);
  });

  testWidgets('a birthday tomorrow reads tomorrow', (tester) async {
    await pumpPage(tester, app(today: DateTime.utc(2026, 12, 31)));

    expect(textOf(tester, const Key('tool-result-value')), '36y 11m 30d');
    expect(find.text('Next birthday tomorrow'), findsOneWidget);
  });

  testWidgets('share copies the full age summary', (tester) async {
    await pumpPage(tester, app());
    final List<String> copied = captureClipboard(tester);

    await tester.tap(find.byTooltip('Share result'));
    await tester.pump();

    expect(copied, hasLength(1));
    expect(copied.single, contains('Age'));
    expect(copied.single, contains('Date of birth: 1 Jan 1990'));
    expect(copied.single, contains('Age on: 28 Oct 2026'));
    expect(copied.single, contains('Age: 36y 9m 27d'));
    expect(copied.single, contains('Total days: 13,449'));
    expect(copied.single, contains('Next birthday: 1 Jan 2027'));
    expect(copied.single, contains('Days to next birthday: 65'));
  });

  testWidgets('the action copies just the age', (tester) async {
    await pumpPage(tester, app());
    final List<String> copied = captureClipboard(tester);

    await tester.ensureVisible(find.byKey(const Key('tool-action')));
    await tester.tap(find.byKey(const Key('tool-action')));
    await tester.pump();

    expect(copied, <String>['36y 9m 27d']);
    expect(find.text('Copied'), findsOneWidget);
  });
}
