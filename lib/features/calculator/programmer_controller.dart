import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/engine/calc_result.dart';
import '../../core/programmer/base_format.dart';
import '../../core/programmer/prog_key.dart';
import '../../core/programmer/prog_parser.dart';
import '../../core/programmer/prog_source.dart';
import '../../core/programmer/word.dart';
import '../history/history_controller.dart';
import '../history/history_entry.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_format.dart';
import 'prog_state.dart';

/// The Programmer screen's state machine: [ProgKey] → source string →
/// `ProgEngine` → [ProgState] (SPEC §1.4, ARCHITECTURE "State").
///
/// It owns no maths: every value comes from `ProgEngine.evaluate`, and every
/// source edit comes from [ProgSource]. Unlike the decimal calculator there is
/// no persisted `Ans`: the value lives as long as the app session.
class ProgrammerController extends Notifier<ProgState> {
  @override
  ProgState build() => ProgState();

  /// Handles one key.
  void onKey(ProgKey key) {
    if (key == ProgKey.equals) {
      _equals();
      return;
    }
    if (key == ProgKey.clear) {
      state = ProgState(base: state.base, size: state.size);
      return;
    }
    if (key == ProgKey.backspace) {
      _setSource(ProgSource.backspace(_startSource(key)));
      return;
    }
    if (key == ProgKey.toggleSign) {
      _setSource(ProgSource.toggleSign(_startSource(key)));
      return;
    }

    final String? digit = key.digit;
    if (digit != null) {
      _setSource(ProgSource.appendDigit(_startSource(key), digit));
      return;
    }

    final String? operator = key.operator;
    if (operator != null) {
      _setSource(ProgSource.appendOperator(_startSource(key), operator));
      return;
    }

    if (key == ProgKey.not) {
      _setSource(ProgSource.appendNot(_startSource(key)));
    } else if (key == ProgKey.leftParen) {
      _setSource(ProgSource.appendOpenParen(_startSource(key)));
    } else if (key == ProgKey.rightParen) {
      _setSource(ProgSource.appendCloseParen(_startSource(key)));
    }
  }

  /// SPEC §1.4: tapping a base row makes it the input base.
  ///
  /// §11 says switching "converts the current value, not the text", so a typed
  /// expression collapses to its value written in the new base.
  void selectBase(NumberBase base) {
    if (base == state.base) {
      return;
    }
    final bool hasSource = state.source.trim().isNotEmpty;
    state = state.copyWith(
      base: base,
      source: hasSource ? formatInBase(state.value, base) : '',
      clearError: true,
    );
  }

  /// SPEC §1.4 / §11: re-masks the current value into [size].
  ///
  /// Returns true when the signed value changed, so the page can show the
  /// "Value truncated to 16-bit" toast.
  bool setSize(WordSize size) {
    if (size == state.size) {
      return false;
    }
    final Word next = state.value.withSize(size);
    final bool truncated = next.signed != state.value.signed;
    state = ProgState(
      source: state.source,
      value: next,
      base: state.base,
      size: size,
      error: state.error,
      justEvaluated: state.justEvaluated,
    );
    return truncated;
  }

  /// §5 `=`: evaluate the source. An empty source is a no-op, and a failure
  /// keeps the source so the user can fix it.
  void _equals() {
    final String source = state.source.trim();
    if (source.isEmpty) {
      return;
    }
    final ProgResult result = ProgEngine.evaluate(
      source,
      base: state.base,
      size: state.size,
    );
    switch (result) {
      case ProgSuccess(:final Word value):
        state = ProgState(
          source: state.source,
          value: value,
          base: state.base,
          size: state.size,
          justEvaluated: true,
        );
        _saveHistory(source, value);
      case ProgFailure(:final CalcError error):
        state = state.copyWith(error: error, justEvaluated: false);
    }
  }

  /// After `=`: a digit, `(` or `⌫` starts fresh, while an operator, `NOT` or
  /// `±` continues from the result (the Basic display's §5 rule).
  String _startSource(ProgKey key) {
    if (!state.justEvaluated) {
      return state.source;
    }
    final bool continues =
        key.operator != null || key == ProgKey.not || key == ProgKey.toggleSign;
    return continues ? formatInBase(state.value, state.base) : '';
  }

  /// Stores [source] and previews its value; an incomplete source keeps the
  /// last good value instead of blanking the display.
  void _setSource(String source) {
    final String trimmed = source.trimRight();
    final ProgState next = state.copyWith(
      source: source,
      clearError: true,
      justEvaluated: false,
    );
    if (trimmed.isEmpty) {
      state = next.copyWith(value: Word.zero(size: state.size));
      return;
    }
    final ProgResult result = ProgEngine.evaluate(
      trimmed,
      base: state.base,
      size: state.size,
    );
    state = result is ProgSuccess ? next.copyWith(value: result.value) : next;
  }

  /// §10: a successful `=` is saved with the mode it was made in.
  void _saveHistory(String source, Word value) {
    ref
        .read(historyProvider.notifier)
        .add(
          expression: source,
          result: formatBaseValue(
            value,
            state.base,
            options: numberFormatFor(ref.read(settingsProvider)),
          ),
          mode: HistoryMode.programmer,
        );
  }
}

/// ARCHITECTURE "State": the programmer source, its value, the input base and
/// the word size.
final NotifierProvider<ProgrammerController, ProgState> programmerProvider =
    NotifierProvider<ProgrammerController, ProgState>(
      ProgrammerController.new,
      name: 'programmer',
    );
