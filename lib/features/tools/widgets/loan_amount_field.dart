import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/currency/currency_amount.dart';
import '../../../core/engine/formatter.dart';
import 'loan_field.dart';

/// The loan amount input on screen 10.
///
/// The field keeps its own [TextEditingController] because typing should not
/// rebuild the page on every key; each change is reported as a
/// [CurrencyAmount] and the page recalculates the loan from it.
class LoanAmountField extends StatefulWidget {
  const LoanAmountField({
    super.key,
    required this.initialAmount,
    required this.options,
    required this.onChanged,
  });

  final CurrencyAmount initialAmount;
  final NumberFormatOptions options;
  final ValueChanged<CurrencyAmount> onChanged;

  @override
  State<LoanAmountField> createState() => _LoanAmountFieldState();
}

class _LoanAmountFieldState extends State<LoanAmountField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialAmount.display(options: widget.options),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoanField(
      label: 'Loan amount (PKR)',
      child: LoanFieldBox(
        child: LoanTextField(
          fieldKey: const Key('loan-amount'),
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            _LoanAmountFormatter(widget.options),
          ],
          onChanged: (String text) => widget.onChanged(
            CurrencyAmount.fromInput(text, options: widget.options),
          ),
        ),
      ),
    );
  }
}

/// Keeps the field showing the grouped amount while the user types.
///
/// It mirrors the currency amount field: the caret sits at the end after every
/// edit, and the amount is numeric, so this matches how the field is used.
class _LoanAmountFormatter extends TextInputFormatter {
  const _LoanAmountFormatter(this.options);

  final NumberFormatOptions options;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final CurrencyAmount amount = CurrencyAmount.fromInput(
      newValue.text,
      options: options,
    );
    final String text = amount.display(options: options);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
