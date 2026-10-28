import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency/currency_amount.dart';
import '../../../core/engine/formatter.dart';
import '../../../core/tools/percentage.dart';
import '../../../core/tools/tool_format.dart';
import '../../../theme/app_tokens.dart';
import '../../settings/settings_controller.dart';
import '../../settings/settings_format.dart';
import '../../settings/settings_model.dart';
import '../tool_scaffold.dart';
import '../widgets/tool_amount_field.dart';
import '../widgets/tool_choice_chips.dart';
import '../widgets/tool_summary_card.dart';

/// The three percentage questions from SPEC §6.
enum PercentageMode { of, ratio, change }

/// The Percentage tool (SPEC §6, screen-10 pattern).
///
/// One page answers `X% of Y`, `X is what % of Y` and the change from X to Y;
/// the mode picks the formula, while every number comes from
/// [PercentageCalculator].
class PercentagePage extends ConsumerStatefulWidget {
  const PercentagePage({super.key});

  @override
  ConsumerState<PercentagePage> createState() => _PercentagePageState();
}

class _PercentagePageState extends ConsumerState<PercentagePage> {
  PercentageMode _mode = PercentageMode.of;
  CurrencyAmount _x = const CurrencyAmount('15');
  CurrencyAmount _y = const CurrencyAmount('200');

  static const List<String> _labels = <String>[
    'X% of Y',
    'X is ?%',
    '% change',
  ];

  String get _xLabel => switch (_mode) {
    PercentageMode.of => 'Percent (X)',
    PercentageMode.ratio => 'Part (X)',
    PercentageMode.change => 'From (X)',
  };

  String get _yLabel => switch (_mode) {
    PercentageMode.of => 'Value (Y)',
    PercentageMode.ratio => 'Whole (Y)',
    PercentageMode.change => 'To (Y)',
  };

  String get _resultLabel => switch (_mode) {
    PercentageMode.of => 'Answer',
    PercentageMode.ratio => 'Percentage',
    PercentageMode.change => 'Change',
  };

  Decimal? get _value => switch (_mode) {
    PercentageMode.of => PercentageCalculator.of(
      percent: _x.value,
      value: _y.value,
    ),
    PercentageMode.ratio => PercentageCalculator.ratio(
      part: _x.value,
      whole: _y.value,
    ),
    PercentageMode.change => PercentageCalculator.change(
      from: _x.value,
      to: _y.value,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final Settings settings = ref.watch(settingsProvider);
    final NumberFormatOptions options = numberFormatFor(settings);

    return ToolScaffold(
      title: 'Percentage',
      resultLabel: _resultLabel,
      resultValue: _resultText(options),
      resultCaption: _caption(options),
      onShare: _share,
      actionLabel: 'Copy result',
      onAction: _copyResult,
      children: <Widget>[
        ToolChoiceChips(
          labels: _labels,
          selectedIndex: _mode.index,
          onSelected: (int index) => _setMode(PercentageMode.values[index]),
          keyPrefix: 'percentage-mode',
        ),
        const SizedBox(height: AppSizes.toolSheetGap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ToolAmountField(
                key: ValueKey<String>('percentage-x-${_mode.name}'),
                label: _xLabel,
                fieldKey: const Key('percentage-x'),
                initialAmount: _x,
                options: options,
                onChanged: (CurrencyAmount amount) =>
                    setState(() => _x = amount),
              ),
            ),
            const SizedBox(width: AppSizes.toolTenureGap),
            Expanded(
              child: ToolAmountField(
                key: ValueKey<String>('percentage-y-${_mode.name}'),
                label: _yLabel,
                fieldKey: const Key('percentage-y'),
                initialAmount: _y,
                options: options,
                onChanged: (CurrencyAmount amount) =>
                    setState(() => _y = amount),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.toolSheetGap),
        _summary(options),
      ],
    );
  }

  ToolSummaryCard _summary(NumberFormatOptions options) {
    final String x = _x.display(options: options);
    final String y = _y.display(options: options);
    final String result = _resultText(options);

    return ToolSummaryCard(
      rows: switch (_mode) {
        PercentageMode.of => <ToolSummaryRow>[
          ToolSummaryRow(label: 'Percent', value: '$x%'),
          ToolSummaryRow(label: 'Value', value: y),
        ],
        PercentageMode.ratio => <ToolSummaryRow>[
          ToolSummaryRow(label: 'Part', value: x),
          ToolSummaryRow(label: 'Whole', value: y),
        ],
        PercentageMode.change => <ToolSummaryRow>[
          ToolSummaryRow(label: 'From', value: x),
          ToolSummaryRow(label: 'To', value: y),
        ],
      },
      total: ToolSummaryRow(
        label: _resultLabel,
        value: result,
        valueKey: const Key('percentage-result'),
      ),
    );
  }

  String _resultText(NumberFormatOptions options) {
    final Decimal? value = _value;
    if (value == null) {
      return '—';
    }
    final String number = formatToolNumber(value, options: options);
    return _mode == PercentageMode.of ? number : '$number%';
  }

  String _caption(NumberFormatOptions options) {
    final String x = _x.display(options: options);
    final String y = _y.display(options: options);
    if (_value == null) {
      return 'Cannot divide by zero';
    }
    return switch (_mode) {
      PercentageMode.of => '$x% of $y',
      PercentageMode.ratio => '$x is what % of $y',
      PercentageMode.change => '% change from $x to $y',
    };
  }

  void _setMode(PercentageMode mode) {
    final ({String x, String y}) defaults = switch (mode) {
      PercentageMode.of => (x: '15', y: '200'),
      PercentageMode.ratio => (x: '25', y: '200'),
      PercentageMode.change => (x: '200', y: '250'),
    };
    setState(() {
      _mode = mode;
      _x = CurrencyAmount(defaults.x);
      _y = CurrencyAmount(defaults.y);
    });
  }

  Future<void> _copyResult() =>
      _copy(_resultText(numberFormatFor(ref.read(settingsProvider))));

  Future<void> _share() async {
    final NumberFormatOptions options = numberFormatFor(
      ref.read(settingsProvider),
    );
    final String x = _x.display(options: options);
    final String y = _y.display(options: options);
    final String question = switch (_mode) {
      PercentageMode.of => '$x% of $y',
      PercentageMode.ratio => '$x is what % of $y',
      PercentageMode.change => '% change from $x to $y',
    };
    await _copy(
      <String>[
        'Percentage',
        question,
        '$_resultLabel: ${_resultText(options)}',
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
