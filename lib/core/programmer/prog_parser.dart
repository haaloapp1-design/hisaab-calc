import '../engine/calc_result.dart';
import 'base_format.dart';
import 'word.dart';

/// The result of a programmer-mode expression (BUSINESS_LOGIC §11).
sealed class ProgResult {
  const ProgResult();
}

/// A successfully evaluated expression.
final class ProgSuccess extends ProgResult {
  const ProgSuccess(this.value);

  /// The result, re-masked into the expression's word size.
  final Word value;

  @override
  bool operator ==(Object other) =>
      other is ProgSuccess && other.value == value;

  @override
  int get hashCode => Object.hash(ProgSuccess, value);

  @override
  String toString() => 'ProgSuccess($value)';
}

/// A failed evaluation; [error] carries the §7 display text.
final class ProgFailure extends ProgResult {
  const ProgFailure(this.error);

  final CalcError error;

  @override
  bool operator ==(Object other) =>
      other is ProgFailure && other.error == error;

  @override
  int get hashCode => Object.hash(ProgFailure, error);

  @override
  String toString() => 'ProgFailure(${error.name})';
}

/// Parses and evaluates programmer-mode expressions (BUSINESS_LOGIC §11).
///
/// [source] is what the keypad and the base rows produce: digits in [base],
/// brackets, `+ − × ÷ mod`, `AND OR XOR NAND NOT`, `<< >>` and the `±` sign.
/// ASCII `- * / & | ^ ~` are accepted as the same operators. Precedence, low to
/// high: OR, XOR, AND/NAND, shifts, `+ −`, `× ÷ mod`, then unary NOT/±.
abstract final class ProgEngine {
  /// Evaluates [source] in [base] with [size]-bit words (default 32-bit).
  ///
  /// Every intermediate result is re-masked (§11), so arithmetic wraps two's
  /// complement and division truncates toward zero. The engine never throws to
  /// the UI: syntax is [CalcError.syntax], `÷ 0`/`mod 0` is
  /// [CalcError.divideByZero] and a negative shift count is [CalcError.domain].
  static ProgResult evaluate(
    String source, {
    NumberBase base = NumberBase.dec,
    WordSize size = WordSize.standard,
  }) {
    try {
      return ProgSuccess(_Parser(source, base, size).parse());
    } on FormatException {
      return const ProgFailure(CalcError.syntax);
    } on _ProgError catch (error) {
      return ProgFailure(error.error);
    }
  }
}

/// A runtime failure (not a syntax error) the facade turns into a [ProgFailure].
final class _ProgError implements Exception {
  const _ProgError(this.error);

  final CalcError error;
}

/// Binary operators, with the §11 precedence levels (higher binds tighter).
///
/// NAND shares AND's level because it is `NOT (a AND b)` and §11 does not give
/// it a row of its own.
enum _Op {
  or(0),
  xor(1),
  and(2),
  nand(2),
  shiftLeft(3),
  shiftRight(3),
  add(4),
  subtract(4),
  multiply(5),
  divide(5),
  mod(5);

  const _Op(this.level);

  final int level;
}

typedef _Spelling = ({_Op op, String text, bool keyword});

/// Spellings the parser accepts; keywords are matched case-insensitively.
const List<_Spelling> _spellings = <_Spelling>[
  (op: _Op.nand, text: 'NAND', keyword: true),
  (op: _Op.and, text: 'AND', keyword: true),
  (op: _Op.xor, text: 'XOR', keyword: true),
  (op: _Op.or, text: 'OR', keyword: true),
  (op: _Op.mod, text: 'mod', keyword: true),
  (op: _Op.shiftLeft, text: '<<', keyword: false),
  (op: _Op.shiftRight, text: '>>', keyword: false),
  (op: _Op.add, text: '+', keyword: false),
  (op: _Op.subtract, text: '−', keyword: false),
  (op: _Op.subtract, text: '-', keyword: false),
  (op: _Op.multiply, text: '×', keyword: false),
  (op: _Op.multiply, text: '*', keyword: false),
  (op: _Op.divide, text: '÷', keyword: false),
  (op: _Op.divide, text: '/', keyword: false),
  (op: _Op.and, text: '&', keyword: false),
  (op: _Op.or, text: '|', keyword: false),
  (op: _Op.xor, text: '^', keyword: false),
];

/// A precedence-climbing parser that evaluates as it goes.
final class _Parser {
  _Parser(this.source, this.base, this.size);

