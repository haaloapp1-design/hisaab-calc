import 'package:decimal/decimal.dart';

import 'ast.dart';
import 'token.dart';

/// Precedence-climbing parser (BUSINESS_LOGIC §3).
///
/// T07 covers numbers, constants, unary signs, binary operators and brackets.
/// Postfix operators, functions and auto-closing brackets arrive in T08.
///
/// Throws [FormatException] on syntax errors; the engine facade turns that
/// into `CalcError.syntax`.
class Parser {
  Parser(this._tokens);

  final List<Token> _tokens;
  int _index = 0;

  static const int _addPrecedence = 1;
  static const int _multiplyPrecedence = 2;
  static const int _implicitPrecedence = 3;
  static const int _unaryPrecedence = 4;
  static const int _powerPrecedence = 5;

  /// Parses the whole token list into one tree.
  Node parse() {
    final Node node = _parseExpression(_addPrecedence);
    if (!_isAtEnd) {
      throw FormatException(
        'Unexpected token ${_tokens[_index]}',
        null,
        _index,
      );
    }
    return node;
  }

  Node _parseExpression(int minPrecedence) {
    Node left = _parsePrefix();

    while (!_isAtEnd) {
      final Token token = _tokens[_index];
      if (token is! OperatorToken) {
        break;
      }
      final int precedence = _precedenceOf(token);
      if (precedence < minPrecedence) {
        break;
      }

      _index++;
      final bool rightAssociative = token.operator == OperatorType.power;
      final Node right = _parseExpression(
        rightAssociative ? precedence : precedence + 1,
      );
      left = BinaryNode(token.operator, left, right);
    }

    return left;
  }

  Node _parsePrefix() {
    final Token token = _current;
    if (token is UnaryToken) {
      _index++;
      final Node operand = _parseExpression(_unaryPrecedence);
      return UnaryNode(negative: token.negative, operand: operand);
    }
    return _parsePrimary();
  }

  Node _parsePrimary() {
    final Token token = _current;
    switch (token) {
      case NumberToken(:final String value):
        _index++;
        return NumberNode(_toDecimal(value));
      case ConstantToken(:final MathConstant constant):
        _index++;
        return ConstNode(constant);
      case LeftParenToken():
        _index++;
        final Node inner = _parseExpression(_addPrecedence);
        if (_current is! RightParenToken) {
          throw FormatException('Expected ")"', null, _index);
        }
        _index++;
        return inner;
      default:
        throw FormatException('Unexpected token $token', null, _index);
    }
  }

  int _precedenceOf(OperatorToken token) => switch (token.operator) {
    OperatorType.add || OperatorType.subtract => _addPrecedence,
    OperatorType.multiply =>
      token.implicit ? _implicitPrecedence : _multiplyPrecedence,
    OperatorType.divide || OperatorType.mod => _multiplyPrecedence,
    OperatorType.power => _powerPrecedence,
  };

  /// `12.` is accepted by the tokenizer; trim the dot before `Decimal.parse`.
  Decimal _toDecimal(String raw) {
    final String value = raw.endsWith('.')
        ? raw.substring(0, raw.length - 1)
        : raw;
    return Decimal.parse(value);
  }

  bool get _isAtEnd => _index >= _tokens.length;

  Token get _current {
    if (_isAtEnd) {
      throw FormatException('Unexpected end of expression', null, _index);
    }
    return _tokens[_index];
  }
}
