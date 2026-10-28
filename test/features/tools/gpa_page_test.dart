import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/features/tools/pages/gpa_page.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app() => ProviderScope(
    overrides: [kvStoreProvider.overrideWithValue(MemoryKvStore())],
    child: MaterialApp(theme: AppTheme.light(), home: const GpaPage()),
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

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.tap(find.byKey(key));
    await tester.pump();
  }

  testWidgets('opens on three courses with a 3.56 GPA', (tester) async {
    await pumpPage(tester);

    expect(find.text('GPA / grades'), findsOneWidget);
    expect(textOf(tester, const Key('tool-result-value')), '3.56');
    expect(find.text('9 credits · 3 courses'), findsOneWidget);

    expect(fieldText(tester, const Key('gpa-course-1-name')), 'Maths');
    expect(fieldText(tester, const Key('gpa-course-1-credits')), '3');
    expect(fieldText(tester, const Key('gpa-course-1-points')), '4');
    expect(fieldText(tester, const Key('gpa-course-2-name')), 'Physics');
    expect(fieldText(tester, const Key('gpa-course-2-credits')), '4');
    expect(fieldText(tester, const Key('gpa-course-2-points')), '3.5');
    expect(fieldText(tester, const Key('gpa-course-3-name')), 'English');
    expect(fieldText(tester, const Key('gpa-course-3-credits')), '2');
    expect(fieldText(tester, const Key('gpa-course-3-points')), '3');

    expect(textOf(tester, const Key('gpa-total-credits')), '9');
    expect(textOf(tester, const Key('gpa-course-count')), '3');
    expect(textOf(tester, const Key('gpa-scale-value')), '4.0');
    expect(textOf(tester, const Key('gpa-percentage')), '88.89%');
  });

  testWidgets('the scale chips change only the percentage', (tester) async {
    await pumpPage(tester);

    await tapVisible(tester, const Key('gpa-scale-1'));
    expect(textOf(tester, const Key('tool-result-value')), '3.56');
    expect(textOf(tester, const Key('gpa-scale-value')), '5.0');
    expect(textOf(tester, const Key('gpa-percentage')), '71.11%');

    await tapVisible(tester, const Key('gpa-scale-2'));
    expect(textOf(tester, const Key('tool-result-value')), '3.56');
    expect(textOf(tester, const Key('gpa-scale-value')), '10.0');
    expect(textOf(tester, const Key('gpa-percentage')), '35.56%');
  });

  testWidgets('editing a grade recalculates the weighted average', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.enterText(find.byKey(const Key('gpa-course-2-points')), '4');
    await tester.pump();

    expect(textOf(tester, const Key('tool-result-value')), '3.78');
    expect(find.text('9 credits · 3 courses'), findsOneWidget);
    expect(textOf(tester, const Key('gpa-percentage')), '94.44%');
  });

  testWidgets('a course can be added and starts with no credits', (
    tester,
  ) async {
    await pumpPage(tester);

    await tapVisible(tester, const Key('gpa-add'));
    await tester.pumpAndSettle();

    expect(fieldText(tester, const Key('gpa-course-4-name')), '');
    expect(fieldText(tester, const Key('gpa-course-4-credits')), '0');
    expect(textOf(tester, const Key('tool-result-value')), '3.56');
    expect(find.text('9 credits · 4 courses'), findsOneWidget);
    expect(textOf(tester, const Key('gpa-course-count')), '4');

    await tester.enterText(find.byKey(const Key('gpa-course-4-credits')), '3');
    await tester.enterText(find.byKey(const Key('gpa-course-4-points')), '3');
    await tester.pump();

    expect(textOf(tester, const Key('tool-result-value')), '3.42');
    expect(find.text('12 credits · 4 courses'), findsOneWidget);
  });

  testWidgets('deleting a course drops its credits', (tester) async {
    await pumpPage(tester);

    await tapVisible(tester, const Key('gpa-course-2-delete'));

    expect(find.byKey(const Key('gpa-course-2-name')), findsNothing);
    expect(textOf(tester, const Key('tool-result-value')), '3.60');
    expect(find.text('5 credits · 2 courses'), findsOneWidget);
    expect(textOf(tester, const Key('gpa-total-credits')), '5');
  });

  testWidgets('deleting every course shows a dash', (tester) async {
    await pumpPage(tester);

    await tapVisible(tester, const Key('gpa-course-1-delete'));
    await tapVisible(tester, const Key('gpa-course-2-delete'));
    await tapVisible(tester, const Key('gpa-course-3-delete'));

    expect(textOf(tester, const Key('tool-result-value')), '—');
    expect(find.text('Add a course with credits'), findsOneWidget);
    expect(find.byKey(const Key('gpa-total-credits')), findsNothing);
  });

  testWidgets('share copies the scale, credits and percentage', (tester) async {
    await pumpPage(tester);
    final List<String> copied = captureClipboard(tester);

    await tester.tap(find.byTooltip('Share result'));
    await tester.pump();

    expect(copied, hasLength(1));
    expect(copied.single, contains('GPA / grades'));
    expect(copied.single, contains('Scale: 4.0'));
    expect(copied.single, contains('Courses: 3'));
    expect(copied.single, contains('Total credits: 9'));
    expect(copied.single, contains('GPA: 3.56'));
    expect(copied.single, contains('Percentage: 88.89%'));
  });

  testWidgets('the action copies just the GPA', (tester) async {
    await pumpPage(tester);
    final List<String> copied = captureClipboard(tester);

    await tapVisible(tester, const Key('tool-action'));

    expect(copied, <String>['3.56']);
    expect(find.text('Copied'), findsOneWidget);
  });
}
