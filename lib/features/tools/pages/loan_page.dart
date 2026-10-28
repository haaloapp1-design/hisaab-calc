import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency/currency_amount.dart';
import '../../../core/engine/formatter.dart';
import '../../../core/tools/loan.dart';
import '../../../theme/app_tokens.dart';
import '../../settings/settings_controller.dart';
import '../../settings/settings_format.dart';
import '../../settings/settings_model.dart';
import '../tool_scaffold.dart';
import '../widgets/loan_breakdown.dart';
import '../widgets/loan_rate_chips.dart';
import '../widgets/loan_schedule_sheet.dart';
import '../widgets/loan_tenure_row.dart';
import '../widgets/tool_amount_field.dart';

/// The Loan / EMI tool (SPEC §6, screen `10-loan-emi.html`).
///
/// The page owns the three inputs (amount, annual rate, tenure + unit) and
/// rebuilds the result on every change. All maths comes from [LoanCalculator];
/// the widgets only format and dispatch.
class LoanPage extends ConsumerStatefulWidget {
  const LoanPage({super.key});

  /// The design opens on a one-million loan at 12 % for five years.
  static const int defaultAmount = 1000000;
  static const int defaultRate = 12;
  static const int defaultYears = 5;

  /// The currency the design shows in the caption and the amount label.
  static const String currencyCode = 'PKR';

  @override
  ConsumerState<LoanPage> createState() => _LoanPageState();
}

class _LoanPageState extends ConsumerState<LoanPage> {
  CurrencyAmount _amount = const CurrencyAmount('1000000');
  int _rate = LoanPage.defaultRate;
  int _tenure = LoanPage.defaultYears;
  LoanTenureUnit _unit = LoanTenureUnit.years;
  late final TextEditingController _tenureController = TextEditingController(
    text: '${LoanPage.defaultYears}',
  );

  @override
  void dispose() {
    _tenureController.dispose();
    super.dispose();
  }

  /// The engine's tenure; an empty field still means a one-month loan.
  int get _months => math.max(1, _unit.toMonths(_tenure));

  LoanResult get _result => LoanCalculator.calculate(
    principal: _amount.value,
    annualRate: Decimal.fromInt(_rate),
    months: _months,
  );

  @override
  Widget build(BuildContext context) {
    final Settings settings = ref.watch(settingsProvider);
    final NumberFormatOptions options = numberFormatFor(settings);
    final LoanResult result = _result;

    return ToolScaffold(
      title: 'Loan / EMI',
      resultLabel: 'Monthly instalment',
      resultValue: formatLoanMoney(result.monthlyPayment, options: options),
      resultCaption:
          '${LoanPage.currencyCode} for $_months ${_months == 1 ? 'month' : 'months'}',
      onShare: _share,
      actionLabel: 'Show monthly schedule',
      onAction: () =>
          showLoanScheduleSheet(context, result: result, options: options),
      children: <Widget>[
        ToolAmountField(
          label: 'Loan amount (PKR)',
          fieldKey: const Key('loan-amount'),
          initialAmount: _amount,
          options: options,
          onChanged: (CurrencyAmount amount) =>
              setState(() => _amount = amount),
        ),
        const SizedBox(height: AppSizes.toolSheetGap),
        LoanRateChips(
          selected: _rate,
          onSelected: (int rate) => setState(() => _rate = rate),
        ),
        const SizedBox(height: AppSizes.toolSheetGap),
        LoanTenureRow(
          controller: _tenureController,
          unit: _unit,
          onChanged: _onTenureChanged,
          onUnitChanged: _onUnitChanged,
        ),
        const SizedBox(height: AppSizes.toolSheetGap),
        LoanBreakdown(result: result, options: options),
      ],
    );
  }

  void _onTenureChanged(String text) {
    final int value = int.tryParse(text) ?? 0;
    setState(() => _tenure = value);
  }

  void _onUnitChanged(LoanTenureUnit unit) {
    setState(() {
      _unit = unit;
      // A shorter unit accepts fewer digits; trim instead of leaving a value
      // the field could no longer hold.
      final String text = _tenureController.text;
      if (text.length > unit.maxDigits) {
        final String trimmed = text.substring(0, unit.maxDigits);
        _tenureController.value = TextEditingValue(
          text: trimmed,
          selection: TextSelection.collapsed(offset: trimmed.length),
        );
        _tenure = int.tryParse(trimmed) ?? 0;
      }
    });
  }

  /// Copies a plain-text summary of the current loan to the clipboard.
  Future<void> _share() async {
    final NumberFormatOptions options = numberFormatFor(
      ref.read(settingsProvider),
    );
    final LoanResult result = _result;
    final String tenure = '$_months ${_months == 1 ? 'month' : 'months'}';
    final String text = <String>[
      'Loan / EMI',
      'Loan amount: ${LoanPage.currencyCode} '
          '${formatLoanMoney(result.principal, options: options)}',
      'Interest rate: $_rate% per year',
      'Tenure: $tenure',
      'Monthly instalment: ${LoanPage.currencyCode} '
          '${formatLoanMoney(result.monthlyPayment, options: options)}',
      'Total interest: ${LoanPage.currencyCode} '
          '${formatLoanMoney(result.totalInterest, options: options)}',
      'Total payable: ${LoanPage.currencyCode} '
          '${formatLoanMoney(result.totalPayable, options: options)}',
    ].join('\n');

    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Copied')));
  }
}
