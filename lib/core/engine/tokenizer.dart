import 'token.dart';

/// Function names the tokenizer understands, matching the labels on the
/// scientific keypad (BUSINESS_LOGIC §3, SPEC §1.3).
const Set<String> _functionNames = <String>{
  'sin',
  'cos',
  'tan',
  'sin⁻¹',
  'cos⁻¹',
  'tan⁻¹',
  'ln',
  'log',
};

const String _inverseSuffix = '⁻¹';

/// Turns source text into tokens (BUSINESS_LOGIC §1, §3).
///
/// Handles numbers, operators, brackets, postfix operators, functions,
/// constants (`π`, `e`), `Ans`, and inserts the hidden `×` for implicit
/// multiplication.
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

  // A function token owns its opening bracket, so `sin(` is one token.
  void addFunction(String name) {
    if (index < source.length && source[index] == '(') {
      index++;
    }
    add(FunctionToken(name), valueAfter: true);
  }

  while (index < source.length) {
    final String char = source[index];

    if (_isWhitespace(char)) {
      index++;
      continue;
    }

    // Multi-character function symbols (checked before numbers/letters).
    if (_matchesAt(source, index, '10ˣ')) {
      index += 3;
      addFunction('10ˣ');
      continue;
    }
    if (_matchesAt(source, index, 'eˣ')) {
      index += 2;
      addFunction('eˣ');
      continue;
    }
    if (char == '√' || char == '∛') {
      index++;
      addFunction(char);
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
      String word = source.substring(start, index);

      if ((word == 'sin' || word == 'cos' || word == 'tan') &&
          _matchesAt(source, index, _inverseSuffix)) {
        index += _inverseSuffix.length;
        word += _inverseSuffix;
      }

      if (word == 'mod') {
        add(const OperatorToken(OperatorType.mod), valueAfter: true);
        continue;
      }
      if (word == 'Ans' || word == 'ans') {
        add(const AnsToken(), valueAfter: false);
        continue;
      }
      if (word == 'pi') {
        add(const ConstantToken(MathConstant.pi), valueAfter: false);
        continue;
      }
      if (word == 'e') {
        add(const ConstantToken(MathConstant.e), valueAfter: false);
        continue;
      }
      if (_functionNames.contains(word)) {
        addFunction(word);
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
      case 'π':
        add(const ConstantToken(MathConstant.pi), valueAfter: false);
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

  return _insertImplicitMultiplication(tokens);
}

/// Inserts the hidden `×` between A and B per BUSINESS_LOGIC §3.
List<Token> _insertImplicitMultiplication(List<Token> tokens) {
  if (tokens.length < 2) {
    return tokens;
  }

  final List<Token> result = <Token>[];
  Token? previous;
  for (final Token token in tokens) {
    if (previous != null && _endsValue(previous) && _startsValue(token)) {
      result.add(const OperatorToken(OperatorType.multiply, implicit: true));
    }
    result.add(token);
    previous = token;
  }
  return result;
}

/// A is a number, constant, `)`, `!`, `%`, `Ans` or a postfix power.
bool _endsValue(Token token) =>
    token is NumberToken ||
    token is ConstantToken ||
    token is RightParenToken ||
    token is PostfixToken ||
    token is AnsToken;

/// B is a number, constant, `(`, a function or `Ans`.
bool _startsValue(Token token) =>
    token is NumberToken ||
    token is ConstantToken ||
    token is LeftParenToken ||
    token is FunctionToken ||
    token is AnsToken;

bool _matchesAt(String source, int index, String text) =>
    source.startsWith(text, index);

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
