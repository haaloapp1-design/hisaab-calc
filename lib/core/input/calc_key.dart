import '../engine/token.dart';

/// Every key a calculator keypad can emit (BUSINESS_LOGIC §5).
///
/// The enum carries the key's meaning in engine terms, so the controller only
/// dispatches and never hard-codes labels: `CalcKey.sin` is the `sin(` function
/// token, `CalcKey.power` is the `^` operator, and so on.
enum CalcKey {
  digit0,
  digit1,
  digit2,
  digit3,
  digit4,
  digit5,
  digit6,
  digit7,
  digit8,
  digit9,

  /// `.`
  decimalPoint,

  add,
  subtract,
  multiply,
  divide,

  /// `xʸ`
  power,

  /// `ʸ√x` (2nd function of `xʸ`)
  root,

  leftParen,
  rightParen,

  /// `±`
  toggleSign,

  /// `%` — a postfix, so §4 percent rules apply.
  percent,

  /// `n!`
  factorial,

  /// `x²`
  square,

  /// `x³`
  cube,

  /// `1/x` (renders as `⁻¹`)
  reciprocal,

  /// `√`
  sqrt,

  /// `∛`
  cbrt,

  sin,
  cos,
  tan,
  sinInverse,
  cosInverse,
  tanInverse,

  ln,
  log,

  /// `eˣ`
  exp,

  /// `10ˣ`
  tenPow,

  /// `π`
  pi,

  /// `e`
  e,

  /// `Ans`
  ans,

  /// `⌫`
  backspace,

  /// `C` / `AC`
  clear,

  /// `=`
  equals;

  /// The digit this key types, or null when it is not a digit key.
  int? get digit => switch (this) {
    CalcKey.digit0 => 0,
    CalcKey.digit1 => 1,
    CalcKey.digit2 => 2,
    CalcKey.digit3 => 3,
    CalcKey.digit4 => 4,
    CalcKey.digit5 => 5,
    CalcKey.digit6 => 6,
    CalcKey.digit7 => 7,
    CalcKey.digit8 => 8,
    CalcKey.digit9 => 9,
    _ => null,
  };

  /// The binary operator this key types, or null.
  OperatorType? get operatorType => switch (this) {
    CalcKey.add => OperatorType.add,
    CalcKey.subtract => OperatorType.subtract,
    CalcKey.multiply => OperatorType.multiply,
    CalcKey.divide => OperatorType.divide,
    CalcKey.power => OperatorType.power,
    CalcKey.root => OperatorType.root,
    _ => null,
  };

  /// The engine function name this key inserts, or null.
  String? get functionName => switch (this) {
    CalcKey.sin => 'sin',
    CalcKey.cos => 'cos',
    CalcKey.tan => 'tan',
    CalcKey.sinInverse => 'sin⁻¹',
    CalcKey.cosInverse => 'cos⁻¹',
    CalcKey.tanInverse => 'tan⁻¹',
    CalcKey.ln => 'ln',
    CalcKey.log => 'log',
    CalcKey.exp => 'eˣ',
    CalcKey.tenPow => '10ˣ',
    CalcKey.sqrt => '√',
    CalcKey.cbrt => '∛',
    _ => null,
  };

  /// The postfix operator this key types, or null.
  PostfixType? get postfixType => switch (this) {
    CalcKey.percent => PostfixType.percent,
    CalcKey.factorial => PostfixType.factorial,
    CalcKey.square => PostfixType.square,
    CalcKey.cube => PostfixType.cube,
    CalcKey.reciprocal => PostfixType.reciprocal,
    _ => null,
  };

  /// The constant this key inserts, or null.
  MathConstant? get constant => switch (this) {
    CalcKey.pi => MathConstant.pi,
    CalcKey.e => MathConstant.e,
    _ => null,
  };
}
