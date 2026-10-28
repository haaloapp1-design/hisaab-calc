import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/features/tools/pages/loan_page.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:calculator/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app() => ProviderScope(
    overrides: [kvStoreProvider.overrideWithValue(MemoryKvStore())],
    child: MaterialApp(theme: AppTheme.light(), home: const LoanPage()),
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

  testWidgets('opens on the screen 10 defaults', (tester) async {
    await pumpPage(tester);

    expect(find.text('Loan / EMI'), findsOneWidget);
    expect(find.text('Monthly instalment'), findsOneWidget);
    expect(textOf(tester, const Key('tool-result-value')), '22,244.45');
    expect(find.text('PKR for 60 months'), findsOneWidget);

    expect(fieldText(tester, const Key('loan-amount')), '1,000,000');
    expect(fieldText(tester, const Key('loan-tenure')), '5');
    expect(find.text('Loan amount (PKR)'), findsOneWidget);
    expect(find.text('Interest rate per year'), findsOneWidget);
    expect(find.text('Tenure'), findsOneWidget);
    expect(find.text('In'), findsOneWidget);

    expect(find.text('1,000,000.00'), findsOneWidget);
    expect(find.text('334,666.86'), findsOneWidget);
    expect(textOf(tester, const Key('loan-total-payable')), '1,334,666.86');

    final FractionallySizedBox bar = tester.widget<FractionallySizedBox>(
      find.byKey(const Key('loan-bar-principal')),
    );
    expect(bar.widthFactor, closeTo(0.7492506, 0.000001));
    expect(tester.getSize(find.byKey(const Key('loan-bar'))).height, 12);
  });

  testWidgets('rate chips recalculate the loan and show the pick', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('loan-rate-10')));
    await tester.pump();

    expect(textOf(tester, const Key('tool-result-value')), '21,247.04');
    expect(textOf(tester, const Key('loan-total-payable')), '1,274,822.68');

    Text selected = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('loan-rate-10')),
        matching: find.text('10%'),
      ),
    );
    Text other = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('loan-rate-12')),
        matching: find.text('12%'),
      ),
    );
    expect(selected.style?.fontWeight, AppTypography.bold);
    expect(other.style?.fontWeight, AppTypography.regular);

    await tester.tap(find.byKey(const Key('loan-rate-14')));
    await tester.pump();
    expect(textOf(tester, const Key('tool-result-value')), '23,268.25');
    expect(find.text('396,095.05'), findsOneWidget);
  });

  testWidgets('years and months keep the number and change its meaning', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('loan-unit-months')));
    await tester.pump();

    expect(fieldText(tester, const Key('loan-tenure')), '5');
    expect(find.text('PKR for 5 months'), findsOneWidget);
    expect(textOf(tester, const Key('tool-result-value')), '206,039.80');
    expect(textOf(tester, const Key('loan-total-payable')), '1,030,199.00');

    await tester.enterText(find.byKey(const Key('loan-tenure')), '60');
    await tester.pump();

    expect(find.text('PKR for 60 months'), findsOneWidget);
    expect(textOf(tester, const Key('tool-result-value')), '22,244.45');

    await tester.tap(find.byKey(const Key('loan-unit-years')));
    await tester.pump();
    expect(find.text('PKR for 720 months'), findsOneWidget);
  });

  testWidgets('amount edits recalculate live and an empty amount is zero', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.enterText(find.byKey(const Key('loan-amount')), '500000');
    await tester.pump();

    expect(fieldText(tester, const Key('loan-amount')), '500,000');
    expect(textOf(tester, const Key('tool-result-value')), '11,122.22');
    expect(textOf(tester, const Key('loan-total-payable')), '667,333.43');

    await tester.enterText(find.byKey(const Key('loan-amount')), '');
    await tester.pump();

    expect(fieldText(tester, const Key('loan-amount')), '');
    expect(textOf(tester, const Key('tool-result-value')), '0.00');
    expect(textOf(tester, const Key('loan-total-payable')), '0.00');
    expect(
      tester
          .widget<FractionallySizedBox>(
            find.byKey(const Key('loan-bar-principal')),
          )
          .widthFactor,
      0,
    );
  });

  testWidgets('the schedule lists every month and ends at a zero balance', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.ensureVisible(find.byKey(const Key('tool-action')));
    await tester.tap(find.byKey(const Key('tool-action')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('loan-schedule-sheet')), findsOneWidget);
    expect(find.text('Monthly schedule'), findsOneWidget);
    expect(find.text('Payment'), findsOneWidget);
    expect(find.text('Balance'), findsOneWidget);

    final Finder first = find.byKey(const Key('loan-schedule-row-1'));
    expect(first, findsOneWidget);
    expect(
      find.descendant(of: first, matching: find.text('10,000.00')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: first, matching: find.text('12,244.45')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: first, matching: find.text('987,755.55')),
      findsOneWidget,
    );

    final Finder scrollable = find.descendant(
      of: find.byKey(const Key('loan-schedule-sheet')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('loan-schedule-row-60')),
      300,
      scrollable: scrollable,
    );

    final Finder last = find.byKey(const Key('loan-schedule-row-60'));
    expect(
      find.descendant(of: last, matching: find.text('220.24')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: last, matching: find.text('22,024.21')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: last, matching: find.text('0.00')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('loan-schedule-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('loan-schedule-sheet')), findsNothing);
  });

  testWidgets('share copies a summary of the loan', (tester) async {
    await pumpPage(tester);
    final List<String> copied = captureClipboard(tester);

    await tester.tap(find.byTooltip('Share result'));
    await tester.pump();

    expect(copied, hasLength(1));
    expect(copied.single, contains('Loan / EMI'));
    expect(copied.single, contains('Loan amount: PKR 1,000,000.00'));
    expect(copied.single, contains('Interest rate: 12% per year'));
    expect(copied.single, contains('Tenure: 60 months'));
    expect(copied.single, contains('Monthly instalment: PKR 22,244.45'));
    expect(copied.single, contains('Total interest: PKR 334,666.86'));
    expect(copied.single, contains('Total payable: PKR 1,334,666.86'));
    expect(find.text('Copied'), findsOneWidget);
  });
}
