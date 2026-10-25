import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/engine/angle_mode.dart';
import '../../core/engine/calc_engine.dart';
import '../../core/engine/calc_result.dart';
import '../../core/engine/token.dart';
import '../../core/input/calc_key.dart';
import '../../core/input/input_buffer.dart';
import '../../core/input/last_operation.dart';
import '../../core/input/value_tokens.dart';
import '../../core/storage/kv_store_provider.dart';
import 'calc_state.dart';

/// The calculator screen's state machine: `CalcKey` → [InputBuffer] → preview,
/// `=` → result (BUSINESS_LOGIC §5, ARCHITECTURE "State").
///
/// It owns no maths: every value comes from [CalcEngine].
class CalculatorController extends Notifier<CalcState> {
  /// §9 the persisted `Ans` lives under this KvStore key.
  static const String ansKey = 'ans_v1';

  Future<void>? _restore;
  Future<void> _lastPersist = Future<void>.value();
  bool _ansChanged = false;

  @override
  CalcState build() {
    // `Ans` is persisted, so start from the store (async) while the first
    // frame shows 0; tests await [restoreDone].
    _restore ??= _restoreAns();
    return CalcState(ans: Decimal.zero);
  }

  /// Completes when the persisted `Ans` has been loaded. Test hook.
  Future<void> get restoreDone => _restore ?? Future<void>.value();

  /// Completes when the last `Ans` write has finished. Test hook.
  Future<void> get persistDone => _lastPersist;

  /// Handles one key.
  void onKey(CalcKey key) {
    if (key == CalcKey.equals) {
      _equals();
      return;
    }

    final InputBuffer start = _startBuffer(key);

    final int? digit = key.digit;
    if (digit != null) {
      _set(start.appendDigit(digit));
      return;
    }

    final OperatorType? operatorType = key.operatorType;
    if (operatorType != null) {
      _set(_appendOperator(start, operatorType));
      return;
    }

    final String? function = key.functionName;
    if (function != null) {
      _set(start.appendFunction(function));
      return;
    }

    final PostfixType? postfix = key.postfixType;
    if (postfix != null) {
      _set(start.appendPostfix(postfix));
      return;
    }

    final MathConstant? constant = key.constant;
    if (constant != null) {
      _set(start.appendConstant(constant));
      return;
    }

    final InputBuffer next = switch (key) {
      CalcKey.decimalPoint => start.appendDecimalPoint(),
      CalcKey.leftParen => start.appendLeftParen(),
      CalcKey.rightParen => start.appendRightParen(),
      CalcKey.toggleSign => start.toggleSign(),
      CalcKey.ans => start.appendValueTokens(valueTokens(state.ans)),
      CalcKey.backspace => start.backspace(),
      CalcKey.clear => const InputBuffer.empty(),
      _ => start,
    };
    _set(next);
  }

  /// §5 after `=`: a digit/function/constant starts a new expression, while an
  /// operator/`±`/postfix continues from the result. `⌫` and `C` just clear.
  InputBuffer _startBuffer(CalcKey key) {
    if (!state.justEvaluated) {
      return state.buffer;
    }
    final bool startsNew =
        key.digit != null ||
        key == CalcKey.decimalPoint ||
        key.functionName != null ||
        key.constant != null ||
        key == CalcKey.leftParen ||
        key == CalcKey.ans ||
        key == CalcKey.backspace ||
        key == CalcKey.clear;
    if (startsNew) {
      return const InputBuffer.empty();
    }
    final bool continues =
        key.operatorType != null ||
        key.postfixType != null ||
        key == CalcKey.toggleSign;
    return continues ? InputBuffer(valueTokens(state.ans)) : state.buffer;
  }

  /// A buffer edit: the previous `=` result/error is no longer shown.
  void _set(InputBuffer buffer) {
    state = CalcState(
      buffer: buffer,
      preview: _previewFor(buffer),
      ans: state.ans,
    );
  }

  /// §5 preview rule: only when the buffer holds an operator or a function,
  /// only on success — errors and incomplete input show nothing.
  Decimal? _previewFor(InputBuffer buffer) {
    if (!buffer.tokens.any(_isOperatorOrFunction)) {
      return null;
    }
    final CalcResult result = CalcEngine.evaluate(
      buffer.tokens,
      angleMode: AngleMode.deg,
    );
    return result is Success ? result.value : null;
  }

  static bool _isOperatorOrFunction(Token token) =>
      token is OperatorToken ||
      token is FunctionToken ||
      token is UnaryToken ||
      token is PostfixToken;

  /// §5 operator row: an empty buffer starts from `Ans` (or `0`).
  InputBuffer _appendOperator(InputBuffer buffer, OperatorType operatorType) {
    final InputBuffer start = buffer.isEmpty
        ? InputBuffer(valueTokens(state.ans))
        : buffer;
    return start.appendOperator(operatorType);
  }

  /// §5 `=` row: evaluate, or repeat the last operation on a second `=`.
  void _equals() {
    if (state.justEvaluated) {
      final LastOperation? last = state.lastOperation;
      if (last == null) {
        return;
      }
      _applyResult(
        last.apply(state.result ?? state.ans),
        buffer: state.buffer,
        lastOperation: last,
      );
      return;
    }

    final InputBuffer buffer = state.buffer;
    if (buffer.isEmpty) {
      return;
    }
    _applyResult(
      CalcEngine.evaluate(buffer.tokens, angleMode: AngleMode.deg),
      buffer: buffer,
      lastOperation: LastOperation.of(buffer.tokens),
    );
  }

  void _applyResult(
    CalcResult result, {
    required InputBuffer buffer,
    LastOperation? lastOperation,
  }) {
    switch (result) {
      case Success(:final Decimal value):
        state = CalcState(
          buffer: buffer,
          ans: value,
          result: value,
          justEvaluated: true,
          lastOperation: lastOperation,
        );
        _saveAns(value);
      case Failure(:final CalcError error):
        // §5: show the message and keep the buffer so the user can fix it.
        state = CalcState(buffer: buffer, ans: state.ans, error: error);
    }
  }

  void _saveAns(Decimal value) {
    _ansChanged = true;
    final String text = value.toString();
    final store = ref.read(kvStoreProvider);
    _lastPersist = _lastPersist.then((_) => store.setString(ansKey, text));
  }

  Future<void> _restoreAns() async {
    final String? raw = await ref.read(kvStoreProvider).getString(ansKey);
    final Decimal? value = raw == null ? null : Decimal.tryParse(raw);
    if (value == null || _ansChanged || !ref.mounted) {
      return;
    }
    state = CalcState(
      buffer: state.buffer,
      preview: state.preview,
      ans: value,
    );
  }
}

/// ARCHITECTURE "State": mode, buffer tokens, preview, result, error, 2nd and
/// Ans. T24/T25 add mode, 2nd and the settings-driven angle mode.
final NotifierProvider<CalculatorController, CalcState> calculatorProvider =
    NotifierProvider<CalculatorController, CalcState>(
      CalculatorController.new,
      name: 'calculator',
    );
