import '../engine/token.dart';

/// Edits the token list the user is typing (BUSINESS_LOGIC §5).
///
/// The buffer holds tokens, not characters: `sin(` is one token, so editing
/// rules work on whole functions. Every edit returns a new buffer, which keeps
/// the Riverpod controller simple and the rules easy to test.
final class InputBuffer {
  const InputBuffer(this.tokens);

  const InputBuffer.empty() : tokens = const <Token>[];

  /// The typed tokens, in order.
  final List<Token> tokens;

  /// §5: the most digits one typed number may hold.
  static const int maxDigits = 15;

  bool get isEmpty => tokens.isEmpty;

  int get length => tokens.length;

  Token? get last => tokens.isEmpty ? null : tokens.last;

  /// §5 digit row: appends to the current number, replaces a leading zero and
  /// stops at [maxDigits]. After a value it starts a new factor (implicit ×).
  InputBuffer appendDigit(int digit) {
    assert(digit >= 0 && digit <= 9, 'digit must be 0–9');
    final String text = '$digit';
    final Token? previous = last;

    if (previous is NumberToken) {
      if (_digitCount(previous.value) >= maxDigits) {
        return this;
      }
      // `0` then `5` → `5`; a second `0` keeps the number at `0`.
      final String value = previous.value == '0'
          ? text
          : '${previous.value}$text';
      return _replaceLast(NumberToken(value));
    }

    return _startNumber(text);
  }

  /// §5 `.` row: one dot per number, and a leading dot becomes `0.`.
  InputBuffer appendDecimalPoint() {
    final Token? previous = last;

    if (previous is NumberToken) {
      if (previous.value.contains('.')) {
        return this;
      }
      return _replaceLast(NumberToken('${previous.value}.'));
    }

    return _startNumber('0.');
  }

  /// §5 operator row: replaces a trailing operator, except `−` after `×`/`÷`/`(`
  /// (and a function's bracket), which starts a negative number. An empty buffer
  /// starts from [startValue] — the controller passes `Ans`, the default is `0`.
  InputBuffer appendOperator(
    OperatorType operator, {
    NumberToken startValue = const NumberToken('0'),
  }) {
    final List<Token> next = List<Token>.of(tokens);

    // A trailing sign has no value yet, so drop it before deciding.
    if (next.isNotEmpty && next.last is UnaryToken) {
      next.removeLast();
    }

    if (next.isEmpty) {
      return InputBuffer(<Token>[startValue, OperatorToken(operator)]);
    }

    final Token previous = next.last;

    if (previous is OperatorToken) {
      if (operator == OperatorType.subtract &&
          (previous.operator == OperatorType.multiply ||
              previous.operator == OperatorType.divide)) {
        next.add(const UnaryToken(negative: true));
        return InputBuffer(next);
      }
      next[next.length - 1] = OperatorToken(operator);
      return InputBuffer(next);
    }

    if (previous is LeftParenToken || previous is FunctionToken) {
      // No value to operate on yet; only a leading minus is meaningful.
      if (operator == OperatorType.subtract) {
        next.add(const UnaryToken(negative: true));
        return InputBuffer(next);
      }
      return this;
    }

    if (_endsValue(previous)) {
      next.add(OperatorToken(operator));
      return InputBuffer(next);
    }

    return this;
  }

  /// §5 `(` row: always allowed; after a value the hidden `×` is inserted.
  InputBuffer appendLeftParen() => _appendValue(const LeftParenToken());

  /// §5 `)` row: only when a bracket is open and the last token is a value.
  InputBuffer appendRightParen() {
    if (_openCount <= _closeCount) {
      return this;
    }
    final Token? previous = last;
    if (previous == null || !_endsValue(previous)) {
      return this;
    }
    return InputBuffer(<Token>[...tokens, const RightParenToken()]);
  }

  /// §5 `±` row: wraps the current number as `(−n)` and unwraps it again.
  ///
  /// A number that already carries a `UnaryToken` (for example `5×−5`) toggles
  /// that sign instead of gaining a second wrapper.
  InputBuffer toggleSign() {
    if (tokens.isEmpty) {
      return this;
    }

    final List<Token> next = List<Token>.of(tokens);

    if (_endsWithNegativeNumberWrapper(next)) {
      final int start = next.length - 4;
      final Token number = next[start + 2];
      next.replaceRange(start, next.length, <Token>[number]);
      return InputBuffer(next);
    }

    if (next.last is NumberToken) {
      final int signIndex = next.length - 2;
      if (signIndex >= 0 && next[signIndex] is UnaryToken) {
        next.removeAt(signIndex);
        return InputBuffer(next);
      }

      final NumberToken number = next.removeLast() as NumberToken;
      next
        ..add(const LeftParenToken())
        ..add(const UnaryToken(negative: true))
        ..add(number)
        ..add(const RightParenToken());
      return InputBuffer(next);
    }

    return this;
  }

  /// §5 `⌫` row: removes one token, or one digit from the last number.
  InputBuffer backspace() {
    if (tokens.isEmpty) {
      return this;
    }

    final List<Token> next = List<Token>.of(tokens);
    final Token previous = next.last;

    if (previous is NumberToken) {
      final String value = previous.value;
      if (value.length <= 1) {
        next.removeLast();
      } else {
        next[next.length - 1] = NumberToken(
          value.substring(0, value.length - 1),
        );
      }
      return InputBuffer(next);
    }

    next.removeLast();
    return InputBuffer(next);
  }

  /// §5 `C`/`AC`: clears the buffer; memory and `Ans` live elsewhere.
  InputBuffer clear() => const InputBuffer.empty();

  InputBuffer _startNumber(String value) => _appendValue(NumberToken(value));

  InputBuffer _appendValue(Token token) {
    final List<Token> next = List<Token>.of(tokens);
    if (next.isNotEmpty && _endsValue(next.last)) {
      next.add(const OperatorToken(OperatorType.multiply, implicit: true));
    }
    next.add(token);
    return InputBuffer(next);
  }

  InputBuffer _replaceLast(Token token) {
    final List<Token> next = List<Token>.of(tokens);
    next[next.length - 1] = token;
    return InputBuffer(next);
  }

  int get _openCount => tokens
      .where((Token token) => token is LeftParenToken || token is FunctionToken)
      .length;

  int get _closeCount => tokens.whereType<RightParenToken>().length;

  static bool _endsWithNegativeNumberWrapper(List<Token> tokens) {
    if (tokens.length < 4) {
      return false;
    }
    final int start = tokens.length - 4;
    return tokens[start] is LeftParenToken &&
        tokens[start + 1] is UnaryToken &&
        (tokens[start + 1] as UnaryToken).negative &&
        tokens[start + 2] is NumberToken &&
        tokens[start + 3] is RightParenToken;
  }

  static int _digitCount(String value) => value.replaceAll('.', '').length;

  @override
  bool operator ==(Object other) {
    if (other is! InputBuffer || other.tokens.length != tokens.length) {
      return false;
    }
    for (int i = 0; i < tokens.length; i++) {
      if (other.tokens[i] != tokens[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(tokens);

  @override
  String toString() => 'InputBuffer($tokens)';
}

/// A is a number, constant, `)`, `!`, `%`, `Ans` or a postfix power.
bool _endsValue(Token token) =>
    token is NumberToken ||
    token is ConstantToken ||
    token is RightParenToken ||
    token is PostfixToken ||
    token is AnsToken;
