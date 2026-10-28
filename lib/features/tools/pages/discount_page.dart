import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency/currency_amount.dart';
import '../../../core/engine/formatter.dart';
import '../../../core/tools/discount.dart';
import '../../../core/tools/tool_format.dart';
import '../../../theme/app_tokens.dart';
import '../../settings/settings_controller.dart';
import '../../settings/settings_format.dart';
import '../../settings/settings_model.dart';
import '../tool_scaffold.dart';
import '../widgets/tool_amount_field.dart';
import '../widgets/tool_summary_card.dart';

/// The Discount and tax tool (SPEC §6, screen-10 pattern).
///
/// The page owns the price, the discount and the tax; [DiscountCalculator]
/// produces the saved amount, the discounted price, the tax and the final
/// price.
class DiscountPage extends ConsumerStatefulWidget {
  const DiscountPage({super.key});

  @override
  ConsumerState<DiscountPage> createState() => _DiscountPageState();
}

class _DiscountPageState extends ConsumerState<DiscountPage> {
  CurrencyAmount _price = const CurrencyAmount('1000');
  CurrencyAmount _discount = const CurrencyAmount('20');
  CurrencyAmount _tax = const CurrencyAmount('17');

  DiscountResult get _result => DiscountCalculator.calculate(
    price: _price.value,
    discountPercent: _discount.value,
    taxPercent: _tax.value,
  );

  @override
  Widget build(BuildContext context) {
    final Settings settings = ref.watch(settingsProvider);
    final NumberFormatOptions options = numberFormatFor(settings);
    final DiscountResult result = _result;

    return ToolScaffold(
      title: 'Discount and tax',
      resultLabel: 'Final price',
      resultValue: formatToolNumber(result.finalPrice, options: options),
      resultCaption:
          'After ${_discount.display(options: options)}% off and '
          '${_tax.display(options: options)}% tax',
      onShare: _share,
      actionLabel: 'Copy result',
      onAction: _copyResult,
      children: <Widget>[
        ToolAmountField(
          label: 'Price (PKR)',
          fieldKey: const Key('discount-price'),
          initialAmount: _price,
          options: options,
          onChanged: (CurrencyAmount amount) => setState(() => _price = amount),
        ),
        const SizedBox(height: AppSizes.toolSheetGap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ToolAmountField(
                label: 'Discount (%)',
                fieldKey: const Key('discount-percent'),
                initialAmount: _discount,
                options: options,
                onChanged: (CurrencyAmount amount) =>
                    setState(() => _discount = amount),
              ),
            ),
            const SizedBox(width: AppSizes.toolTenureGap),
            Expanded(
              child: ToolAmountField(
                label: 'Tax / GST (%)',
                fieldKey: const Key('discount-tax'),
                initialAmount: _tax,
                options: options,
                onChanged: (CurrencyAmount amount) =>
                    setState(() => _tax = amount),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.toolSheetGap),
        ToolSummaryCard(
          rows: <ToolSummaryRow>[
            ToolSummaryRow(
              label: 'You save',
              value: formatToolNumber(result.saved, options: options),
              valueKey: const Key('discount-saved'),
            ),
            ToolSummaryRow(
              label: 'After discount',
              value: formatToolNumber(result.afterDiscount, options: options),
              valueKey: const Key('discount-after'),
            ),
            ToolSummaryRow(
              label: 'Tax',
              value: formatToolNumber(result.tax, options: options),
              valueKey: const Key('discount-tax-amount'),
            ),
          ],
          total: ToolSummaryRow(
            label: 'Final price',
            value: formatToolNumber(result.finalPrice, options: options),
            valueKey: const Key('discount-final'),
          ),
        ),
      ],
    );
  }

  Future<void> _copyResult() => _copy(
    formatToolNumber(
      _result.finalPrice,
      options: numberFormatFor(ref.read(settingsProvider)),
    ),
  );

  Future<void> _share() async {
    final NumberFormatOptions options = numberFormatFor(
      ref.read(settingsProvider),
    );
    final DiscountResult result = _result;
    await _copy(
      <String>[
        'Discount and tax',
        'Price: ${formatToolNumber(result.price, options: options)}',
        'Discount: ${_discount.display(options: options)}%',
        'Tax: ${_tax.display(options: options)}%',
        'You save: ${formatToolNumber(result.saved, options: options)}',
        'After discount: '
            '${formatToolNumber(result.afterDiscount, options: options)}',
        'Tax amount: ${formatToolNumber(result.tax, options: options)}',
        'Final price: ${formatToolNumber(result.finalPrice, options: options)}',
      ].join('\n'),
    );
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Copied')));
  }
}
