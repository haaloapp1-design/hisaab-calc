import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/formatter.dart';
import '../../../core/tools/age.dart';
import '../../../core/tools/date_math.dart';
import '../../../core/tools/tool_date_format.dart';
import '../../../core/tools/tool_format.dart';
import '../../../theme/app_tokens.dart';
import '../../settings/settings_controller.dart';
import '../../settings/settings_format.dart';
import '../../settings/settings_model.dart';
import '../tool_scaffold.dart';
import '../widgets/tool_date_field.dart';
import '../widgets/tool_summary_card.dart';

/// The Age tool (SPEC §6, screen-10 pattern).
///
/// The page owns the date of birth and the "on" date (today by default); the
/// calendar maths comes from [AgeCalculator], and the widgets only format it.
class AgePage extends ConsumerStatefulWidget {
  const AgePage({super.key, this.today, this.picker});

  /// Overrides "today" in tests; defaults to the device date.
  final DateTime? today;

  /// Overrides the Material date picker (tests pass a stub).
  final ToolDatePicker? picker;

  @override
  ConsumerState<AgePage> createState() => _AgePageState();
}

class _AgePageState extends ConsumerState<AgePage> {
  late DateTime _onDate = dateOnly(widget.today ?? DateTime.now());
  late DateTime _dateOfBirth = DateTime.utc(1990, 1, 1);

  AgeResult? get _result =>
      AgeCalculator.calculate(dateOfBirth: _dateOfBirth, onDate: _onDate);

  @override
  Widget build(BuildContext context) {
    final Settings settings = ref.watch(settingsProvider);
    final NumberFormatOptions options = numberFormatFor(settings);
    final AgeResult? result = _result;

    return ToolScaffold(
      title: 'Age',
      resultLabel: 'Age',
      resultValue: result == null ? '—' : _ageText(result),
      resultCaption: result == null
          ? 'On date is before the date of birth'
          : 'Next birthday ${_nextText(result, options)}',
      onShare: _share,
      actionLabel: 'Copy result',
      onAction: _copyResult,
      children: <Widget>[
        ToolDateField(
          label: 'Date of birth',
          value: _dateOfBirth,
          fieldKey: const Key('age-dob'),
          lastDate: _onDate,
          picker: widget.picker,
          onChanged: (DateTime date) => setState(() => _dateOfBirth = date),
        ),
        const SizedBox(height: AppSizes.toolSheetGap),
        ToolDateField(
          label: 'Age on date',
          value: _onDate,
          fieldKey: const Key('age-on'),
          firstDate: _dateOfBirth,
          picker: widget.picker,
          onChanged: (DateTime date) => setState(() => _onDate = date),
        ),
        if (result != null) ...<Widget>[
          const SizedBox(height: AppSizes.toolSheetGap),
          ToolSummaryCard(
            rows: <ToolSummaryRow>[
              ToolSummaryRow(
                label: 'Years',
                value: '${result.years}',
                valueKey: const Key('age-years'),
              ),
              ToolSummaryRow(
                label: 'Months',
                value: '${result.months}',
                valueKey: const Key('age-months'),
              ),
              ToolSummaryRow(
                label: 'Days',
                value: '${result.days}',
                valueKey: const Key('age-days'),
              ),
              ToolSummaryRow(
                label: 'Total days',
                value: formatToolCount(result.totalDays, options: options),
                valueKey: const Key('age-total-days'),
              ),
            ],
            total: ToolSummaryRow(
              label: 'Next birthday',
              value: formatToolDate(result.nextBirthday),
              valueKey: const Key('age-next-birthday'),
            ),
          ),
        ],
      ],
    );
  }

  /// `36y 9m 27d`, the compact age in the header.
  String _ageText(AgeResult result) =>
      '${result.years}y ${result.months}m ${result.days}d';

  /// `in 65 days`, or `tomorrow` when only one day is left.
  String _nextText(AgeResult result, NumberFormatOptions options) {
    final int days = result.daysToNextBirthday;
    if (days == 1) {
      return 'tomorrow';
    }
    return 'in ${formatToolCount(days, options: options)} days';
  }

  Future<void> _copyResult() async {
    final AgeResult? result = _result;
    await _copy(result == null ? '—' : _ageText(result));
    if (!mounted) {
      return;
    }
    _toast('Copied');
  }

  Future<void> _share() async {
    final NumberFormatOptions options = numberFormatFor(
      ref.read(settingsProvider),
    );
    final AgeResult? result = _result;
    if (result == null) {
      await _copy('Age\nOn date is before the date of birth');
      if (mounted) {
        _toast('Copied');
      }
      return;
    }
    await _copy(
      <String>[
        'Age',
        'Date of birth: ${formatToolDate(result.dateOfBirth)}',
        'Age on: ${formatToolDate(result.onDate)}',
        'Age: ${_ageText(result)}',
        'Total days: ${formatToolCount(result.totalDays, options: options)}',
        'Next birthday: ${formatToolDate(result.nextBirthday)}',
        'Days to next birthday: '
            '${formatToolCount(result.daysToNextBirthday, options: options)}',
      ].join('\n'),
    );
    if (!mounted) {
      return;
    }
    _toast('Copied');
  }

  Future<void> _copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
