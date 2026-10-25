import 'token.dart';

/// Turns source text into tokens (BUSINESS_LOGIC §1, §3).
///
/// Numbers, operators, brackets and postfix operators are handled here.
/// Functions, constants and implicit `×` arrive in T06.
///
/// Throws [FormatException] for text it cannot tokenize; the engine facade
/// turns that into `CalcError.syntax`, so nothing reaches the UI as an
/// exception.
List<Token> tokenize(String source) {
  final List<Token> tokens = <Token>[];
  int index = 0;

  // True when the next token would start a value, which makes `+`/`−` unary.
  bool expectsValue = true;

  void add(Token token, {required bool valueAfter}) {
    tokens.add(token);
    expectsValue = valueAfter;
  }

  while (index < source.length) {
    final String char = source[index];

    if (_isWhitespace(char)) {
      index++;
      continue;
    }

    if (_isDigit(char)) {
      final int start = index;
      while (index < source.length && _isDigit(source[index])) {
        index++;
      }
      if (index < source.length && source[index] == '.') {
        index++;
        while (index < source.length && _isDigit(source[index])) {
          index++;
        }
      }
      add(NumberToken(source.substring(start, index)), valueAfter: false);
      continue;
    }

    if (_isLetter(char)) {
      final int start = index;
      while (index < source.length && _isLetter(source[index])) {
        index++;
      }
      final String word = source.substring(start, index);
      if (word == 'mod') {
        add(const OperatorToken(OperatorType.mod), valueAfter: true);
        continue;
      }
      throw FormatException('Unknown name "$word"', source, start);
    }

    switch (char) {
      case '+':
        add(
          expectsValue
              ? const UnaryToken(negative: false)
              : const OperatorToken(OperatorType.add),
          valueAfter: true,
        );
      case '−' || '-':
        add(
          expectsValue
              ? const UnaryToken(negative: true)
              : const OperatorToken(OperatorType.subtract),
          valueAfter: true,
        );
      case '×' || '*':
        add(const OperatorToken(OperatorType.multiply), valueAfter: true);
      case '÷' || '/':
        add(const OperatorToken(OperatorType.divide), valueAfter: true);
      case '^':
        add(const OperatorToken(OperatorType.power), valueAfter: true);
      case '(':
        add(const LeftParenToken(), valueAfter: true);
      case ')':
        add(const RightParenToken(), valueAfter: false);
      case '!':
        add(const PostfixToken(PostfixType.factorial), valueAfter: false);
      case '%':
        add(const PostfixToken(PostfixType.percent), valueAfter: false);
      case '²':
        add(const PostfixToken(PostfixType.square), valueAfter: false);
      case '³':
        add(const PostfixToken(PostfixType.cube), valueAfter: false);
      default:
        throw FormatException('Unexpected character "$char"', source, index);
    }
    index++;
  }

  return tokens;
}

bool _isDigit(String char) {
  final int code = char.codeUnitAt(0);
  return code >= 0x30 && code <= 0x39;
}

bool _isLetter(String char) {
  final int code = char.codeUnitAt(0);
  return (code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A);
}

bool _isWhitespace(String char) =>
    char == ' ' || char == '\t' || char == '\n' || char == '\r';
