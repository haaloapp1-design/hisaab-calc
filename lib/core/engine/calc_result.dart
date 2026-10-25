import 'package:decimal/decimal.dart';

/// The result of evaluating an expression.
///
/// The engine never throws to the UI: every failure is a [Failure] carrying a
/// [CalcError] (BUSINESS_LOGIC §1, §7).
sealed class CalcResult {
  const CalcResult();
}

/// A successfully evaluated expression.
final class Success extends CalcResult {
  const Success(this.value);

  final Decimal value;

  @override
  bool operator ==(Object other) => other is Success && other.value == value;

  @override
  int get hashCode => Object.hash(Success, value);

  @override
  String toString() => 'Success($value)';
}

/// A failed evaluation.
final class Failure extends CalcResult {
  const Failure(this.error);

  final CalcError error;

  @override
  bool operator ==(Object other) => other is Failure && other.error == error;

  @override
  int get hashCode => Object.hash(Failure, error);

  @override
  String toString() => 'Failure(${error.name})';
}

/// Every error the engine can report, with the text shown on the display.
enum CalcError {
  divideByZero("Can't divide by zero"),
  domain('Undefined'),
  overflow('Number too large'),
  syntax('Invalid input'),
  tooLong('Expression too long');

  const CalcError(this.displayText);

  /// User-facing message from the BUSINESS_LOGIC §7 table.
  final String displayText;
}
