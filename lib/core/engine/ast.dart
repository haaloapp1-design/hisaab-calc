import 'package:decimal/decimal.dart';

import 'token.dart';

/// Expression tree produced by the parser (BUSINESS_LOGIC §1).
///
/// Nodes are immutable values with structural equality, which keeps parser
/// tests readable.
sealed class Node {
  const Node();
}

final class NumberNode extends Node {
  const NumberNode(this.value);

  final Decimal value;

  @override
  bool operator ==(Object other) => other is NumberNode && other.value == value;

  @override
  int get hashCode => Object.hash(NumberNode, value);

  @override
  String toString() => 'NumberNode($value)';
}

final class ConstNode extends Node {
  const ConstNode(this.constant);

  final MathConstant constant;

  @override
  bool operator ==(Object other) =>
      other is ConstNode && other.constant == constant;

  @override
  int get hashCode => Object.hash(ConstNode, constant);

  @override
  String toString() => 'ConstNode(${constant.name})';
}

/// Unary `+`/`−` (precedence level 4).
final class UnaryNode extends Node {
  const UnaryNode({required this.negative, required this.operand});

  final bool negative;
  final Node operand;

  @override
  bool operator ==(Object other) =>
      other is UnaryNode &&
      other.negative == negative &&
      other.operand == operand;

  @override
  int get hashCode => Object.hash(UnaryNode, negative, operand);

  @override
  String toString() => 'UnaryNode(${negative ? '−' : '+'}, $operand)';
}

final class BinaryNode extends Node {
  const BinaryNode(this.operator, this.left, this.right);

  final OperatorType operator;
  final Node left;
  final Node right;

  @override
  bool operator ==(Object other) =>
      other is BinaryNode &&
      other.operator == operator &&
      other.left == left &&
      other.right == right;

  @override
  int get hashCode => Object.hash(BinaryNode, operator, left, right);

  @override
  String toString() => 'BinaryNode(${operator.name}, $left, $right)';
}

/// A function call; [name] is the display name from the tokenizer.
final class FuncNode extends Node {
  const FuncNode(this.name, this.argument);

  final String name;
  final Node argument;

  @override
  bool operator ==(Object other) =>
      other is FuncNode && other.name == name && other.argument == argument;

  @override
  int get hashCode => Object.hash(FuncNode, name, argument);

  @override
  String toString() => 'FuncNode($name, $argument)';
}

final class PostfixNode extends Node {
  const PostfixNode(this.postfix, this.operand);

  final PostfixType postfix;
  final Node operand;

  @override
  bool operator ==(Object other) =>
      other is PostfixNode &&
      other.postfix == postfix &&
      other.operand == operand;

  @override
  int get hashCode => Object.hash(PostfixNode, postfix, operand);

  @override
  String toString() => 'PostfixNode(${postfix.name}, $operand)';
}
