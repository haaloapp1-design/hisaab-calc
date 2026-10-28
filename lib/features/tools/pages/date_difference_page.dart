import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/formatter.dart';
import '../../../core/tools/date_difference.dart';
import '../../../core/tools/date_math.dart';
import '../../../core/tools/tool_date_format.dart';
import '../../../core/tools/tool_format.dart';
import '../../../theme/app_tokens.dart';
import '../../settings/settings_controller.dart';
import '../../settings/settings_format.dart';
import '../../settings/settings_model.dart';
import '../tool_scaffold.dart';
import '../widgets/date_shift_card.dart';
import '../widgets/tool_date_field.dart';
import '../widgets/tool_summary_card.dart';
import '../widgets/tool_toggle_row.dart';

/// The Date difference tool (SPEC §6, screen-10 pattern).
///
/// The page owns the two dates and the include-end-date switch; the maths comes
/// from [DateDifferenceCalculator]. The add/subtract panel is [DateShiftCard].
class DateDifferencePage extends ConsumerStatefulWidget {
  const DateDifferencePage({super.key, this.today, this.picker});

  /// Overrides "today" in tests; defaults to the device date.
  final DateTime? today;

  /// Overrides the Material date picker (tests pass a stub).
  final ToolDatePicker? picker;

  @override
  ConsumerState<DateDifferencePage> createState() => _DateDifferencePageState();
}

class _DateDifferencePageState extends ConsumerState<DateDifferencePage> {
  late final DateTime _today = dateOnly(widget.today ?? DateTime.now());
  late DateTime _start = _today.subtract(const Duration(days: 30));
  late DateTime _end = _today;
  bool _includeEnd = false;

  DateDifferenceResult get _result => DateDifferenceCalculator.between(
    start: _start,
    end: _end,
    includeEndDate: _includeEnd,
  );

  @override
  Widget build(BuildContext context) {
    final Settings settings = ref.watch(settingsProvider);
    final NumberFormatOptions options = numberFormatFor(settings);
    final DateDifferenceResult result = _result;

    return ToolScaffold(
      title: 'Date difference',
      resultLabel: 'Days between',
      resultValue: formatToolCount(result.days, options: options),
      resultCaption: _caption(result),
      onShare: _share,
      actionLabel: 'Copy result',
      onAction: _copyResult,
      children: <Widget>[
        ToolDateField(
          label: 'Start date',
          value: _start,
          fieldKey: const Key('date-start'),
          picker: widget.picker,
          onChanged: (DateTime date) => setState(() => _start = date),
        ),
        const SizedBox(height: AppSizes.toolSheetGap),
        ToolDateField(
          label: 'End date',
          value: _end,
          fieldKey: const Key('date-end'),
          picker: widget.picker,
          onChanged: (DateTime date) => setState(() => _end = date),
        ),
        const SizedBox(height: AppSizes.toolSheetGap),
        ToolToggleRow(
          title: 'Include end date',
          subtitle: 'Count the last day too',
          value: _includeEnd,
          onChanged: (bool value) => setState(() => _includeEnd = value),
          switchKey: const Key('date-include-end'),
          semanticLabel: 'Include end date',
        ),
        const SizedBox(height: AppSizes.toolSheetGap),
        ToolSummaryCard(
          rows: <ToolSummaryRow>[
            ToolSummaryRow(
              label: 'Weeks + days',
              value: _weeksText(result, options),
              valueKey: const Key('date-weeks'),
            ),
            ToolSummaryRow(
              label: 'Months + days',
              value: _monthsText(result, options),
              valueKey: const Key('date-months'),
            ),
            ToolSummaryRow(
              label: 'Include end date',
              value: _includeEnd ? 'Yes' : 'No',
              valueKey: const Key('date-include'),
            ),
          ],
          total: ToolSummaryRow(
            label: 'Total days',
            value: formatToolCount(result.days, options: options),
            valueKey: const Key('date-total-days'),
          ),
        ),
        const SizedBox(height: AppSizes.toolSheetGap),
        DateShiftCard(today: _today, picker: widget.picker),
      ],
    );
  }

  /// `1 Jan 2026 → 28 Oct 2026`, plus a note when the end is earlier.
  String _caption(DateDifferenceResult result) {
    final String range = formatToolDateRange(result.start, result.end);
    return result.isNegative ? '$range · end is before start' : range;
  }

  /// `4 weeks 2 days`, with a typographic minus for a reversed range.
  String _weeksText(DateDifferenceResult result, NumberFormatOptions options) {
    final String weeks = formatToolCount(result.weeks, options: options);
    final String days = formatToolCount(result.weekDays, options: options);
    final String text =
        '$weeks ${_plural(result.weeks, 'week')} '
        '$days ${_plural(result.weekDays, 'day')}';
    return result.isNegative ? '−$text' : text;
  }

  /// `1 month 0 days`, with a typographic minus for a reversed range.
  String _monthsText(DateDifferenceResult result, NumberFormatOptions options) {
    final String months = formatToolCount(result.months, options: options);
    final String days = formatToolCount(result.monthDays, options: options);
    final String text =
        '$months ${_plural(result.months, 'month')} '
        '$days ${_plural(result.monthDays, 'day')}';
    return result.isNegative ? '−$text' : text;
  }

  String _plural(int value, String word) => value == 1 ? word : '${word}s';

  Future<void> _copyResult() async {
    final NumberFormatOptions options = numberFormatFor(
      ref.read(settingsProvider),
    );
    await Clipboard.setData(
      ClipboardData(text: formatToolCount(_result.days, options: options)),
    );
    if (!mounted) {
      return;
    }
    _toast('Copied');
  }

  Future<void> _share() async {
    final NumberFormatOptions options = numberFormatFor(
      ref.read(settingsProvider),
    );
    final DateDifferenceResult result = _result;
    await Clipboard.setData(
      ClipboardData(
        text: <String>[
          'Date difference',
          'Start: ${formatToolDate(result.start)}',
          'End: ${formatToolDate(result.end)}',
          'Include end date: ${_includeEnd ? 'Yes' : 'No'}',
          'Days: ${formatToolCount(result.days, options: options)}',
          'Weeks + days: ${_weeksText(result, options)}',
          'Months + days: ${_monthsText(result, options)}',
        ].join('\n'),
      ),
    );
    if (!mounted) {
      return;
    }
    _toast('Copied');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
