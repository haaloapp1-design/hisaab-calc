import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/engine/angle_mode.dart';
import '../../core/engine/calc_engine.dart';
import '../../core/engine/calc_result.dart';
import '../../core/engine/token.dart';
import '../../core/input/calc_key.dart';
import '../../core/input/input_buffer.dart';
import '../../core/storage/kv_store_provider.dart';
import 'calc_state.dart';

/// The calculator screen's state machine: `CalcKey` → [InputBuffer] → preview
/// (BUSINESS_LOGIC §5, ARCHITECTURE "State").
///
/// It owns no maths: every preview comes from [CalcEngine].
class CalculatorController extends Notifier<CalcState> {
  /// §9 the persisted `Ans` lives under this KvStore key.
  static const String ansKey = 'ans_v1';

  Future<void>? _restore;

  @override
  CalcState build() {
    // `Ans` is persisted, so start from the store (async) while the first
    // frame shows 0; tests await [restoreDone].
    _restore ??= _restoreAns();
    return CalcState(ans: Decimal.zero);
  }

  /// Completes when the persisted `Ans` has been loaded. Test hook.
  Future<void> get restoreDone => _restore ?? Future<void>.value();

  /// Handles one key. `=` is T18's task; every other key edits the buffer and
  /// refreshes the preview.
  void onKey(CalcKey key) {
    final int? digit = key.digit;
    if (digit != null) {
      _set(state.buffer.appendDigit(digit));
      return;
    }

    final OperatorType? operatorType = key.operatorType;
    if (operatorType != null) {
      _set(_appendOperator(operatorType));
      return;
    }

    final String? function = key.functionName;
    if (function != null) {
      _set(state.buffer.appendFunction(function));
      return;
    }

    final PostfixType? postfix = key.postfixType;
    if (postfix != null) {
      _set(state.buffer.appendPostfix(postfix));
      return;
    }

    final MathConstant? constant = key.constant;
    if (constant != null) {
      _set(state.buffer.appendConstant(constant));
      return;
    }

    // The remaining keys. Null means the key changes nothing (for now `=`, see
    // T18, and any key this controller has no rule for).
    final InputBuffer? next = switch (key) {
      CalcKey.decimalPoint => state.buffer.appendDecimalPoint(),
      CalcKey.leftParen => state.buffer.appendLeftParen(),
      CalcKey.rightParen => state.buffer.appendRightParen(),
      CalcKey.toggleSign => state.buffer.toggleSign(),
      CalcKey.ans => state.buffer.appendValueTokens(_valueTokens(state.ans)),
      CalcKey.backspace => state.buffer.backspace(),
      CalcKey.clear => const InputBuffer.empty(),
      _ => null,
    };
    if (next != null) {
      _set(next);
    }
  }

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
  InputBuffer _appendOperator(OperatorType operatorType) {
    final InputBuffer buffer = state.buffer.isEmpty
        ? InputBuffer(_valueTokens(state.ans))
        : state.buffer;
    return buffer.appendOperator(operatorType);
  }

  /// `Ans` as buffer tokens. A negative answer needs brackets, because
  /// [NumberToken] itself is always unsigned (§1, §3).
  static List<Token> _valueTokens(Decimal value) {
    if (value < Decimal.zero) {
      return <Token>[
        const LeftParenToken(),
        const UnaryToken(negative: true),
        NumberToken(value.abs().toString()),
        const RightParenToken(),
      ];
    }
    return <Token>[NumberToken(value.toString())];
  }

  Future<void> _restoreAns() async {
    final String? raw = await ref.read(kvStoreProvider).getString(ansKey);
    final Decimal? value = raw == null ? null : Decimal.tryParse(raw);
    if (value == null || !ref.mounted) {
      return;
    }
    state = CalcState(
      buffer: state.buffer,
      preview: state.preview,
      ans: value,
    );
  }
}

/// ARCHITECTURE "State": calculator mode, buffer, preview, result, error,
/// 2nd and Ans. T18/T24 add the remaining fields.
final NotifierProvider<CalculatorController, CalcState> calculatorProvider =
    NotifierProvider<CalculatorController, CalcState>(
      CalculatorController.new,
      name: 'calculator',
    );
