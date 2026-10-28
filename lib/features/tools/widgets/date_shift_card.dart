import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/tools/date_difference.dart';
import '../../../core/tools/date_math.dart';
import '../../../core/tools/tool_date_format.dart';
import '../../../theme/app_tokens.dart';
import '../widgets/tool_choice_chips.dart';
import '../widgets/tool_date_field.dart';
import '../widgets/tool_field.dart';
import '../widgets/tool_summary_card.dart';

/// The "add or subtract days" panel of the Date difference page (§14).
///
/// It is self-contained: the page's two difference dates do not affect it, and
/// the shift itself comes from [DateShift].
class DateShiftCard extends StatefulWidget {
  const DateShiftCard({super.key, this.today, this.picker});

  /// Overrides "today" in tests; defaults to the device date.
  final DateTime? today;

  /// Overrides the Material date picker (tests pass a stub).
  final ToolDatePicker? picker;

  @override
  State<DateShiftCard> createState() => _DateShiftCardState();
}

class _DateShiftCardState extends State<DateShiftCard> {
  late DateTime _date = dateOnly(widget.today ?? DateTime.now());
  bool _subtract = false;
  int _days = 30;
  late final TextEditingController _daysController = TextEditingController(
    text: '30',
  );

  @override
  void dispose() {
    _daysController.dispose();
    super.dispose();
  }

  DateTime get _result =>
      DateShift.shift(date: _date, days: _subtract ? -_days : _days);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ToolDateField(
          label: 'Shift a date',
          value: _date,
          fieldKey: const Key('shift-date'),
          picker: widget.picker,
          onChanged: (DateTime date) => setState(() => _date = date),
        ),
        const SizedBox(height: AppSizes.toolSheetGap),
        ToolChoiceChips(
          labels: const <String>['Add days', 'Subtract days'],
          selectedIndex: _subtract ? 1 : 0,
          onSelected: (int index) => setState(() => _subtract = index == 1),
          keyPrefix: 'shift-mode',
        ),
        const SizedBox(height: AppSizes.toolSheetGap),
        ToolField(
          label: 'Days',
          child: ToolFieldBox(
            child: ToolTextField(
              fieldKey: const Key('shift-days'),
              controller: _daysController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              onChanged: (String text) =>
                  setState(() => _days = int.tryParse(text) ?? 0),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.toolSheetGap),
        ToolSummaryCard(
          rows: <ToolSummaryRow>[
            ToolSummaryRow(
              label: 'Result date',
              value: formatToolDate(_result),
              valueKey: const Key('shift-result-date'),
            ),
            ToolSummaryRow(
              label: 'Day',
              value: formatToolWeekday(_result),
              valueKey: const Key('shift-result-day'),
            ),
          ],
        ),
      ],
    );
  }
}
