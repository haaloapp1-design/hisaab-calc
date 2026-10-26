import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/currency/currency_amount.dart';
import '../../../core/engine/formatter.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// The 52 px amount line on the blue area of screen 08.
///
/// The field keeps its own [TextEditingController] because typing should not
/// rebuild the whole page on every key; each change is reported as a
/// [CurrencyAmount] and the controller persists it.
class CurrencyAmountField extends StatefulWidget {
  const CurrencyAmountField({
    super.key,
    required this.initialAmount,
    required this.options,
    required this.onChanged,
  });

  final CurrencyAmount initialAmount;
  final NumberFormatOptions options;
  final ValueChanged<CurrencyAmount> onChanged;

  @override
  State<CurrencyAmountField> createState() => _CurrencyAmountFieldState();
}

class _CurrencyAmountFieldState extends State<CurrencyAmountField> {
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
    final AppPalette palette = AppPalette.of(context);

    return SizedBox(
      height: AppSizes.currencyAmountHeight,
      child: TextField(
        key: const Key('currency-amount'),
        controller: _controller,
        textAlign: TextAlign.right,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
        maxLines: 1,
        style: AppTypography.currencyAmount.copyWith(color: palette.onPrimary),
        cursorColor: palette.onPrimary,
        inputFormatters: <TextInputFormatter>[
          _CurrencyAmountFormatter(widget.options),
        ],
        decoration: InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          hintText: '0',
          hintStyle: AppTypography.currencyAmount.copyWith(
            color: palette.onPrimaryMuted,
          ),
        ),
        onChanged: (String text) => widget.onChanged(
          CurrencyAmount.fromInput(text, options: widget.options),
        ),
      ),
    );
  }
}

/// Keeps the field showing the grouped amount while the user types.
///
/// The caret sits at the end after every edit; the amount is numeric and the
/// field is right-aligned, so this matches how the screen is used.
class _CurrencyAmountFormatter extends TextInputFormatter {
  const _CurrencyAmountFormatter(this.options);

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
