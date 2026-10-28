import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/formatter.dart';
import '../../../core/tools/statistics.dart';
import '../../../core/tools/tool_format.dart';
import '../../../theme/app_tokens.dart';
import '../../settings/settings_controller.dart';
import '../../settings/settings_format.dart';
import '../../settings/settings_model.dart';
import '../tool_scaffold.dart';
import '../widgets/tool_field.dart';
import '../widgets/tool_summary_card.dart';

/// The Statistics tool (SPEC §6, screen-10 pattern).
///
/// One field takes the list; [StatisticsCalculator] returns the whole summary
/// and the widgets format it. An invalid or empty list shows a dash.
class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});

  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  static const String _defaultValues = '4, 8, 15, 16, 23, 42';

  late final TextEditingController _controller = TextEditingController(
    text: _defaultValues,
  );
  late List<Decimal>? _values = StatisticsCalculator.parseInput(_defaultValues);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  StatisticsResult? get _result {
    final List<Decimal>? values = _values;
    return values == null ? null : StatisticsCalculator.calculate(values);
  }

  @override
  Widget build(BuildContext context) {
    final Settings settings = ref.watch(settingsProvider);
    final NumberFormatOptions options = numberFormatFor(settings);
    final StatisticsResult? result = _result;

    return ToolScaffold(
      title: 'Statistics',
      resultLabel: 'Mean',
      resultValue: result == null
          ? '—'
          : formatToolNumber(result.mean, options: options),
      resultCaption: result == null
          ? 'Enter numbers separated by commas'
          : '${formatToolCount(result.count, options: options)} values · '
                'sum ${formatToolNumber(result.sum, options: options)}',
      onShare: _share,
      actionLabel: 'Copy result',
      onAction: _copyResult,
      children: <Widget>[
        ToolField(
          label: 'Values (comma separated)',
          child: ToolFieldBox(
            child: ToolTextField(
              fieldKey: const Key('statistics-values'),
              controller: _controller,
              keyboardType: TextInputType.text,
              inputFormatters: <TextInputFormatter>[
                LengthLimitingTextInputFormatter(300),
              ],
              onChanged: (String text) => setState(
                () => _values = StatisticsCalculator.parseInput(text),
              ),
            ),
          ),
        ),
        if (result != null) ...<Widget>[
          const SizedBox(height: AppSizes.toolSheetGap),
          _summary(result, options),
        ],
      ],
    );
  }

  ToolSummaryCard _summary(
    StatisticsResult result,
    NumberFormatOptions options,
  ) => ToolSummaryCard(
    rows: <ToolSummaryRow>[
      ToolSummaryRow(
        label: 'Count',
        value: formatToolCount(result.count, options: options),
        valueKey: const Key('statistics-count'),
      ),
      ToolSummaryRow(
        label: 'Sum',
        value: formatToolNumber(result.sum, options: options),
        valueKey: const Key('statistics-sum'),
      ),
      ToolSummaryRow(
        label: 'Median',
        value: formatToolNumber(result.median, options: options),
        valueKey: const Key('statistics-median'),
      ),
      ToolSummaryRow(
        label: 'Mode',
        value: _modeText(result, options),
        valueKey: const Key('statistics-mode'),
      ),
      ToolSummaryRow(
        label: 'Min',
        value: formatToolNumber(result.min, options: options),
        valueKey: const Key('statistics-min'),
      ),
      ToolSummaryRow(
        label: 'Max',
        value: formatToolNumber(result.max, options: options),
        valueKey: const Key('statistics-max'),
      ),
      ToolSummaryRow(
        label: 'Range',
        value: formatToolNumber(result.range, options: options),
        valueKey: const Key('statistics-range'),
      ),
      ToolSummaryRow(
        label: 'Population SD',
        value: formatToolNumber(result.populationSd, options: options),
        valueKey: const Key('statistics-population-sd'),
      ),
    ],
    total: ToolSummaryRow(
      label: 'Sample SD',
      value: result.sampleSd == null
          ? '—'
          : formatToolNumber(result.sampleSd!, options: options),
      valueKey: const Key('statistics-sample-sd'),
    ),
  );

  String _modeText(StatisticsResult result, NumberFormatOptions options) {
    if (result.modes.isEmpty) {
      return 'None';
    }
    return result.modes
        .map((Decimal value) => formatToolNumber(value, options: options))
        .join(', ');
  }

  Future<void> _copyResult() async {
    final NumberFormatOptions options = numberFormatFor(
      ref.read(settingsProvider),
    );
    final StatisticsResult? result = _result;
    await _copy(
      result == null ? '—' : formatToolNumber(result.mean, options: options),
    );
  }

  Future<void> _share() async {
    final NumberFormatOptions options = numberFormatFor(
      ref.read(settingsProvider),
    );
    final StatisticsResult? result = _result;
    if (result == null) {
      await _copy('Statistics\nEnter numbers separated by commas');
      return;
    }
    await _copy(
      <String>[
        'Statistics',
        'Count: ${formatToolCount(result.count, options: options)}',
        'Sum: ${formatToolNumber(result.sum, options: options)}',
        'Mean: ${formatToolNumber(result.mean, options: options)}',
        'Median: ${formatToolNumber(result.median, options: options)}',
        'Mode: ${_modeText(result, options)}',
        'Min: ${formatToolNumber(result.min, options: options)}',
        'Max: ${formatToolNumber(result.max, options: options)}',
        'Range: ${formatToolNumber(result.range, options: options)}',
        'Population SD: '
            '${formatToolNumber(result.populationSd, options: options)}',
        'Sample SD: '
            '${result.sampleSd == null ? '—' : formatToolNumber(result.sampleSd!, options: options)}',
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
