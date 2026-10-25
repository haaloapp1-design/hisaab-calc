import 'package:calculator/core/engine/angle_mode.dart';
import 'package:calculator/core/engine/calc_engine.dart';
import 'package:calculator/core/engine/calc_result.dart';
import 'package:calculator/core/engine/formatter.dart';
import 'package:calculator/core/engine/tokenizer.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// One row of the §2–§8 acceptance table: source text → displayed result.
class _Row {
  const _Row(this.expression, this.expected, {this.angleMode = AngleMode.deg});

  final String expression;
  final String expected;
  final AngleMode angleMode;
}

const List<_Row> _table = <_Row>[
  // §2 exact arithmetic and division.
  _Row('0.1+0.2', '0.3'),
  _Row('1÷3×3', '1'),
  _Row('1÷3', '0.333333333333'),
  _Row('2÷3', '0.666666666667'),
  _Row('7−2×3', '1'),
  _Row('(1+2)×3', '9'),
  _Row('2+3×4', '14'),
  _Row('10÷4', '2.5'),
  _Row('1+2×3−4', '3'),
  _Row('8÷4÷2', '1'),
  _Row('5÷0', "Can't divide by zero"),
  _Row('1÷0', "Can't divide by zero"),
  // §2/§3 powers and postfix powers.
  _Row('2^10', '1,024'),
  _Row('2^3^2', '512'),
  _Row('2^100', '1.2676506E+30'),
  _Row('2^−2', '0.25'),
  _Row('2^0.5', '1.41421356237'),
  _Row('0^0', '1'),
  _Row('0^−1', "Can't divide by zero"),
  _Row('−2^2', '−4'),
  _Row('(−2)^0.5', 'Undefined'),
  _Row('10^400', 'Number too large'),
  _Row('5²', '25'),
  _Row('(−3)³', '−27'),
  // §3 unary signs and constants.
  _Row('−5+2', '−3'),
  _Row('−−4', '4'),
  _Row('π', '3.14159265359'),
  _Row('e', '2.71828182846'),
  _Row('2π', '6.28318530718'),
  // §4 percent.
  _Row('50%', '0.5'),
  _Row('200+10%', '220'),
  _Row('200−10%', '180'),
  _Row('200×10%', '20'),
  _Row('200÷10%', '2,000'),
  _Row('200+10%+5', '225'),
  _Row('10%+200', '200.1'),
  // §6 trigonometry.
  _Row('sin(30)', '0.5'),
  _Row('sin(180)', '0'),
  _Row('cos(60)', '0.5'),
  _Row('tan(90)', 'Undefined'),
  _Row('sin⁻¹(2)', 'Undefined'),
  _Row('sin⁻¹(0.5)', '30'),
  _Row('cos(π)', '−1', angleMode: AngleMode.rad),
  _Row('sin(π÷2)', '1', angleMode: AngleMode.rad),
  _Row('tan(π÷2)', 'Undefined', angleMode: AngleMode.rad),
  // §6 logs, exponentials and roots.
  _Row('ln(e)', '1'),
  _Row('ln(0)', 'Undefined'),
  _Row('log(1000)', '3'),
  _Row('log(0.001)', '−3'),
  _Row('eˣ(0)', '1'),
  _Row('10ˣ(3)', '1,000'),
  _Row('eˣ(710)', 'Number too large'),
  _Row('√(144)', '12'),
  _Row('√(2)', '1.41421356237'),
  _Row('√(−4)', 'Undefined'),
  _Row('∛(−8)', '−2'),
  _Row('√(9+16)', '5'),
  // §6 factorial.
  _Row('5!', '120'),
  _Row('10!', '3,628,800'),
  _Row('171!', 'Number too large'),
  _Row('5.5!', 'Undefined'),
  // §8 formatting.
  _Row('1234567.891', '1,234,567.891'),
  _Row('123456789012345', '123,456,789,012,000'),
  _Row('0.000000001', '0.000000001'),
  _Row('0.0000000001', '1E-10'),
  _Row('−0.5', '−0.5'),
  // §3 auto-closing and §7 errors.
  _Row('(2+3', '5'),
  _Row('2+', 'Invalid input'),
  _Row('×3', 'Invalid input'),
  _Row('2+×3', 'Invalid input'),
];

String _display(String source, {AngleMode angleMode = AngleMode.deg}) {
  final CalcResult result = CalcEngine.evaluate(
    tokenize(source),
    angleMode: angleMode,
  );
  return switch (result) {
    Success(:final Decimal value) => formatNumber(value),
    Failure(:final CalcError error) => error.displayText,
  };
}

void main() {
  test('the §2–§8 table has 40+ rows and every row passes', () {
    expect(_table.length, greaterThanOrEqualTo(40));
    for (final _Row row in _table) {
      expect(
        _display(row.expression, angleMode: row.angleMode),
        row.expected,
        reason: row.expression,
      );
    }
  });

  test('evaluateSource matches evaluate on tokens', () {
    expect(
      CalcEngine.evaluateSource('200+10%'),
      CalcEngine.evaluate(tokenize('200+10%')),
    );
    expect(CalcEngine.evaluateSource('sin(30)'), Success(Decimal.parse('0.5')));
  });

  test('nothing throws: bad text becomes CalcError.syntax', () {
    expect(CalcEngine.evaluateSource('@'), const Failure(CalcError.syntax));
    expect(CalcEngine.evaluateSource('2+'), const Failure(CalcError.syntax));
    expect(
      CalcEngine.evaluate(tokenize('2+×3')),
      const Failure(CalcError.syntax),
    );
    expect(CalcEngine.evaluateSource(''), const Failure(CalcError.syntax));
  });

  test('the facade forwards the angle mode', () {
    expect(
      CalcEngine.evaluateSource('cos(π)', angleMode: AngleMode.rad),
      Success(Decimal.fromInt(-1)),
    );
    expect(CalcEngine.evaluateSource('cos(π)'), isA<Success>());
    expect(_display('sin(30)', angleMode: AngleMode.rad), '−0.988031624093');
  });
}
