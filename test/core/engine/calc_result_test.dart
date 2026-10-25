import 'package:calculator/core/engine/calc_result.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalcError', () {
    test('has the display text from the §7 table', () {
      expect(CalcError.divideByZero.displayText, "Can't divide by zero");
      expect(CalcError.domain.displayText, 'Undefined');
      expect(CalcError.overflow.displayText, 'Number too large');
      expect(CalcError.syntax.displayText, 'Invalid input');
      expect(CalcError.tooLong.displayText, 'Expression too long');
    });

    test('covers exactly the five documented errors', () {
      expect(CalcError.values, <CalcError>[
        CalcError.divideByZero,
        CalcError.domain,
        CalcError.overflow,
        CalcError.syntax,
        CalcError.tooLong,
      ]);
    });
  });

  group('CalcResult', () {
    test('Success carries an exact Decimal', () {
      final CalcResult result = Success(Decimal.parse('0.3'));

      expect(result, Success(Decimal.parse('0.3')));
      expect((result as Success).value, Decimal.parse('0.3'));
    });

    test('Failure carries the error', () {
      const CalcResult result = Failure(CalcError.divideByZero);

      expect(result, const Failure(CalcError.divideByZero));
      expect((result as Failure).error.displayText, "Can't divide by zero");
    });

    test('different results are not equal', () {
      expect(Success(Decimal.one), isNot(Failure(CalcError.overflow)));
      expect(Failure(CalcError.syntax), isNot(const Failure(CalcError.domain)));
      expect(Success(Decimal.one), isNot(Success(Decimal.fromInt(2))));
    });

    test('can be switched on exhaustively', () {
      String describe(CalcResult result) => switch (result) {
        Success(:final Decimal value) => 'value:$value',
        Failure(:final CalcError error) => 'error:${error.name}',
      };

      expect(describe(Success(Decimal.fromInt(42))), 'value:42');
      expect(describe(const Failure(CalcError.domain)), 'error:domain');
    });
  });
}
