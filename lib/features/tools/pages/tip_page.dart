import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency/currency_amount.dart';
import '../../../core/engine/formatter.dart';
import '../../../core/tools/tip.dart';
import '../../../core/tools/tool_format.dart';
import '../../../theme/app_tokens.dart';
import '../../settings/settings_controller.dart';
import '../../settings/settings_format.dart';
import '../../settings/settings_model.dart';
import '../tool_scaffold.dart';
import '../widgets/tool_amount_field.dart';
import '../widgets/tool_field.dart';
import '../widgets/tool_summary_card.dart';
import '../widgets/tool_toggle_row.dart';

/// The Tip and split tool (SPEC §6, screen-10 pattern).
///
/// The page owns the bill, the tip percentage and the number of people; the
/// round-up switch picks between [TipResult.perPerson] and
/// [TipResult.roundedPerPerson].
class TipPage extends ConsumerStatefulWidget {
  const TipPage({super.key});

  @override
  ConsumerState<TipPage> createState() => _TipPageState();
}

class _TipPageState extends ConsumerState<TipPage> {
  CurrencyAmount _bill = const CurrencyAmount('1000');
  CurrencyAmount _tip = const CurrencyAmount('10');
  int _people = 3;
  bool _roundUp = false;
  late final TextEditingController _peopleController = TextEditingController(
    text: '3',
  );

  @override
  void dispose() {
    _peopleController.dispose();
    super.dispose();
  }

  int get _peopleCount => math.max(1, _people);

  TipResult get _result => TipCalculator.calculate(
    bill: _bill.value,
    tipPercent: _tip.value,
    people: _peopleCount,
  );

  Decimal get _perPerson =>
      _roundUp ? _result.roundedPerPerson : _result.perPerson;

  @override
  Widget build(BuildContext context) {
    final Settings settings = ref.watch(settingsProvider);
    final NumberFormatOptions options = numberFormatFor(settings);
    final TipResult result = _result;

    return ToolScaffold(
      title: 'Tip and split',
      resultLabel: 'Per person',
      resultValue: formatToolNumber(_perPerson, options: options),
      resultCaption: _caption(options),
      onShare: _share,
      actionLabel: 'Copy result',
      onAction: _copyResult,
      children: <Widget>[
        ToolAmountField(
          label: 'Bill (PKR)',
          fieldKey: const Key('tip-bill'),
          initialAmount: _bill,
          options: options,
          onChanged: (CurrencyAmount amount) => setState(() => _bill = amount),
        ),
        const SizedBox(height: AppSizes.toolSheetGap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ToolAmountField(
                label: 'Tip (%)',
                fieldKey: const Key('tip-percent'),
                initialAmount: _tip,
                options: options,
                onChanged: (CurrencyAmount amount) =>
                    setState(() => _tip = amount),
              ),
            ),
            const SizedBox(width: AppSizes.toolTenureGap),
            Expanded(
              child: ToolField(
                label: 'People',
                child: ToolFieldBox(
                  child: ToolTextField(
                    fieldKey: const Key('tip-people'),
                    controller: _peopleController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    onChanged: _onPeopleChanged,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.toolSheetGap),
        ToolToggleRow(
          title: 'Round up per person',
          subtitle: 'To the next whole currency unit',
          value: _roundUp,
          onChanged: (bool value) => setState(() => _roundUp = value),
          switchKey: const Key('tip-round-up'),
          semanticLabel: 'Round up per person',
        ),
        const SizedBox(height: AppSizes.toolSheetGap),
        ToolSummaryCard(
          rows: <ToolSummaryRow>[
            ToolSummaryRow(
              label: 'Tip',
              value: formatToolNumber(result.tip, options: options),
              valueKey: const Key('tip-tip'),
            ),
            ToolSummaryRow(
              label: 'Total',
              value: formatToolNumber(result.total, options: options),
              valueKey: const Key('tip-total'),
            ),
          ],
          total: ToolSummaryRow(
            label: 'Per person',
            value: formatToolNumber(_perPerson, options: options),
            valueKey: const Key('tip-per-person'),
          ),
        ),
      ],
    );
  }

  String _caption(NumberFormatOptions options) {
    final String people = _peopleCount == 1 ? 'person' : 'people';
    final String rounded = _roundUp ? ' · rounded up' : '';
    return '${formatToolNumber(_result.total, options: options)} total '
        'for $_peopleCount $people$rounded';
  }

  void _onPeopleChanged(String text) {
    setState(() => _people = int.tryParse(text) ?? 0);
  }

  Future<void> _copyResult() => _copy(
    formatToolNumber(
      _perPerson,
      options: numberFormatFor(ref.read(settingsProvider)),
    ),
  );

  Future<void> _share() async {
    final NumberFormatOptions options = numberFormatFor(
      ref.read(settingsProvider),
    );
    final TipResult result = _result;
    await _copy(
      <String>[
        'Tip and split',
        'Bill: ${formatToolNumber(result.bill, options: options)}',
        'Tip: ${_tip.display(options: options)}%',
        'People: $_peopleCount',
        'Tip: ${formatToolNumber(result.tip, options: options)}',
        'Total: ${formatToolNumber(result.total, options: options)}',
        'Per person: ${formatToolNumber(_perPerson, options: options)}',
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
