import 'package:calculator/core/engine/token.dart';
import 'package:calculator/core/input/calc_key.dart';
import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/features/calculator/calc_state.dart';
import 'package:calculator/features/calculator/calculator_controller.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemoryKvStore store;
  late ProviderContainer container;

  setUp(() {
    store = MemoryKvStore();
    container = ProviderContainer(
      overrides: [kvStoreProvider.overrideWithValue(store)],
    );
  });

  tearDown(() => container.dispose());

  CalculatorController controller() =>
      container.read(calculatorProvider.notifier);
  CalcState calc() => container.read(calculatorProvider);

  /// Waits for the persisted Ans, then taps [keys] in order.
  Future<void> press(List<CalcKey> keys) async {
    final CalculatorController c = controller();
    await c.restoreDone;
    for (final CalcKey key in keys) {
      c.onKey(key);
    }
  }

  List<Token> tokens() => calc().buffer.tokens;

  group('buffer editing through onKey', () {
    test('digits, dot and operators build the typed tokens', () async {
      await press(<CalcKey>[
        CalcKey.digit1,
        CalcKey.digit2,
        CalcKey.decimalPoint,
        CalcKey.digit5,
        CalcKey.add,
        CalcKey.digit3,
      ]);

      expect(tokens(), <Token>[
        const NumberToken('12.5'),
        const OperatorToken(OperatorType.add),
        const NumberToken('3'),
      ]);
    });

    test('clear empties the buffer and the preview', () async {
      await press(<CalcKey>[
        CalcKey.digit2,
        CalcKey.add,
        CalcKey.digit3,
        CalcKey.clear,
      ]);

      expect(calc().buffer.isEmpty, isTrue);
      expect(calc().preview, isNull);
    });

    test('backspace refreshes the preview', () async {
      await press(<CalcKey>[
        CalcKey.digit2,
        CalcKey.add,
        CalcKey.digit3,
        CalcKey.digit4,
      ]);
      expect(calc().preview, Decimal.parse('36'));

      controller().onKey(CalcKey.backspace);
      expect(tokens().last, const NumberToken('3'));
      expect(calc().preview, Decimal.parse('5'));

      controller().onKey(CalcKey.backspace);
      expect(tokens().last, const OperatorToken(OperatorType.add));
      expect(calc().preview, isNull);
    });

    test('a stray ) is ignored', () async {
      await press(<CalcKey>[CalcKey.rightParen]);

      expect(calc().buffer.isEmpty, isTrue);
    });
  });

  group('live preview (§5)', () {
    test('shows the result of an operator expression', () async {
      await press(<CalcKey>[
        CalcKey.digit2,
        CalcKey.add,
        CalcKey.digit3,
      ]);

      expect(calc().preview, Decimal.parse('5'));
    });

    test('is empty for a plain number', () async {
      await press(<CalcKey>[CalcKey.digit4, CalcKey.digit2]);

      expect(calc().preview, isNull);
    });

    test('is empty while the expression is incomplete', () async {
      await press(<CalcKey>[CalcKey.digit2, CalcKey.add]);

      expect(calc().preview, isNull);
    });

    test('never shows an error', () async {
      await press(<CalcKey>[
        CalcKey.digit5,
        CalcKey.divide,
        CalcKey.digit0,
      ]);

      expect(calc().preview, isNull);
    });

    test('uses exact Decimal arithmetic', () async {
      await press(<CalcKey>[
        CalcKey.digit0,
        CalcKey.decimalPoint,
        CalcKey.digit1,
        CalcKey.add,
        CalcKey.digit0,
        CalcKey.decimalPoint,
        CalcKey.digit2,
      ]);

      expect(calc().preview, Decimal.parse('0.3'));
    });

    test('auto-closes missing brackets', () async {
      await press(<CalcKey>[
        CalcKey.sin,
        CalcKey.digit3,
        CalcKey.digit0,
      ]);

      expect(calc().preview, Decimal.parse('0.5'));
    });

    test('shows implicit multiplication', () async {
      await press(<CalcKey>[
        CalcKey.digit2,
        CalcKey.leftParen,
        CalcKey.digit3,
      ]);

      expect(calc().preview, Decimal.parse('6'));
    });

    test('previews a function typed after a value', () async {
      await press(<CalcKey>[
        CalcKey.digit2,
        CalcKey.sin,
        CalcKey.digit3,
        CalcKey.digit0,
      ]);

      expect(tokens(), <Token>[
        const NumberToken('2'),
        const OperatorToken(OperatorType.multiply, implicit: true),
        const FunctionToken('sin'),
        const NumberToken('30'),
      ]);
      expect(calc().preview, Decimal.parse('1'));
    });

    test('previews postfix keys', () async {
      await press(<CalcKey>[
        CalcKey.digit5,
        CalcKey.factorial,
      ]);

      expect(calc().preview, Decimal.parse('120'));
    });

    test('previews the power key', () async {
      await press(<CalcKey>[
        CalcKey.digit2,
        CalcKey.power,
        CalcKey.digit3,
      ]);

      expect(calc().preview, Decimal.parse('8'));
    });

    test('previews a signed number', () async {
      await press(<CalcKey>[CalcKey.digit5, CalcKey.toggleSign]);

      expect(tokens(), <Token>[
        const LeftParenToken(),
        const UnaryToken(negative: true),
        const NumberToken('5'),
        const RightParenToken(),
      ]);
      expect(calc().preview, Decimal.parse('-5'));
    });

    test('previews a constant after a value', () async {
      await press(<CalcKey>[
        CalcKey.digit2,
        CalcKey.pi,
      ]);

      expect(calc().preview, isNotNull);
      expect(calc().preview!.toDouble(), closeTo(6.283185307, 1e-9));
    });
  });

  group('Ans (§5, §9)', () {
    test('is zero when the store has no answer', () async {
      await press(<CalcKey>[CalcKey.add]);

      expect(calc().ans, Decimal.zero);
      expect(tokens(), <Token>[
        const NumberToken('0'),
        const OperatorToken(OperatorType.add),
      ]);
    });

    test('is restored from the store', () async {
      await store.setString(CalculatorController.ansKey, '8');
      final CalculatorController c = controller();
      await c.restoreDone;

      expect(calc().ans, Decimal.parse('8'));
    });

    test('starts an operator expression when the buffer is empty', () async {
      await store.setString(CalculatorController.ansKey, '8');
      await press(<CalcKey>[
        CalcKey.multiply,
        CalcKey.digit2,
      ]);

      expect(tokens(), <Token>[
        const NumberToken('8'),
        const OperatorToken(OperatorType.multiply),
        const NumberToken('2'),
      ]);
      expect(calc().preview, Decimal.parse('16'));
    });

    test('a negative answer is bracketed', () async {
      await store.setString(CalculatorController.ansKey, '-5');
      await press(<CalcKey>[CalcKey.add]);

      expect(tokens(), <Token>[
        const LeftParenToken(),
        const UnaryToken(negative: true),
        const NumberToken('5'),
        const RightParenToken(),
        const OperatorToken(OperatorType.add),
      ]);
    });

    test('the Ans key inserts the loaded answer', () async {
      await store.setString(CalculatorController.ansKey, '8');
      await press(<CalcKey>[
        CalcKey.digit2,
        CalcKey.add,
        CalcKey.ans,
      ]);

      expect(tokens(), <Token>[
        const NumberToken('2'),
        const OperatorToken(OperatorType.add),
        const NumberToken('8'),
      ]);
      expect(calc().preview, Decimal.parse('10'));
    });

    test('keeps keys typed while Ans is still loading', () async {
      await store.setString(CalculatorController.ansKey, '8');
      final CalculatorController c = controller();

      c.onKey(CalcKey.digit5);
      await c.restoreDone;

      expect(calc().buffer.tokens, <Token>[const NumberToken('5')]);
      expect(calc().ans, Decimal.parse('8'));
    });

    test('clear keeps Ans', () async {
      await store.setString(CalculatorController.ansKey, '8');
      await press(<CalcKey>[
        CalcKey.digit5,
        CalcKey.clear,
      ]);

      expect(calc().ans, Decimal.parse('8'));
    });
  });
}
