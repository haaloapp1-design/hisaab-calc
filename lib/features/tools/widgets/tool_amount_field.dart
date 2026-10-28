import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/currency/currency_amount.dart';
import '../../../core/engine/formatter.dart';
import 'tool_field.dart';

/// A grouped decimal input on a tool page (screen 10 pattern).
///
/// The field keeps its own [TextEditingController] because typing should not
/// rebuild the page on every key; each change is reported as a
/// [CurrencyAmount] and the page recalculates from [CurrencyAmount.value].
class ToolAmountField extends StatefulWidget {
  const ToolAmountField({
    super.key,
    required this.label,
    required this.fieldKey,
    required this.initialAmount,
    required this.options,
    required this.onChanged,
  });

  /// The 13 px label above the box, e.g. `Loan amount (PKR)`.
  final String label;

  /// The key on the inner [TextField], used by the tests.
  final Key fieldKey;

  final CurrencyAmount initialAmount;
  final NumberFormatOptions options;
  final ValueChanged<CurrencyAmount> onChanged;

  @override
  State<ToolAmountField> createState() => _ToolAmountFieldState();
}

class _ToolAmountFieldState extends State<ToolAmountField> {
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
    return ToolField(
      label: widget.label,
      child: ToolFieldBox(
        child: ToolTextField(
          fieldKey: widget.fieldKey,
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            _ToolAmountFormatter(widget.options),
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
class _ToolAmountFormatter extends TextInputFormatter {
  const _ToolAmountFormatter(this.options);

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
