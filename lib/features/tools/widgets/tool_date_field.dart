import 'package:flutter/material.dart';

import '../../../core/tools/date_math.dart';
import '../../../core/tools/tool_date_format.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';
import 'tool_field.dart';

/// Opens a date picker for [initialDate]; the default is the Material dialog.
///
/// Pages take the same callback so a widget test can pick a date without
/// driving the calendar dialog.
typedef ToolDatePicker = Future<DateTime?> Function(
  BuildContext context,
  DateTime initialDate,
  DateTime firstDate,
  DateTime lastDate,
);

/// A labelled read-only date box that opens a picker on tap.
///
/// The page owns the [value]; the field only formats it and reports the picked
/// day as a UTC date-only value.
class ToolDateField extends StatelessWidget {
  const ToolDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.fieldKey,
    this.firstDate,
    this.lastDate,
    this.picker,
  });

  /// The 13 px label above the box, e.g. `Date of birth`.
  final String label;

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  /// The key on the tappable box, used by the tests.
  final Key fieldKey;

  final DateTime? firstDate;
  final DateTime? lastDate;

  /// Overrides the Material date picker (tests pass a stub).
  final ToolDatePicker? picker;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final DateTime first = firstDate ?? DateTime.utc(1900);
    final DateTime last = lastDate ?? DateTime.utc(2100, 12, 31);
    final ToolDatePicker open = picker ?? _showMaterialPicker;

    return ToolField(
      label: label,
      child: ToolFieldBox(
        child: Semantics(
          button: true,
          label: '$label, ${formatToolDate(value)}',
          child: GestureDetector(
            key: fieldKey,
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              final DateTime? picked = await open(context, value, first, last);
              if (picked != null) {
                onChanged(dateOnly(picked));
              }
            },
            child: SizedBox(
              height: AppSizes.minTapTarget,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      formatToolDate(value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.toolFieldValue.copyWith(
                        color: palette.ink,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_rounded,
                    size: AppSizes.toolDateIcon,
                    color: palette.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Future<DateTime?> _showMaterialPicker(
    BuildContext context,
    DateTime initialDate,
    DateTime firstDate,
    DateTime lastDate,
  ) => showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
  );
}
