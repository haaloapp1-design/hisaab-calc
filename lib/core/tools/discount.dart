import 'package:decimal/decimal.dart';

/// Working scale for the discount divisions.
const int _scale = 32;

/// The result of a price after a discount and a tax (BUSINESS_LOGIC §14).
final class DiscountResult {
  const DiscountResult({
    required this.price,
    required this.discountPercent,
    required this.taxPercent,
    required this.afterDiscount,
    required this.saved,
    required this.tax,
    required this.finalPrice,
  });

  /// The original price.
  final Decimal price;

  /// The percentage taken off [price].
  final Decimal discountPercent;

  /// The percentage added on the discounted price.
  final Decimal taxPercent;

  /// `price × (1 − discountPercent / 100)`.
  final Decimal afterDiscount;

  /// `price − afterDiscount`.
  final Decimal saved;

  /// `afterDiscount × taxPercent / 100`.
  final Decimal tax;

  /// `afterDiscount × (1 + taxPercent / 100)`.
  final Decimal finalPrice;

  @override
  String toString() =>
      'DiscountResult(afterDiscount: $afterDiscount, saved: $saved, '
      'tax: $tax, finalPrice: $finalPrice)';
}

/// The discount / tax formulas of BUSINESS_LOGIC §14.
///
/// Negative prices or percentages are programming errors; the page's fields
/// cannot produce them. A discount above 100 % follows the formula, so the
/// discounted price can go negative instead of the UI throwing.
abstract final class DiscountCalculator {
  /// Calculates the discount, the tax and the final price.
  static DiscountResult calculate({
    required Decimal price,
    required Decimal discountPercent,
    required Decimal taxPercent,
  }) {
    if (price < Decimal.zero) {
      throw ArgumentError.value(price, 'price', 'must not be negative');
    }
    if (discountPercent < Decimal.zero) {
      throw ArgumentError.value(
        discountPercent,
        'discountPercent',
        'must not be negative',
      );
    }
    if (taxPercent < Decimal.zero) {
      throw ArgumentError.value(
        taxPercent,
        'taxPercent',
        'must not be negative',
      );
    }

    final Decimal afterDiscount = _divide(
      price * (_hundred - discountPercent),
      _hundred,
    );
    final Decimal tax = _divide(afterDiscount * taxPercent, _hundred);

    return DiscountResult(
      price: price,
      discountPercent: discountPercent,
      taxPercent: taxPercent,
      afterDiscount: afterDiscount,
      saved: price - afterDiscount,
      tax: tax,
      finalPrice: afterDiscount + tax,
    );
  }

  static final Decimal _hundred = Decimal.fromInt(100);

  static Decimal _divide(Decimal a, Decimal b) =>
      (a / b).toDecimal(scaleOnInfinitePrecision: _scale);
}
