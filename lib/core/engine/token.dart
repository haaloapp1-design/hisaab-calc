/// The token model the input buffer holds and the tokenizer produces
/// (BUSINESS_LOGIC §1, §3).
///
/// Tokens are values: two tokens are equal when their fields are equal, which
/// keeps tokenizer and input tests readable.
sealed class Token {
  const Token();
}

/// A number the user typed, kept as raw digits (one optional dot).
final class NumberToken extends Token {
  const NumberToken(this.value);

  /// Raw decimal string, e.g. `12.5`. Never signed.
  final String value;

  @override
  bool operator ==(Object other) =>
      other is NumberToken && other.value == value;

  @override
  int get hashCode => Object.hash(NumberToken, value);

  @override
  String toString() => 'NumberToken($value)';
}

/// Binary operators, including `mod` (BUSINESS_LOGIC §3).
///
/// `root` is the scientific `ʸ√x` key: `8 ʸ√ 3` is the cube root of 8.
enum OperatorType { add, subtract, multiply, divide, power, root, mod }

final class OperatorToken extends Token {
  const OperatorToken(this.operator, {this.implicit = false});

  final OperatorType operator;

  /// True for the hidden `×` the tokenizer inserts (`2π`, `3(4)`).
  final bool implicit;

  @override
  bool operator ==(Object other) =>
      other is OperatorToken &&
      other.operator == operator &&
      other.implicit == implicit;

  @override
  int get hashCode => Object.hash(OperatorToken, operator, implicit);

  @override
  String toString() =>
      'OperatorToken(${operator.name}${implicit ? ', implicit' : ''})';
}

/// A leading `+`/`−` (precedence level 4). The tokenizer emits it at the start
/// of an expression or after an operator / `(` / a function.
final class UnaryToken extends Token {
  const UnaryToken({required this.negative});

  final bool negative;

  @override
  bool operator ==(Object other) =>
      other is UnaryToken && other.negative == negative;

  @override
  int get hashCode => Object.hash(UnaryToken, negative);

  @override
  String toString() => 'UnaryToken(${negative ? '−' : '+'})';
}

final class LeftParenToken extends Token {
  const LeftParenToken();

  @override
  bool operator ==(Object other) => other is LeftParenToken;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'LeftParenToken';
}

final class RightParenToken extends Token {
  const RightParenToken();

  @override
  bool operator ==(Object other) => other is RightParenToken;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'RightParenToken';
}

/// A function together with its opening bracket, so `sin(` is ONE token and
/// backspace removes it in one step. The closing bracket is a separate
/// [RightParenToken].
final class FunctionToken extends Token {
  const FunctionToken(this.name);

  /// Display/engine name: `sin`, `sin⁻¹`, `ln`, `log`, `√`, `∛`, `eˣ`, `10ˣ`, …
  final String name;

  @override
  bool operator ==(Object other) =>
      other is FunctionToken && other.name == name;

  @override
  int get hashCode => Object.hash(FunctionToken, name);

  @override
  String toString() => 'FunctionToken($name)';
}

/// Constants with an exact Decimal value (BUSINESS_LOGIC §3).
enum MathConstant { pi, e }

final class ConstantToken extends Token {
  const ConstantToken(this.constant);

  final MathConstant constant;

  @override
  bool operator ==(Object other) =>
      other is ConstantToken && other.constant == constant;

  @override
  int get hashCode => Object.hash(ConstantToken, constant);

  @override
  String toString() => 'ConstantToken(${constant.name})';
}

/// Postfix operators at precedence level 6 / 5 (BUSINESS_LOGIC §3).
///
/// `reciprocal` is the scientific `1/x` key and renders as `⁻¹`.
enum PostfixType { factorial, percent, square, cube, reciprocal }

final class PostfixToken extends Token {
  const PostfixToken(this.postfix);

  final PostfixType postfix;

  @override
  bool operator ==(Object other) =>
      other is PostfixToken && other.postfix == postfix;

  @override
  int get hashCode => Object.hash(PostfixToken, postfix);

  @override
  String toString() => 'PostfixToken(${postfix.name})';
}

/// The previous answer (`Ans`).
final class AnsToken extends Token {
  const AnsToken();

  @override
  bool operator ==(Object other) => other is AnsToken;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'AnsToken';
}
