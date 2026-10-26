import 'package:calculator/core/engine/calc_result.dart';
import 'package:calculator/core/programmer/base_format.dart';
import 'package:calculator/core/programmer/prog_key.dart';
import 'package:calculator/core/programmer/word.dart';
import 'package:calculator/core/storage/kv_store_provider.dart';
import 'package:calculator/core/storage/memory_kv_store.dart';
import 'package:calculator/features/calculator/prog_state.dart';
import 'package:calculator/features/calculator/programmer_controller.dart';
import 'package:calculator/features/history/history_controller.dart';
import 'package:calculator/features/history/history_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [kvStoreProvider.overrideWithValue(MemoryKvStore())],
    );
  });

  tearDown(() => container.dispose());

  ProgrammerController controller() =>
      container.read(programmerProvider.notifier);
  ProgState prog() => container.read(programmerProvider);

  void press(List<ProgKey> keys) {
    final ProgrammerController c = controller();
    for (final ProgKey key in keys) {
      c.onKey(key);
    }
  }

  List<HistoryEntry> history() => container.read(historyProvider);

  test('starts on DEC, 32-bit, with zero', () {
    expect(prog().base, NumberBase.dec);
    expect(prog().size, WordSize.bits32);
    expect(prog().value.signed, BigInt.zero);
    expect(prog().source, '');
    expect(prog().expression, '');
    expect(prog().preview, isFalse);
  });

  test('typing digits previews the value in the active base', () {
    press(<ProgKey>[
      ProgKey.digit2,
      ProgKey.digit0,
      ProgKey.digit2,
      ProgKey.digit1,
    ]);

    expect(prog().source, '2021');
    expect(prog().value.signed, BigInt.from(2021));
    expect(prog().preview, isTrue);
  });

  test('reads hex digits when HEX is the input base', () {
    controller().selectBase(NumberBase.hex);
    press(<ProgKey>[ProgKey.digitF, ProgKey.digitF]);

    expect(prog().base, NumberBase.hex);
    expect(prog().source, 'FF');
    expect(prog().value.signed, BigInt.from(255));
  });

  test('switching base converts the value, not the text', () {
    press(<ProgKey>[
      ProgKey.digit2,
      ProgKey.digit0,
      ProgKey.digit2,
      ProgKey.digit1,
    ]);

    controller().selectBase(NumberBase.hex);
    expect(prog().source, '7E5');
    expect(prog().value.signed, BigInt.from(2021));

    controller().selectBase(NumberBase.bin);
    expect(prog().source, '0111 1110 0101');
    expect(prog().value.signed, BigInt.from(2021));

    controller().selectBase(NumberBase.dec);
    expect(prog().source, '2021');
    expect(prog().value.signed, BigInt.from(2021));
  });

  test('switching base on an empty source keeps it empty', () {
    controller().selectBase(NumberBase.hex);

    expect(prog().source, '');
    expect(prog().value.signed, BigInt.zero);
  });

  test('operators preview live and = commits the result', () {
    press(<ProgKey>[ProgKey.digit5, ProgKey.and, ProgKey.digit3]);
    expect(prog().source, '5 AND 3');
    expect(prog().value.signed, BigInt.one);

    press(<ProgKey>[ProgKey.equals]);

    expect(prog().justEvaluated, isTrue);
    expect(prog().expression, '');
    expect(prog().value.signed, BigInt.one);
    expect(history().single.expression, '5 AND 3');
    expect(history().single.result, '1');
    expect(history().single.mode, HistoryMode.programmer);
  });

  test('= on an empty source is a no-op', () {
    press(<ProgKey>[ProgKey.equals]);

    expect(prog().source, '');
    expect(prog().value.signed, BigInt.zero);
    expect(history(), isEmpty);
  });

  test('a failed = reports the error and keeps the source', () {
    press(<ProgKey>[
      ProgKey.digit5,
      ProgKey.divide,
      ProgKey.digit0,
      ProgKey.equals,
    ]);

    expect(prog().error, CalcError.divideByZero);
    expect(prog().source, '5 ÷ 0');
    expect(prog().justEvaluated, isFalse);
    expect(history(), isEmpty);

    press(<ProgKey>[ProgKey.digit2]);
    expect(prog().error, isNull);
  });

  test('AC clears the source, the value and the error', () {
    press(<ProgKey>[
      ProgKey.digit5,
      ProgKey.divide,
      ProgKey.digit0,
      ProgKey.equals,
    ]);
    press(<ProgKey>[ProgKey.clear]);

    expect(prog().source, '');
    expect(prog().value.signed, BigInt.zero);
    expect(prog().error, isNull);
  });

  test('backspace removes a whole keyword', () {
    press(<ProgKey>[ProgKey.digit5, ProgKey.and]);
    expect(prog().source, '5 AND ');

    press(<ProgKey>[ProgKey.backspace]);

    expect(prog().source, '5');
    expect(prog().value.signed, BigInt.from(5));
  });

  test('± toggles the sign of the number being typed', () {
    press(<ProgKey>[ProgKey.digit5, ProgKey.toggleSign]);
    expect(prog().source, '−5');
    expect(prog().value.signed, BigInt.from(-5));

    press(<ProgKey>[ProgKey.toggleSign]);
    expect(prog().source, '5');
    expect(prog().value.signed, BigInt.from(5));
  });

  test('NOT wraps the next operand', () {
    press(<ProgKey>[ProgKey.not, ProgKey.digit5]);

    expect(prog().source, 'NOT 5');
    expect(prog().value.signed, BigInt.from(-6));
  });

  test('a digit after = starts a new expression', () {
    press(<ProgKey>[
      ProgKey.digit5,
      ProgKey.add,
      ProgKey.digit3,
      ProgKey.equals,
      ProgKey.digit7,
    ]);

    expect(prog().source, '7');
    expect(prog().value.signed, BigInt.from(7));
    expect(prog().justEvaluated, isFalse);
  });

  test('an operator after = continues from the result', () {
    press(<ProgKey>[
      ProgKey.digit5,
      ProgKey.add,
      ProgKey.digit3,
      ProgKey.equals,
      ProgKey.multiply,
      ProgKey.digit2,
    ]);

    expect(prog().source, '8 × 2');
    expect(prog().value.signed, BigInt.from(16));
  });

  test('word size re-masks the value and reports truncation', () {
    press(<ProgKey>[ProgKey.digit2, ProgKey.digit5, ProgKey.digit5]);

    expect(controller().setSize(WordSize.bits8), isTrue);
    expect(prog().size, WordSize.bits8);
    expect(prog().value.signed, BigInt.from(-1));

    expect(controller().setSize(WordSize.bits16), isFalse);
    expect(prog().size, WordSize.bits16);
    expect(prog().value.signed, BigInt.from(-1));

    press(<ProgKey>[ProgKey.clear, ProgKey.digit5]);
    expect(controller().setSize(WordSize.bits8), isFalse);
  });

  test('the same width is not a change', () {
    expect(controller().setSize(WordSize.bits32), isFalse);
  });

  test('results wrap in the chosen width', () {
    controller().setSize(WordSize.bits8);
    press(<ProgKey>[
      ProgKey.digit1,
      ProgKey.digit2,
      ProgKey.digit7,
      ProgKey.add,
      ProgKey.digit1,
      ProgKey.equals,
    ]);

    expect(prog().value.signed, BigInt.from(-128));
  });

  test('history keeps the result in the active base', () {
    controller().selectBase(NumberBase.hex);
    press(<ProgKey>[
      ProgKey.digitF,
      ProgKey.digitF,
      ProgKey.add,
      ProgKey.digit1,
      ProgKey.equals,
    ]);

    expect(prog().value.signed, BigInt.from(256));
    expect(history().single.expression, 'FF + 1');
    expect(history().single.result, '100');
    expect(history().single.mode, HistoryMode.programmer);
  });

  test('the DEC history result follows the Settings separator', () {
    press(<ProgKey>[
      ProgKey.digit2,
      ProgKey.digit0,
      ProgKey.digit2,
      ProgKey.digit1,
      ProgKey.equals,
    ]);

    expect(history().single.result, '2,021');
  });
}
