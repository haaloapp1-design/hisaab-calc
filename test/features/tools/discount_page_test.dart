import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/features/tools/pages/discount_page.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app() => ProviderScope(
    overrides: [kvStoreProvider.overrideWithValue(MemoryKvStore())],
    child: MaterialApp(theme: AppTheme.light(), home: const DiscountPage()),
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

  testWidgets('opens on 1000 with 20% off and 17% tax', (tester) async {
    await pumpPage(tester);

    expect(find.text('Discount and tax'), findsOneWidget);
    expect(textOf(tester, const Key('tool-result-value')), '936.00');
    expect(find.text('After 20% off and 17% tax'), findsOneWidget);
    expect(fieldText(tester, const Key('discount-price')), '1,000');
    expect(fieldText(tester, const Key('discount-percent')), '20');
    expect(fieldText(tester, const Key('discount-tax')), '17');

    expect(textOf(tester, const Key('discount-saved')), '200.00');
    expect(textOf(tester, const Key('discount-after')), '800.00');
    expect(textOf(tester, const Key('discount-tax-amount')), '136.00');
    expect(textOf(tester, const Key('discount-final')), '936.00');
  });

  testWidgets('a price edit recalculates every row', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byKey(const Key('discount-price')), '2000');
    await tester.pump();

    expect(fieldText(tester, const Key('discount-price')), '2,000');
    expect(textOf(tester, const Key('tool-result-value')), '1,872.00');
    expect(textOf(tester, const Key('discount-saved')), '400.00');
    expect(textOf(tester, const Key('discount-after')), '1,600.00');
    expect(textOf(tester, const Key('discount-tax-amount')), '272.00');
    expect(textOf(tester, const Key('discount-final')), '1,872.00');
  });

  testWidgets('zero discount and zero tax leave the price alone', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.enterText(find.byKey(const Key('discount-percent')), '0');
    await tester.pump();
    expect(textOf(tester, const Key('tool-result-value')), '1,170.00');
    expect(textOf(tester, const Key('discount-saved')), '0.00');
    expect(textOf(tester, const Key('discount-after')), '1,000.00');
    expect(textOf(tester, const Key('discount-tax-amount')), '170.00');

    await tester.enterText(find.byKey(const Key('discount-tax')), '0');
    await tester.pump();
    expect(textOf(tester, const Key('tool-result-value')), '1,000.00');
    expect(textOf(tester, const Key('discount-tax-amount')), '0.00');
    expect(textOf(tester, const Key('discount-final')), '1,000.00');
  });

  testWidgets('share copies the full breakdown', (tester) async {
    await pumpPage(tester);
    final List<String> copied = captureClipboard(tester);

    await tester.tap(find.byTooltip('Share result'));
    await tester.pump();

    expect(copied, hasLength(1));
    expect(copied.single, contains('Discount and tax'));
    expect(copied.single, contains('Price: 1,000.00'));
    expect(copied.single, contains('Discount: 20%'));
    expect(copied.single, contains('Tax: 17%'));
    expect(copied.single, contains('You save: 200.00'));
    expect(copied.single, contains('After discount: 800.00'));
    expect(copied.single, contains('Tax amount: 136.00'));
    expect(copied.single, contains('Final price: 936.00'));
  });

  testWidgets('the action copies the final price', (tester) async {
    await pumpPage(tester);
    final List<String> copied = captureClipboard(tester);

    await tester.ensureVisible(find.byKey(const Key('tool-action')));
    await tester.tap(find.byKey(const Key('tool-action')));
    await tester.pump();

    expect(copied, <String>['936.00']);
    expect(find.text('Copied'), findsOneWidget);
  });
}