  final String source;
  final NumberBase base;
  final WordSize size;
  int index = 0;

  /// Parses the whole [source]; trailing input is a syntax error.
  Word parse() {
    _skipWhitespace();
    if (index >= source.length) {
      throw const FormatException('Empty expression');
    }
    final Word value = _binary(0);
    _skipWhitespace();
    if (index < source.length) {
      throw const FormatException('Unexpected input');
    }
    return value;
  }

  /// Level [minLevel] and tighter, left-associative.
  Word _binary(int minLevel) {
    Word left = _unary();
    while (true) {
      final ({_Op op, int length})? token = _readOperator();
      if (token == null || token.op.level < minLevel) {
        return left;
      }
      index += token.length;
      final Word right = _binary(token.op.level + 1);
      left = _apply(token.op, left, right);
    }
  }

  /// NOT/`±`/`+`, a bracketed group, or a number.
  Word _unary() {
    _skipWhitespace();
    if (_takeKeyword('NOT') || _take('~')) {
      return _unary().bitNot();
    }
    if (_take('−') || _take('-')) {
      return _unary().negate();
    }
    if (_take('+')) {
      return _unary();
    }
    if (_take('(')) {
      final Word value = _binary(0);
      _expect(')');
      return value;
    }
    return _number();
  }

  Word _number() {
    _skipWhitespace();
    final int start = index;
    while (index < source.length && _isDigit(source.codeUnitAt(index))) {
      index++;
    }
    if (index == start) {
      throw const FormatException('Expected a number');
    }
    return Word(
      BigInt.parse(source.substring(start, index), radix: base.radix),
      size: size,
    );
  }

  Word _apply(_Op op, Word left, Word right) => switch (op) {
    _Op.or => left.bitOr(right),
    _Op.xor => left.bitXor(right),
    _Op.and => left.bitAnd(right),
    _Op.nand => left.nand(right),
    _Op.shiftLeft => left.shiftLeft(_shiftCount(right)),
    _Op.shiftRight => left.shiftRight(_shiftCount(right)),
    _Op.add => left.add(right),
    _Op.subtract => left.subtract(right),
    _Op.multiply => left.multiply(right),
    _Op.divide => _divide(left, right),
    _Op.mod => _modulo(left, right),
  };

  Word _divide(Word left, Word right) {
    if (right.signed == BigInt.zero) {
      throw const _ProgError(CalcError.divideByZero);
    }
    return left.divide(right);
  }

  Word _modulo(Word left, Word right) {
    if (right.signed == BigInt.zero) {
      throw const _ProgError(CalcError.divideByZero);
    }
    return left.modulo(right);
  }

  BigInt _shiftCount(Word count) {
    if (count.isNegative) {
      throw const _ProgError(CalcError.domain);
    }
    return count.signed;
  }

  ({_Op op, int length})? _readOperator() {
    _skipWhitespace();
    for (final _Spelling spelling in _spellings) {
      final bool found = spelling.keyword
          ? _matchesKeyword(spelling.text)
          : source.startsWith(spelling.text, index);
      if (found) {
        return (op: spelling.op, length: spelling.text.length);
      }
    }
    return null;
  }

  bool _take(String text) {
    if (!source.startsWith(text, index)) {
      return false;
    }
    index += text.length;
    return true;
  }

  bool _takeKeyword(String text) {
    if (!_matchesKeyword(text)) {
      return false;
    }
    index += text.length;
    return true;
  }

  bool _matchesKeyword(String text) {
    if (index + text.length > source.length) {
      return false;
    }
    return source.substring(index, index + text.length).toUpperCase() ==
        text.toUpperCase();
  }

  void _expect(String text) {
    _skipWhitespace();
    if (!_take(text)) {
      throw FormatException('Expected $text');
    }
  }

  void _skipWhitespace() {
    while (index < source.length && _isWhitespace(source.codeUnitAt(index))) {
      index++;
    }
  }

  bool _isDigit(int code) {
    final int value = _digitValue(code);
    return value >= 0 && value < base.radix;
  }

  static int _digitValue(int code) {
    if (code >= 0x30 && code <= 0x39) {
      return code - 0x30;
    }
    final int upper = code >= 0x61 && code <= 0x7A ? code - 0x20 : code;
    return upper >= 0x41 && upper <= 0x46 ? upper - 0x41 + 10 : -1;
  }

  static bool _isWhitespace(int code) =>
      code == 0x20 || code == 0x09 || code == 0x0A || code == 0x0D;
}
