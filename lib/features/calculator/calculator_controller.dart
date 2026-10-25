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

  /// SPEC §1 the remembered Basic / Scientific / Programmer choice.
  static const String modeKey = 'mode_v1';

  Future<void>? _restore;
  Future<void> _lastPersist = Future<void>.value();
  bool _ansChanged = false;
  bool _modeChanged = false;

  @override
  CalcState build() {
    // `Ans` and the mode are persisted, so start from the store (async) while
    // the first frame shows 0/Basic; tests await [restoreDone].
    _restore ??= _restoreState();
    return CalcState(ans: Decimal.zero);
  }

  /// Completes when the persisted `Ans` and mode have been loaded. Test hook.
  Future<void> get restoreDone => _restore ?? Future<void>.value();

  /// Completes when the last persisted write has finished. Test hook.
  Future<void> get persistDone => _lastPersist;

  /// Handles one key.
  void onKey(CalcKey key) {
    // SPEC §1.3: when 2nd is on, the next function key uses its alternate and
    // 2nd turns itself off (BUSINESS_LOGIC §5). Non-function keys keep it on.
    CalcKey effective = key;
    bool usedSecond = false;
    if (state.second) {
      final CalcKey? alternate = _secondAlternate(key);
      if (alternate != null) {
        effective = alternate;
        usedSecond = true;
      }
    }

    if (effective == CalcKey.equals) {
      _equals();
      return;
    }

    final InputBuffer start = _startBuffer(effective);
    final bool second = usedSecond ? false : state.second;

    final int? digit = effective.digit;
    if (digit != null) {
      _set(start.appendDigit(digit), second: second);
      return;
    }

    final OperatorType? operatorType = effective.operatorType;
    if (operatorType != null) {
      _set(_appendOperator(start, operatorType), second: second);
      return;
    }

    final String? function = effective.functionName;
    if (function != null) {
      _set(start.appendFunction(function), second: second);
      return;
    }

    final PostfixType? postfix = effective.postfixType;
    if (postfix != null) {
      _set(start.appendPostfix(postfix), second: second);
      return;
    }

    final MathConstant? constant = effective.constant;
    if (constant != null) {
      _set(start.appendConstant(constant), second: second);
      return;
    }

    final InputBuffer next = switch (effective) {
      CalcKey.decimalPoint => start.appendDecimalPoint(),
      CalcKey.leftParen => start.appendLeftParen(),
      CalcKey.rightParen => start.appendRightParen(),
      CalcKey.toggleSign => start.toggleSign(),
      CalcKey.ans => start.appendValueTokens(valueTokens(state.ans)),
      CalcKey.backspace => start.backspace(),
      CalcKey.clear => const InputBuffer.empty(),
      _ => start,
    };
    _set(next, second: second);
  }

  /// SPEC §1.3 toggles the scientific alternate key set.
  void toggleSecond() => state = state.copyWith(second: !state.second);

  /// SPEC §1.3 the DEG/RAD chip above the display.
  void setAngleMode(AngleMode angleMode) {
    if (state.angleMode == angleMode) {
      return;
    }
    state = CalcState(
      buffer: state.buffer,
      preview: _previewFor(state.buffer, angleMode: angleMode),
      ans: state.ans,
      result: state.result,
      error: state.error,
      justEvaluated: state.justEvaluated,
      lastOperation: state.lastOperation,
      mode: state.mode,
      angleMode: angleMode,
      second: state.second,
    );
  }

  /// The segmented mode switcher; the choice survives a relaunch.
  void setMode(CalcMode mode) {
    if (state.mode == mode) {
      return;
    }
    _modeChanged = true;
    state = state.copyWith(mode: mode);
    final store = ref.read(kvStoreProvider);
    _lastPersist = _lastPersist.then((_) => store.setString(modeKey, mode.name));
  }

  /// SPEC §3 "Clear all saved data": forget the persisted `Ans` and mode and
  /// return the calculator to its launch state.
  Future<void> clearSavedData() async {
    _ansChanged = true;
    _modeChanged = true;
    await _lastPersist;
    final store = ref.read(kvStoreProvider);
    await store.remove(ansKey);
    await store.remove(modeKey);
    if (!ref.mounted) {
      return;
    }
    state = CalcState();
  }

  /// SPEC §1.3 alternates: sin→sin⁻¹ … x²→x³, xʸ→ʸ√x.
  static CalcKey? _secondAlternate(CalcKey key) => switch (key) {
    CalcKey.sin => CalcKey.sinInverse,
    CalcKey.cos => CalcKey.cosInverse,
    CalcKey.tan => CalcKey.tanInverse,
    CalcKey.square => CalcKey.cube,
    CalcKey.sqrt => CalcKey.cbrt,
    CalcKey.ln => CalcKey.exp,
    CalcKey.log => CalcKey.tenPow,
    CalcKey.power => CalcKey.root,
    _ => null,
  };

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
  void _set(InputBuffer buffer, {required bool second}) {
    state = CalcState(
      buffer: buffer,
      preview: _previewFor(buffer),
      ans: state.ans,
      mode: state.mode,
      angleMode: state.angleMode,
      second: second,
    );
  }

  /// §5 preview rule: only when the buffer holds an operator or a function,
  /// only on success — errors and incomplete input show nothing.
  Decimal? _previewFor(InputBuffer buffer, {AngleMode? angleMode}) {
    if (!buffer.tokens.any(_isOperatorOrFunction)) {
      return null;
    }
    final CalcResult result = CalcEngine.evaluate(
      buffer.tokens,
      angleMode: angleMode ?? state.angleMode,
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
        last.apply(state.result ?? state.ans, angleMode: state.angleMode),
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
      CalcEngine.evaluate(buffer.tokens, angleMode: state.angleMode),
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
          mode: state.mode,
          angleMode: state.angleMode,
          second: state.second,
        );
        _saveAns(value);
      case Failure(:final CalcError error):
        // §5: show the message and keep the buffer so the user can fix it.
        state = CalcState(
          buffer: buffer,
          ans: state.ans,
          error: error,
          mode: state.mode,
          angleMode: state.angleMode,
          second: state.second,
        );
    }
  }

  void _saveAns(Decimal value) {
    _ansChanged = true;
    final String text = value.toString();
    final store = ref.read(kvStoreProvider);
    _lastPersist = _lastPersist.then((_) => store.setString(ansKey, text));
  }

  Future<void> _restoreState() async {
    final store = ref.read(kvStoreProvider);
    final String? rawAns = await store.getString(ansKey);
    final String? rawMode = await store.getString(modeKey);
    final Decimal? ans = rawAns == null ? null : Decimal.tryParse(rawAns);

    if (!ref.mounted) {
      return;
    }
    state = CalcState(
      buffer: state.buffer,
      preview: state.preview,
      result: state.result,
      error: state.error,
      justEvaluated: state.justEvaluated,
      lastOperation: state.lastOperation,
      ans: _ansChanged ? state.ans : (ans ?? state.ans),
      mode: _modeChanged ? state.mode : _parseMode(rawMode),
      angleMode: state.angleMode,
      second: state.second,
    );
  }

  static CalcMode _parseMode(String? raw) {
    for (final CalcMode mode in CalcMode.values) {
      if (mode.name == raw) {
        return mode;
      }
    }
    return CalcMode.basic;
  }
}

/// ARCHITECTURE "State": mode, buffer tokens, preview, result, error, 2nd and
/// Ans. The angle mirrors Settings (see `CalculatorPage`).
final NotifierProvider<CalculatorController, CalcState> calculatorProvider =
    NotifierProvider<CalculatorController, CalcState>(
      CalculatorController.new,
      name: 'calculator',
    );
