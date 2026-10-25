import 'package:calculator/core/engine/token.dart';
import 'package:calculator/core/input/calc_key.dart';
import 'package:calculator/core/input/input_buffer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalcKey digit', () {
    test('digit keys report 0–9 and other keys report null', () {
      expect(CalcKey.digit0.digit, 0);
      expect(CalcKey.digit5.digit, 5);
      expect(CalcKey.digit9.digit, 9);
      expect(CalcKey.add.digit, isNull);
      expect(CalcKey.clear.digit, isNull);
    });
  });

  group('CalcKey operatorType', () {
    test('maps the arithmetic and power keys', () {
      expect(CalcKey.add.operatorType, OperatorType.add);
      expect(CalcKey.subtract.operatorType, OperatorType.subtract);
      expect(CalcKey.multiply.operatorType, OperatorType.multiply);
      expect(CalcKey.divide.operatorType, OperatorType.divide);
      expect(CalcKey.power.operatorType, OperatorType.power);
      expect(CalcKey.root.operatorType, OperatorType.root);
    });

    test('other keys are not operators', () {
      expect(CalcKey.digit7.operatorType, isNull);
      expect(CalcKey.sin.operatorType, isNull);
      expect(CalcKey.percent.operatorType, isNull);
    });
  });

  group('CalcKey functionName', () {
    test('every function key maps to the engine name', () {
      expect(CalcKey.sin.functionName, 'sin');
      expect(CalcKey.cos.functionName, 'cos');
      expect(CalcKey.tan.functionName, 'tan');
      expect(CalcKey.sinInverse.functionName, 'sin⁻¹');
      expect(CalcKey.cosInverse.functionName, 'cos⁻¹');
      expect(CalcKey.tanInverse.functionName, 'tan⁻¹');
      expect(CalcKey.ln.functionName, 'ln');
      expect(CalcKey.log.functionName, 'log');
      expect(CalcKey.exp.functionName, 'eˣ');
      expect(CalcKey.tenPow.functionName, '10ˣ');
      expect(CalcKey.sqrt.functionName, '√');
      expect(CalcKey.cbrt.functionName, '∛');
    });

    test('non-function keys report null', () {
      expect(CalcKey.pi.functionName, isNull);
      expect(CalcKey.factorial.functionName, isNull);
    });
  });

  group('CalcKey postfixType and constant', () {
    test('maps postfix keys', () {
      expect(CalcKey.percent.postfixType, PostfixType.percent);
      expect(CalcKey.factorial.postfixType, PostfixType.factorial);
      expect(CalcKey.square.postfixType, PostfixType.square);
      expect(CalcKey.cube.postfixType, PostfixType.cube);
      expect(CalcKey.reciprocal.postfixType, PostfixType.reciprocal);
      expect(CalcKey.digit2.postfixType, isNull);
    });

    test('maps the constant keys', () {
      expect(CalcKey.pi.constant, MathConstant.pi);
      expect(CalcKey.e.constant, MathConstant.e);
      expect(CalcKey.ans.constant, isNull);
    });
  });

  group('CalcKey can drive InputBuffer', () {
    test('function key inserts a whole "sin(" token', () {
      final InputBuffer buffer = const InputBuffer.empty()
          .appendFunction(CalcKey.sin.functionName!);

      expect(buffer.tokens, <Token>[const FunctionToken('sin')]);
    });
  });
}
