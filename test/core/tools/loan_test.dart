import 'package:calculator/core/engine/formatter.dart';
import 'package:calculator/core/tools/loan.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Decimal money(String value) => Decimal.parse(value);

  group('LoanCalculator.calculate', () {
    test('matches the §14 check: 1,000,000 at 12% over 60 months', () {
      final LoanResult result = LoanCalculator.calculate(
        principal: money('1000000'),
        annualRate: money('12'),
        months: 60,
      );

      expect(formatLoanMoney(result.monthlyPayment), '22,244.45');
      expect(formatLoanMoney(result.totalInterest), '334,666.86');
      expect(formatLoanMoney(result.totalPayable), '1,334,666.86');
      expect(result.monthlyPayment.toDouble(), closeTo(22244.4477, 0.0001));
    });

    test('matches the other two rates shown on screen 10', () {
      final LoanResult ten = LoanCalculator.calculate(
        principal: money('1000000'),
        annualRate: money('10'),
        months: 60,
      );
      expect(formatLoanMoney(ten.monthlyPayment), '21,247.04');
      expect(formatLoanMoney(ten.totalInterest), '274,822.68');
      expect(formatLoanMoney(ten.totalPayable), '1,274,822.68');

      final LoanResult fourteen = LoanCalculator.calculate(
        principal: money('1000000'),
        annualRate: money('14'),
        months: 60,
      );
      expect(formatLoanMoney(fourteen.monthlyPayment), '23,268.25');
      expect(formatLoanMoney(fourteen.totalInterest), '396,095.05');
      expect(formatLoanMoney(fourteen.totalPayable), '1,396,095.05');
    });

    test('r = 0 divides the principal evenly with no interest', () {
      final LoanResult result = LoanCalculator.calculate(
        principal: money('120000'),
        annualRate: Decimal.zero,
        months: 12,
      );

      expect(result.monthlyPayment, money('10000'));
      expect(result.totalPayable, money('120000'));
      expect(result.totalInterest, Decimal.zero);
      expect(result.schedule, hasLength(12));
      for (final LoanScheduleRow row in result.schedule) {
        expect(row.interest, Decimal.zero);
        expect(row.payment, money('10000'));
        expect(row.principal, money('10000'));
      }
      expect(result.schedule.last.balance, Decimal.zero);
    });

    test('r = 0 with an uneven division still ends the schedule at 0', () {
      final LoanResult result = LoanCalculator.calculate(
        principal: money('100'),
        annualRate: Decimal.zero,
        months: 3,
      );

      expect(result.monthlyPayment.toDouble(), closeTo(100 / 3, 1e-9));
      expect(result.schedule, hasLength(3));
      expect(result.schedule.last.balance, Decimal.zero);

      final Decimal paid = result.schedule.fold(
        Decimal.zero,
        (Decimal sum, LoanScheduleRow row) => sum + row.payment,
      );
      expect(paid, money('100'));
    });

    test('the schedule has one row per month and repays exactly the '
        'principal', () {
      final LoanResult result = LoanCalculator.calculate(
        principal: money('1000000'),
        annualRate: money('12'),
        months: 60,
      );

      expect(result.schedule, hasLength(60));
      expect(
        result.schedule.map((LoanScheduleRow row) => row.month),
        List<int>.generate(60, (int index) => index + 1),
      );

      final Decimal repaid = result.schedule.fold(
        Decimal.zero,
        (Decimal sum, LoanScheduleRow row) => sum + row.principal,
      );
      expect(repaid.toDouble(), closeTo(1000000, 0.000001));

      expect(result.schedule.first.interest, money('10000'));
      expect(
        result.schedule.first.principal.toDouble(),
        closeTo(12244.4477, 0.0001),
      );
      for (final LoanScheduleRow row in result.schedule) {
        expect(
          row.balance >= Decimal.zero,
          isTrue,
          reason: 'month ${row.month}',
        );
      }
    });

    test('the last month is adjusted so the balance is exactly zero', () {
      final LoanResult result = LoanCalculator.calculate(
        principal: money('1000000'),
        annualRate: money('12'),
        months: 60,
      );

      final LoanScheduleRow last = result.schedule.last;
      expect(last.balance, Decimal.zero);
      expect(last.payment, last.interest + last.principal);
      expect(
        (last.payment - result.monthlyPayment).abs().toDouble(),
        lessThan(0.000001),
      );
    });

    test('a single month is the principal plus one month of interest', () {
      final LoanResult result = LoanCalculator.calculate(
        principal: money('1000'),
        annualRate: money('12'),
        months: 1,
      );

      expect(result.monthlyPayment, money('1010'));
      expect(result.totalInterest, money('10'));
      expect(result.schedule, hasLength(1));
      expect(result.schedule.single.balance, Decimal.zero);
    });

    test('the shares split the total into principal and interest', () {
      final LoanResult result = LoanCalculator.calculate(
        principal: money('1000000'),
        annualRate: money('12'),
        months: 60,
      );

      expect(result.principalShare.toDouble(), closeTo(0.749251, 0.000001));
      expect(result.interestShare.toDouble(), closeTo(0.250749, 0.000001));
      expect(
        (result.principalShare + result.interestShare).toDouble(),
        closeTo(1, 1e-12),
      );
    });

    test('a zero loan gives zero shares instead of dividing by zero', () {
      final LoanResult result = LoanCalculator.calculate(
        principal: Decimal.zero,
        annualRate: money('12'),
        months: 12,
      );

      expect(result.monthlyPayment, Decimal.zero);
      expect(result.totalPayable, Decimal.zero);
      expect(result.principalShare, Decimal.zero);
      expect(result.interestShare, Decimal.zero);
      expect(result.schedule.last.balance, Decimal.zero);
    });

    test('rejects a tenure below one month', () {
      expect(
        () => LoanCalculator.calculate(
          principal: money('1000'),
          annualRate: money('12'),
          months: 0,
        ),
        throwsArgumentError,
      );
    });

    test('rejects a negative principal or rate', () {
      expect(
        () => LoanCalculator.calculate(
          principal: money('-1'),
          annualRate: money('12'),
          months: 12,
        ),
        throwsArgumentError,
      );
      expect(
        () => LoanCalculator.calculate(
          principal: money('1000'),
          annualRate: money('-1'),
          months: 12,
        ),
        throwsArgumentError,
      );
    });
  });

  group('formatLoanMoney', () {
    test('always shows two decimals with grouping', () {
      expect(formatLoanMoney(money('22244.4477')), '22,244.45');
      expect(formatLoanMoney(money('1000000')), '1,000,000.00');
      expect(formatLoanMoney(Decimal.zero), '0.00');
    });

    test('uses the typographic minus and the locale marks', () {
      expect(formatLoanMoney(money('-1234.5')), '−1,234.50');
      expect(
        formatLoanMoney(
          money('22244.4477'),
          options: const NumberFormatOptions(
            decimalSeparator: ',',
            groupSeparator: '.',
          ),
        ),
        '22.244,45',
      );
      expect(
        formatLoanMoney(
          money('22244.4477'),
          options: const NumberFormatOptions(useGrouping: false),
        ),
        '22244.45',
      );
    });
  });
}
