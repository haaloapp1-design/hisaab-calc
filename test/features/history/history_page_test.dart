import 'package:calculator/core/engine/formatter.dart';
import 'package:calculator/core/memory/memory_slots.dart';
import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/features/calculator/calc_state.dart';
import 'package:calculator/features/calculator/calculator_controller.dart';
import 'package:calculator/core/input/calc_key.dart';
import 'package:calculator/features/history/history_controller.dart';
import 'package:calculator/features/history/history_entry.dart';
import 'package:calculator/features/history/history_log.dart';
import 'package:calculator/features/history/history_page.dart';
import 'package:calculator/features/history/memory_controller.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime.now();
  final DateTime yesterday = DateTime(now.year, now.month, now.day - 1, 12);

  HistoryEntry row(
    String expression,
    String result, {
    HistoryMode mode = HistoryMode.basic,
    DateTime? at,
  }) => HistoryEntry.create(
    expression: expression,
    result: result,
    mode: mode,
    createdAt: at ?? now.subtract(const Duration(minutes: 1)),
  );

  late ProviderContainer container;

  void boot({List<HistoryEntry>? stored, List<Decimal?>? memory}) {
    container = ProviderContainer(
      overrides: [
        kvStoreProvider.overrideWithValue(
          MemoryKvStore(<String, String>{
            if (stored != null)
              HistoryController.key: HistoryLog.encode(stored),
            if (memory != null)
              MemoryController.key: MemorySlots.encode(memory),
          }),
        ),
      ],
    );
    addTearDown(container.dispose);
  }

  void designSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget app({VoidCallback? onOpenCalculator}) => UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: HistoryPage(onOpenCalculator: onOpenCalculator)),
    ),
  );

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

  group('History tab', () {
    testWidgets('groups entries under Today and Yesterday', (tester) async {
      designSurface(tester);
      boot(
        stored: <HistoryEntry>[
          row('1800 + 21', '1,821'),
          row('2598 − 2574 + 985', '1,009'),
          row('5 + 3', '8', at: yesterday),
        ],
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('1800 + 21'), findsOneWidget);
      expect(find.text('1,821'), findsOneWidget);
      expect(find.text('5 + 3'), findsOneWidget);
      expect(find.byKey(const Key('history-empty')), findsNothing);
    });

    testWidgets('shows the empty state when nothing is saved', (tester) async {
      designSurface(tester);
      boot();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('history-empty')), findsOneWidget);
      expect(find.text('No saved calculations yet'), findsOneWidget);
    });

    testWidgets('a tap loads the entry and switches to the calculator', (
      tester,
    ) async {
      designSurface(tester);
      bool opened = false;
      boot(
        stored: <HistoryEntry>[
          row('sin(30) + 1', '1.5', mode: HistoryMode.scientific),
        ],
      );
      await tester.pumpWidget(app(onOpenCalculator: () => opened = true));
      await tester.pumpAndSettle();
      await tester.tap(find.text('sin(30) + 1'));
      await tester.pump();

      final CalcState calc = container.read(calculatorProvider);
      expect(opened, isTrue);
      expect(calc.mode, CalcMode.scientific);
      expect(formatExpression(calc.buffer.tokens), 'sin(30) + 1');
    });

    testWidgets('search filters by expression or result', (tester) async {
      designSurface(tester);
      boot(
        stored: <HistoryEntry>[row('1800 + 21', '1,821'), row('5 + 3', '8')],
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('blue-header-action')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('history-search')), '1800');
      await tester.pump();

      expect(find.text('1800 + 21'), findsOneWidget);
      expect(find.text('5 + 3'), findsNothing);

      await tester.enterText(find.byKey(const Key('history-search')), 'zzz');
      await tester.pump();
      expect(find.text('No matching calculations'), findsOneWidget);

      await tester.tap(find.byKey(const Key('history-search-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('history-search')), findsNothing);
      expect(find.text('5 + 3'), findsOneWidget);
    });

    testWidgets('Copy all puts every visible entry on the clipboard', (
      tester,
    ) async {
      designSurface(tester);
      final List<String> copied = captureClipboard(tester);
      boot(
        stored: <HistoryEntry>[row('1800 + 21', '1,821'), row('5 + 3', '8')],
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('history-copy-all')));
      await tester.pumpAndSettle();

      expect(copied, <String>['1800 + 21 = 1,821\n5 + 3 = 8']);
      expect(find.text('History copied'), findsOneWidget);
    });

    testWidgets('long-press offers copy and delete', (tester) async {
      designSurface(tester);
      final List<String> copied = captureClipboard(tester);
      boot(stored: <HistoryEntry>[row('1800 + 21', '1,821')]);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.longPress(find.text('1800 + 21'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('history-entry-copy')), findsOneWidget);
      expect(find.byKey(const Key('history-entry-delete')), findsOneWidget);

      await tester.tap(find.byKey(const Key('history-entry-copy')));
      await tester.pumpAndSettle();
      expect(copied, <String>['1800 + 21 = 1,821']);

      await tester.longPress(find.text('1800 + 21'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('history-entry-delete')));
      await tester.pumpAndSettle();

      expect(container.read(historyProvider), isEmpty);
      expect(find.text('1800 + 21'), findsNothing);
    });

    testWidgets('Clear history asks first and then deletes everything', (
      tester,
    ) async {
      designSurface(tester);
      boot(
        stored: <HistoryEntry>[row('1800 + 21', '1,821'), row('5 + 3', '8')],
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('history-clear')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('history-clear-dialog')), findsOneWidget);

      await tester.tap(find.byKey(const Key('history-clear-cancel')));
      await tester.pumpAndSettle();
      expect(container.read(historyProvider), hasLength(2));

      await tester.tap(find.byKey(const Key('history-clear')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('history-clear-confirm')));
      await tester.pumpAndSettle();

      expect(container.read(historyProvider), isEmpty);
      expect(find.text('No saved calculations yet'), findsOneWidget);
      expect(
        await container.read(kvStoreProvider).getString(HistoryController.key),
        isNull,
      );
    });
  });

  group('Memory tab', () {
    testWidgets('stores the current value from its empty state', (
      tester,
    ) async {
      designSurface(tester);
      boot();
      container.read(calculatorProvider.notifier).onKey(CalcKey.digit5);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Memory'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('memory-empty')), findsOneWidget);
      expect(find.byKey(const Key('history-empty')), findsNothing);

      await tester.tap(find.byKey(const Key('memory-empty-store')));
      await tester.pumpAndSettle();

      expect(container.read(memoryProvider)[0], Decimal.fromInt(5));
      expect(find.byKey(const Key('memory-slot-M1')), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.byKey(const Key('memory-empty')), findsNothing);
    });

    testWidgets('shows the used slots with their MR, M+ and M- buttons', (
      tester,
    ) async {
      designSurface(tester);
      bool opened = false;
      boot(memory: <Decimal?>[Decimal.fromInt(10), Decimal.fromInt(20)]);
      await tester.pumpWidget(app(onOpenCalculator: () => opened = true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Memory'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('memory-slot-M1')), findsOneWidget);
      expect(find.byKey(const Key('memory-slot-M2')), findsOneWidget);
      expect(find.byKey(const Key('memory-slot-M3')), findsNothing);
      expect(find.byKey(const Key('memory-recall-M1')), findsOneWidget);
      expect(find.byKey(const Key('memory-add-M2')), findsOneWidget);
      expect(find.byKey(const Key('memory-subtract-M2')), findsOneWidget);

      await tester.tap(find.byKey(const Key('memory-recall-M1')));
      await tester.pump();

      expect(opened, isTrue);
      expect(
        container.read(calculatorProvider).displayValue,
        Decimal.fromInt(10),
      );
      expect(
        formatExpression(container.read(calculatorProvider).buffer.tokens),
        '10',
      );

      // The calculator now shows 10, so M2 is 20 + 10 after M+.
      await tester.tap(find.byKey(const Key('memory-add-M2')));
      await tester.pump();
      expect(container.read(memoryProvider)[1], Decimal.fromInt(30));

      await tester.tap(find.byKey(const Key('memory-subtract-M2')));
      await tester.pump();
      expect(container.read(memoryProvider)[1], Decimal.fromInt(20));
    });

    testWidgets('a recall after = starts a new expression', (tester) async {
      designSurface(tester);
      boot(memory: <Decimal?>[Decimal.parse('2.5')]);
      container
        ..read(calculatorProvider.notifier).onKey(CalcKey.digit5)
        ..read(calculatorProvider.notifier).onKey(CalcKey.equals);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Memory'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('memory-recall-M1')));
      await tester.pump();

      expect(container.read(calculatorProvider).justEvaluated, isFalse);
      expect(
        formatExpression(container.read(calculatorProvider).buffer.tokens),
        '2.5',
      );
    });
  });
}
