import 'package:calculator/core/engine/calc_result.dart';
import 'package:calculator/core/engine/angle_mode.dart';
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

  group('equals (§5)', () {
    test('evaluates, shows the result and stores Ans', () async {
      await press(<CalcKey>[
        CalcKey.digit5,
        CalcKey.add,
        CalcKey.digit3,
        CalcKey.equals,
      ]);

      expect(calc().result, Decimal.parse('8'));
      expect(calc().ans, Decimal.parse('8'));
      expect(calc().preview, isNull);
      expect(calc().error, isNull);
      expect(calc().justEvaluated, isTrue);
    });

    test('repeating = applies the last operation', () async {
      await press(<CalcKey>[
        CalcKey.digit5,
        CalcKey.add,
        CalcKey.digit3,
        CalcKey.equals,
        CalcKey.equals,
        CalcKey.equals,
      ]);

      expect(calc().result, Decimal.parse('14'));
      expect(calc().ans, Decimal.parse('14'));
    });

    test('repeating = uses the last operator and its operand', () async {
      await press(<CalcKey>[
        CalcKey.digit2,
        CalcKey.add,
        CalcKey.digit3,
        CalcKey.multiply,
        CalcKey.digit4,
        CalcKey.equals,
      ]);
      expect(calc().result, Decimal.parse('14'));

      await press(<CalcKey>[CalcKey.equals]);

      expect(calc().result, Decimal.parse('56'));
    });

    test('repeating = handles a negative operand', () async {
      await press(<CalcKey>[
        CalcKey.digit5,
        CalcKey.multiply,
        CalcKey.subtract,
        CalcKey.digit2,
        CalcKey.equals,
      ]);
      expect(calc().result, Decimal.parse('-10'));

      await press(<CalcKey>[CalcKey.equals]);

      expect(calc().result, Decimal.parse('20'));
    });

    test('persists Ans to the store', () async {
      await press(<CalcKey>[
        CalcKey.digit5,
        CalcKey.add,
        CalcKey.digit3,
        CalcKey.equals,
      ]);
      await controller().persistDone;

      expect(
        await store.getString(CalculatorController.ansKey),
        '8',
      );
    });

    test('a digit after = starts a new expression', () async {
      await press(<CalcKey>[
        CalcKey.digit5,
        CalcKey.add,
        CalcKey.digit3,
        CalcKey.equals,
        CalcKey.digit7,
      ]);

      expect(tokens(), <Token>[const NumberToken('7')]);
      expect(calc().result, isNull);
      expect(calc().error, isNull);
      expect(calc().preview, isNull);
      expect(calc().justEvaluated, isFalse);
    });

    test('a function after = starts a new expression', () async {
      await press(<CalcKey>[
        CalcKey.digit5,
        CalcKey.add,
        CalcKey.digit3,
        CalcKey.equals,
        CalcKey.sin,
        CalcKey.digit3,
        CalcKey.digit0,
      ]);

      expect(tokens(), <Token>[
        const FunctionToken('sin'),
        const NumberToken('30'),
      ]);
      expect(calc().preview, Decimal.parse('0.5'));
    });

    test('an operator after = continues from the result', () async {
      await press(<CalcKey>[
        CalcKey.digit5,
        CalcKey.add,
        CalcKey.digit3,
        CalcKey.equals,
        CalcKey.multiply,
        CalcKey.digit2,
      ]);

      expect(tokens(), <Token>[
        const NumberToken('8'),
        const OperatorToken(OperatorType.multiply),
        const NumberToken('2'),
      ]);
      expect(calc().preview, Decimal.parse('16'));

      await press(<CalcKey>[CalcKey.equals]);

      expect(calc().result, Decimal.parse('16'));
    });

    test('the Ans key after = inserts the result', () async {
      await press(<CalcKey>[
        CalcKey.digit5,
        CalcKey.add,
        CalcKey.digit3,
        CalcKey.equals,
        CalcKey.ans,
      ]);

      expect(tokens(), <Token>[const NumberToken('8')]);
    });

    test('a postfix after = applies to the result', () async {
      await press(<CalcKey>[
        CalcKey.digit5,
        CalcKey.add,
        CalcKey.digit3,
        CalcKey.equals,
        CalcKey.square,
      ]);

      expect(tokens(), <Token>[
        const NumberToken('8'),
        const PostfixToken(PostfixType.square),
      ]);
      expect(calc().preview, Decimal.parse('64'));
    });

    test('± after = toggles the result', () async {
      await press(<CalcKey>[
        CalcKey.digit5,
        CalcKey.add,
        CalcKey.digit3,
        CalcKey.equals,
        CalcKey.toggleSign,
      ]);

      expect(tokens(), <Token>[
        const LeftParenToken(),
        const UnaryToken(negative: true),
        const NumberToken('8'),
        const RightParenToken(),
      ]);
      expect(calc().preview, Decimal.parse('-8'));
    });

    test('an error keeps the buffer so it can be fixed', () async {
      await press(<CalcKey>[
        CalcKey.digit5,
        CalcKey.divide,
        CalcKey.digit0,
        CalcKey.equals,
      ]);

      expect(calc().error, CalcError.divideByZero);
      expect(calc().result, isNull);
      expect(calc().justEvaluated, isFalse);
      expect(tokens(), <Token>[
        const NumberToken('5'),
        const OperatorToken(OperatorType.divide),
        const NumberToken('0'),
      ]);

      await press(<CalcKey>[
        CalcKey.backspace,
        CalcKey.digit2,
        CalcKey.equals,
      ]);

      expect(calc().error, isNull);
      expect(calc().result, Decimal.parse('2.5'));
    });

    test('= on an empty buffer does nothing', () async {
      await press(<CalcKey>[CalcKey.equals]);

      expect(calc().result, isNull);
      expect(calc().error, isNull);
      expect(tokens(), isEmpty);
    });

    test('= on a bare number keeps it on a repeated =', () async {
      await press(<CalcKey>[
        CalcKey.digit5,
        CalcKey.equals,
        CalcKey.equals,
      ]);

      expect(calc().result, Decimal.parse('5'));
      expect(calc().ans, Decimal.parse('5'));
      expect(tokens(), <Token>[const NumberToken('5')]);
    });

    test('an incomplete expression reports a syntax error', () async {
      await press(<CalcKey>[
        CalcKey.digit2,
        CalcKey.add,
        CalcKey.equals,
      ]);

      expect(calc().error, CalcError.syntax);
      expect(tokens(), <Token>[
        const NumberToken('2'),
        const OperatorToken(OperatorType.add),
      ]);
    });
  });

  group('mode, angle and 2nd', () {
    test('the mode switcher updates and persists the mode', () async {
      await controller().restoreDone;

      controller().setMode(CalcMode.scientific);

      expect(calc().mode, CalcMode.scientific);
      await controller().persistDone;
      expect(
        await store.getString(CalculatorController.modeKey),
        'scientific',
      );
    });

    test('the mode is restored from the store', () async {
      await store.setString(CalculatorController.modeKey, 'programmer');

      await controller().restoreDone;

      expect(calc().mode, CalcMode.programmer);
    });

    test('an unknown stored mode falls back to Basic', () async {
      await store.setString(CalculatorController.modeKey, 'hex');

      await controller().restoreDone;

      expect(calc().mode, CalcMode.basic);
    });

    test('a mode chosen while loading is not overwritten', () async {
      await store.setString(CalculatorController.modeKey, 'scientific');
      final CalculatorController c = controller();

      c.setMode(CalcMode.programmer);
      await c.restoreDone;

      expect(calc().mode, CalcMode.programmer);
    });

    test('the angle mode drives the preview and =', () async {
      await press(<CalcKey>[
        CalcKey.sin,
        CalcKey.digit3,
        CalcKey.digit0,
      ]);
      expect(calc().preview, Decimal.parse('0.5'));

      controller().setAngleMode(AngleMode.rad);

      expect(calc().angleMode, AngleMode.rad);
      expect(
        calc().preview!.toDouble(),
        closeTo(-0.988031624092862, 1e-12),
      );

      controller().onKey(CalcKey.equals);

      expect(
        calc().result!.toDouble(),
        closeTo(-0.988031624092862, 1e-12),
      );
    });

    test('the angle mode does not persist until Settings owns it', () async {
      await controller().restoreDone;
      controller().setAngleMode(AngleMode.rad);
      await controller().persistDone;

      expect(calc().angleMode, AngleMode.rad);
      expect(await store.getString(CalculatorController.modeKey), isNull);
    });

    test('2nd swaps a function and turns itself off', () async {
      await press(<CalcKey>[CalcKey.digit0, CalcKey.decimalPoint, CalcKey.digit5]);

      controller().toggleSecond();
      expect(calc().second, isTrue);

      controller().onKey(CalcKey.sin);

      expect(tokens().last, const FunctionToken('sin⁻¹'));
      expect(calc().second, isFalse);
    });

    test('2nd stays on until a function is used', () async {
      await press(<CalcKey>[CalcKey.digit2]);
      controller().toggleSecond();

      controller().onKey(CalcKey.digit5);

      expect(calc().second, isTrue);
      expect(tokens(), <Token>[const NumberToken('25')]);
    });

    test('2nd reaches the other alternates, including ʸ√x', () async {
      await press(<CalcKey>[CalcKey.digit8]);
      controller().toggleSecond();
      controller().onKey(CalcKey.power);
      controller().onKey(CalcKey.digit3);

      expect(tokens(), <Token>[
        const NumberToken('8'),
        const OperatorToken(OperatorType.root),
        const NumberToken('3'),
      ]);
      expect(calc().preview, Decimal.fromInt(2));

      controller().onKey(CalcKey.equals);
      expect(calc().result, Decimal.fromInt(2));
    });

    test('the reciprocal key previews 1/x', () async {
      await press(<CalcKey>[CalcKey.digit4, CalcKey.reciprocal]);

      expect(tokens(), <Token>[
        const NumberToken('4'),
        const PostfixToken(PostfixType.reciprocal),
      ]);
      expect(calc().preview, Decimal.parse('0.25'));
    });

    test('openBrackets follows the buffer', () async {
      await press(<CalcKey>[
        CalcKey.leftParen,
        CalcKey.sin,
        CalcKey.digit3,
        CalcKey.digit0,
      ]);
      expect(calc().openBrackets, 2);

      await press(<CalcKey>[CalcKey.rightParen]);
      expect(calc().openBrackets, 1);

      await press(<CalcKey>[CalcKey.rightParen]);
      expect(calc().openBrackets, 0);
    });
  });

  group('clearSavedData', () {
    test('forgets Ans and the mode and returns to the launch state', () async {
      await store.setString(CalculatorController.ansKey, '12');
      await store.setString(CalculatorController.modeKey, 'scientific');
      await controller().restoreDone;
      expect(calc().ans, Decimal.fromInt(12));
      expect(calc().mode, CalcMode.scientific);

      await controller().clearSavedData();

      expect(calc(), isA<CalcState>());
      expect(calc().ans, Decimal.zero);
      expect(calc().mode, CalcMode.basic);
      expect(calc().buffer.isEmpty, isTrue);
      expect(calc().result, isNull);
      expect(await store.getString(CalculatorController.ansKey), isNull);
      expect(await store.getString(CalculatorController.modeKey), isNull);
    });

    test('a pending Ans write cannot reappear after the delete', () async {
      await press(<CalcKey>[CalcKey.digit7, CalcKey.equals]);

      await controller().clearSavedData();

      expect(await store.getString(CalculatorController.ansKey), isNull);
      expect(calc().ans, Decimal.zero);
    });
  });
}
