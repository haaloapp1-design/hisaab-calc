import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency/currency_amount.dart';
import '../../../core/engine/formatter.dart';
import '../../../core/tools/bmi.dart';
import '../../../core/tools/tool_format.dart';
import '../../../theme/app_tokens.dart';
import '../../settings/settings_controller.dart';
import '../../settings/settings_format.dart';
import '../../settings/settings_model.dart';
import '../tool_scaffold.dart';
import '../widgets/tool_amount_field.dart';
import '../widgets/tool_choice_chips.dart';
import '../widgets/tool_summary_card.dart';

/// The BMI tool (SPEC §6, screen-10 pattern).
///
/// The page owns the metric and imperial fields separately, so switching units
/// keeps each set; [BmiCalculator] does the conversions and the WHO band.
class BmiPage extends ConsumerStatefulWidget {
  const BmiPage({super.key});

  @override
  ConsumerState<BmiPage> createState() => _BmiPageState();
}

class _BmiPageState extends ConsumerState<BmiPage> {
  bool _metric = true;
  CurrencyAmount _heightCm = const CurrencyAmount('170');
  CurrencyAmount _weightKg = const CurrencyAmount('70');
  CurrencyAmount _feet = const CurrencyAmount('5');
  CurrencyAmount _inches = const CurrencyAmount('7');
  CurrencyAmount _pounds = const CurrencyAmount('154');

  BmiResult? get _result => _metric
      ? BmiCalculator.metric(
          heightCm: _heightCm.value,
          weightKg: _weightKg.value,
        )
      : BmiCalculator.imperial(
          feet: _feet.value,
          inches: _inches.value,
          pounds: _pounds.value,
        );

  @override
  Widget build(BuildContext context) {
    final Settings settings = ref.watch(settingsProvider);
    final NumberFormatOptions options = numberFormatFor(settings);
    final BmiResult? result = _result;

    return ToolScaffold(
      title: 'BMI',
      resultLabel: 'BMI',
      resultValue: result == null
          ? '—'
          : formatToolNumber(result.bmi, options: options),
      resultCaption: result == null
          ? 'Enter a height and weight'
          : '${result.category.label} · for adults',
      onShare: _share,
      actionLabel: 'Copy result',
      onAction: _copyResult,
      children: <Widget>[
        ToolChoiceChips(
          labels: const <String>['cm / kg', 'ft + in / lb'],
          selectedIndex: _metric ? 0 : 1,
          onSelected: (int index) => setState(() => _metric = index == 0),
          keyPrefix: 'bmi-unit',
        ),
        const SizedBox(height: AppSizes.toolSheetGap),
        if (_metric)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: ToolAmountField(
                  key: const ValueKey<String>('bmi-height-cm'),
                  label: 'Height (cm)',
                  fieldKey: const Key('bmi-height'),
                  initialAmount: _heightCm,
                  options: options,
                  onChanged: (CurrencyAmount amount) =>
                      setState(() => _heightCm = amount),
                ),
              ),
              const SizedBox(width: AppSizes.toolTenureGap),
              Expanded(
                child: ToolAmountField(
                  key: const ValueKey<String>('bmi-weight-field-kg'),
                  label: 'Weight (kg)',
                  fieldKey: const Key('bmi-weight'),
                  initialAmount: _weightKg,
                  options: options,
                  onChanged: (CurrencyAmount amount) =>
                      setState(() => _weightKg = amount),
                ),
              ),
            ],
          )
        else ...<Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: ToolAmountField(
                  key: const ValueKey<String>('bmi-feet-ft'),
                  label: 'Feet',
                  fieldKey: const Key('bmi-feet'),
                  initialAmount: _feet,
                  options: options,
                  onChanged: (CurrencyAmount amount) =>
                      setState(() => _feet = amount),
                ),
              ),
              const SizedBox(width: AppSizes.toolTenureGap),
              Expanded(
                child: ToolAmountField(
                  key: const ValueKey<String>('bmi-inches-in'),
                  label: 'Inches',
                  fieldKey: const Key('bmi-inches'),
                  initialAmount: _inches,
                  options: options,
                  onChanged: (CurrencyAmount amount) =>
                      setState(() => _inches = amount),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.toolSheetGap),
          ToolAmountField(
            key: const ValueKey<String>('bmi-pounds-lb'),
            label: 'Weight (lb)',
            fieldKey: const Key('bmi-pounds'),
            initialAmount: _pounds,
            options: options,
            onChanged: (CurrencyAmount amount) =>
                setState(() => _pounds = amount),
          ),
        ],
        if (result != null) ...<Widget>[
          const SizedBox(height: AppSizes.toolSheetGap),
          ToolSummaryCard(
            rows: <ToolSummaryRow>[
              ToolSummaryRow(
                label: 'Height',
                value:
                    '${formatToolNumber(result.heightMeters, options: options)} m',
                valueKey: const Key('bmi-height-m'),
              ),
              ToolSummaryRow(
                label: 'Weight',
                value:
                    '${formatToolNumber(result.weightKg, options: options)} kg',
                valueKey: const Key('bmi-weight-kg'),
              ),
            ],
            total: ToolSummaryRow(
              label: 'Category',
              value: result.category.label,
              valueKey: const Key('bmi-category'),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _copyResult() async {
    final NumberFormatOptions options = numberFormatFor(
      ref.read(settingsProvider),
    );
    final BmiResult? result = _result;
    await _copy(
      result == null ? '—' : formatToolNumber(result.bmi, options: options),
    );
  }

  Future<void> _share() async {
    final NumberFormatOptions options = numberFormatFor(
      ref.read(settingsProvider),
    );
    final BmiResult? result = _result;
    if (result == null) {
      await _copy('BMI\nEnter a height and weight');
      return;
    }
    await _copy(
      <String>[
        'BMI',
        'Height: ${formatToolNumber(result.heightMeters, options: options)} m',
        'Weight: ${formatToolNumber(result.weightKg, options: options)} kg',
        'BMI: ${formatToolNumber(result.bmi, options: options)}',
        'Category: ${result.category.label} (adults)',
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
