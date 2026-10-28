import 'package:calculator/core/tools/discount.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Decimal d(String source) => Decimal.parse(source);

  test('1000 with 20% off and 17% tax', () {
    final DiscountResult result = DiscountCalculator.calculate(
      price: d('1000'),
      discountPercent: d('20'),
      taxPercent: d('17'),
    );

    expect(result.price, d('1000'));
    expect(result.afterDiscount, d('800'));
    expect(result.saved, d('200'));
    expect(result.tax, d('136'));
    expect(result.finalPrice, d('936'));
  });

  test('zero price, discount and tax stay zero', () {
    final DiscountResult result = DiscountCalculator.calculate(
      price: Decimal.zero,
      discountPercent: Decimal.zero,
      taxPercent: Decimal.zero,
    );

    expect(result.afterDiscount, Decimal.zero);
    expect(result.saved, Decimal.zero);
    expect(result.tax, Decimal.zero);
    expect(result.finalPrice, Decimal.zero);
  });

  test('a 100% discount makes the price free', () {
    final DiscountResult result = DiscountCalculator.calculate(
      price: d('1000'),
      discountPercent: d('100'),
      taxPercent: d('17'),
    );

    expect(result.afterDiscount, Decimal.zero);
    expect(result.saved, d('1000'));
    expect(result.tax, Decimal.zero);
    expect(result.finalPrice, Decimal.zero);
  });

  test('a decimal discount and tax keep exact money', () {
    final DiscountResult result = DiscountCalculator.calculate(
      price: d('99.99'),
      discountPercent: d('12.5'),
      taxPercent: d('5'),
    );

    expect(result.afterDiscount, d('87.49125'));
    expect(result.saved, d('12.49875'));
    expect(result.tax, d('4.3745625'));
    expect(result.finalPrice, d('91.8658125'));
  });

  test('no tax leaves the discounted price unchanged', () {
    final DiscountResult result = DiscountCalculator.calculate(
      price: d('250'),
      discountPercent: d('10'),
      taxPercent: Decimal.zero,
    );

    expect(result.tax, Decimal.zero);
    expect(result.finalPrice, d('225'));
  });

  test('negative inputs are rejected', () {
    expect(
      () => DiscountCalculator.calculate(
        price: d('-1'),
        discountPercent: Decimal.zero,
        taxPercent: Decimal.zero,
      ),
      throwsArgumentError,
    );
    expect(
      () => DiscountCalculator.calculate(
        price: d('1'),
        discountPercent: d('-1'),
        taxPercent: Decimal.zero,
      ),
      throwsArgumentError,
    );
    expect(
      () => DiscountCalculator.calculate(
        price: d('1'),
        discountPercent: Decimal.zero,
        taxPercent: d('-1'),
      ),
      throwsArgumentError,
    );
  });
}
