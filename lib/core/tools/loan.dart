import 'package:decimal/decimal.dart';

import '../engine/formatter.dart';

/// Working scale for the divisions of the EMI formula.
///
/// Money is shown with two decimals, but the schedule is computed from the
/// unrounded instalment, so 32 places leave the last balance at zero to within
/// a rounding error far below one cent.
const int _scale = 32;

/// One month of the amortisation schedule (BUSINESS_LOGIC §14).
///
/// Every amount is in the loan currency and unrounded; the page formats it
/// with [formatLoanMoney]. `payment` is `interest + principal`, which equals
/// the monthly instalment except in the last month, where it is adjusted so
/// the balance reaches exactly zero.
final class LoanScheduleRow {
  const LoanScheduleRow({
    required this.month,
    required this.payment,
    required this.interest,
    required this.principal,
    required this.balance,
  });

  /// 1-based month number.
  final int month;

  /// What is paid that month.
  final Decimal payment;

  /// The interest part of [payment].
  final Decimal interest;

  /// The part of [payment] that repays the principal.
  final Decimal principal;

  /// What is still owed after [payment]; the last row is exactly zero.
  final Decimal balance;

  @override
  bool operator ==(Object other) =>
      other is LoanScheduleRow &&
      other.month == month &&
      other.payment == payment &&
      other.interest == interest &&
      other.principal == principal &&
      other.balance == balance;

  @override
  int get hashCode => Object.hash(month, payment, interest, principal, balance);

  @override
  String toString() =>
      'LoanScheduleRow(month: $month, payment: $payment, '
      'interest: $interest, principal: $principal, balance: $balance)';
}

/// The result of a loan calculation (BUSINESS_LOGIC §14).
final class LoanResult {
  const LoanResult({
    required this.principal,
    required this.monthlyPayment,
    required this.totalPayable,
    required this.totalInterest,
    required this.schedule,
  });

  /// The amount borrowed.
  final Decimal principal;

  /// The EMI: the instalment every month, before display rounding.
  final Decimal monthlyPayment;

  /// `EMI × months`.
  final Decimal totalPayable;

  /// `totalPayable − principal`.
  final Decimal totalInterest;

  /// One row per month, in order; the last balance is exactly zero.
  final List<LoanScheduleRow> schedule;

  /// The share of [totalPayable] that repays the principal, between 0 and 1.
  ///
  /// The page draws the principal/interest bar from this; a zero loan gives
  /// zero instead of dividing by zero.
  Decimal get principalShare => totalPayable == Decimal.zero
      ? Decimal.zero
      : _divide(principal, totalPayable);

  /// The share of [totalPayable] that is interest, between 0 and 1.
  Decimal get interestShare => totalPayable == Decimal.zero
      ? Decimal.zero
      : _divide(totalInterest, totalPayable);

  @override
  String toString() =>
      'LoanResult(monthlyPayment: $monthlyPayment, '
      'totalPayable: $totalPayable, totalInterest: $totalInterest)';
}

/// The loan / EMI maths of BUSINESS_LOGIC §14.
///
/// `r = R / 12 / 100`; if `r == 0` the instalment is `P / n`, otherwise
/// `EMI = P × r × (1 + r)^n / ((1 + r)^n − 1)`. The schedule walks the balance
/// month by month and the final row is adjusted so it ends at exactly zero.
abstract final class LoanCalculator {
  /// Calculates the instalment, the totals and the monthly schedule.
  ///
  /// [months] must be at least 1; [principal] and [annualRate] must not be
  /// negative. The page clamps its fields before calling, so a bad value here
  /// is a programming error.
  static LoanResult calculate({
    required Decimal principal,
    required Decimal annualRate,
    required int months,
  }) {
    if (months < 1) {
      throw ArgumentError.value(months, 'months', 'must be at least 1');
    }
    if (principal < Decimal.zero) {
      throw ArgumentError.value(principal, 'principal', 'must not be negative');
    }
    if (annualRate < Decimal.zero) {
      throw ArgumentError.value(
        annualRate,
        'annualRate',
        'must not be negative',
      );
    }

    final Decimal monthlyRate = _divide(annualRate, Decimal.fromInt(1200));
    final Decimal emi = monthlyRate == Decimal.zero
        ? _divide(principal, Decimal.fromInt(months))
        : _emi(principal, monthlyRate, months);
    final Decimal total = emi * Decimal.fromInt(months);

    return LoanResult(
      principal: principal,
      monthlyPayment: emi,
      totalPayable: total,
      totalInterest: total - principal,
      schedule: List<LoanScheduleRow>.unmodifiable(
        _schedule(principal, monthlyRate, emi, months),
      ),
    );
  }

  /// `P × r × (1 + r)^n / ((1 + r)^n − 1)`, with `r > 0`.
  static Decimal _emi(Decimal principal, Decimal monthlyRate, int months) {
    final Decimal growth = (Decimal.one + monthlyRate)
        .pow(months)
        .toDecimal(scaleOnInfinitePrecision: _scale);
    return _divide(principal * monthlyRate * growth, growth - Decimal.one);
  }

  /// Walks the balance; the last row repays whatever is left, so it ends at 0.
  static List<LoanScheduleRow> _schedule(
    Decimal principal,
    Decimal monthlyRate,
    Decimal emi,
    int months,
  ) {
    final List<LoanScheduleRow> rows = <LoanScheduleRow>[];
    Decimal balance = principal;

    for (int month = 1; month <= months; month++) {
      final Decimal interest = balance * monthlyRate;
      final bool last = month == months;
      final Decimal principalPart = last ? balance : emi - interest;
      final Decimal payment = last ? balance + interest : emi;
      balance -= principalPart;

      rows.add(
        LoanScheduleRow(
          month: month,
          payment: payment,
          interest: interest,
          principal: principalPart,
          balance: balance,
        ),
      );
    }

    return rows;
  }
}

/// Formats a loan amount like the rest of the app's money: two decimals with
/// the Settings grouping and locale marks (`22,244.45`).
String formatLoanMoney(
  Decimal value, {
  NumberFormatOptions options = const NumberFormatOptions(),
}) => formatNumber(
  value,
  options: NumberFormatOptions(
    decimalPlaces: 2,
    useGrouping: options.useGrouping,
    decimalSeparator: options.decimalSeparator,
    groupSeparator: options.groupSeparator,
  ),
);

/// Divides at the formula's working scale, so `Decimal` never truncates.
Decimal _divide(Decimal a, Decimal b) =>
    (a / b).toDecimal(scaleOnInfinitePrecision: _scale);
