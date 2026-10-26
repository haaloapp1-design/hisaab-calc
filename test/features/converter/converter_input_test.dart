import 'package:calculator/core/engine/formatter.dart';
import 'package:calculator/features/converter/converter_input.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts empty and reads as zero', () {
    const ConverterInput input = ConverterInput();
    expect(input.isEmpty, isTrue);
    expect(input.value, Decimal.zero);
    expect(input.display(), '0');
  });

  test('builds a number from digits and replaces a leading zero', () {
    ConverterInput input = const ConverterInput();
    input = input.digit('0');
    expect(input.source, '0');
    input = input.digit('5');
    expect(input.source, '5');
    input = input.digit('2');
    expect(input.source, '52');
    expect(input.value, Decimal.fromInt(52));
  });

  test('00 appends two zeros, and one while the input is still zero', () {
    expect(const ConverterInput().doubleZero().source, '0');
    expect(const ConverterInput('5').doubleZero().source, '500');
    expect(const ConverterInput('12.5').doubleZero().source, '12.500');
  });

  test('accepts one decimal point', () {
    expect(const ConverterInput().dot().source, '0.');
    expect(const ConverterInput('-').dot().source, '-0.');
    expect(const ConverterInput('5').dot().source, '5.');
    expect(const ConverterInput('5.').dot().source, '5.');
    expect(const ConverterInput('5.2').dot().source, '5.2');
    expect(const ConverterInput('1.5').value, Decimal.parse('1.5'));
  });

  test('toggle sign flips a real value and ignores zero', () {
    expect(const ConverterInput().toggleSign().source, '');
    expect(const ConverterInput('0').toggleSign().source, '0');
    expect(const ConverterInput('5').toggleSign().source, '-5');
    expect(const ConverterInput('-5').toggleSign().source, '5');
    expect(const ConverterInput('5.').toggleSign().source, '-5.');
    expect(const ConverterInput('-5').value, Decimal.fromInt(-5));
  });

  test('backspace drops one character and clear empties', () {
    expect(const ConverterInput('123').backspace().source, '12');
    expect(const ConverterInput('5.').backspace().source, '5');
    expect(const ConverterInput().backspace().source, '');
    expect(const ConverterInput('123').clear().source, '');
  });

  test('stops at the maximum number of digits', () {
    ConverterInput input = const ConverterInput();
    for (int i = 0; i < ConverterInput.maxDigits; i++) {
      input = input.digit('7');
    }
    expect(input.source, '777777777777777');
    expect(input.digit('7').source, input.source);
    expect(input.dot().source, '${input.source}.');
    expect(input.dot().digit('7').source, input.dot().source);
  });

  test('display groups and localises the typed digits', () {
    const ConverterInput grouped = ConverterInput('5000');
    expect(grouped.display(), '5,000');
    expect(
      grouped.display(options: const NumberFormatOptions(useGrouping: false)),
      '5000',
    );
    expect(
      grouped.display(
        options: const NumberFormatOptions(
          decimalSeparator: ',',
          groupSeparator: '.',
        ),
      ),
      '5.000',
    );
    expect(const ConverterInput('-1234.5').display(), '−1,234.5');
    expect(const ConverterInput('5.').display(), '5.');
  });

  test('compares by the typed source', () {
    expect(const ConverterInput('5'), const ConverterInput('5'));
    expect(const ConverterInput('5'), isNot(const ConverterInput('6')));
    expect(const ConverterInput('5').hashCode, '5'.hashCode);
    expect(const ConverterInput('5').toString(), 'ConverterInput(5)');
  });
}
