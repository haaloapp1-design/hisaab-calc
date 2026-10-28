import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/tools/gpa.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';
import 'tool_field.dart';

/// One editable course card of the GPA tool.
///
/// The page owns the course list and its stable [id]; this card only keeps the
/// three text controllers so typing does not rebuild the page on every key,
/// and reports a new [GpaCourse] through [onChanged]. The keys are
/// `gpa-course-$id-name`, `-credits`, `-points` and `-delete`.
class GpaCourseRow extends StatefulWidget {
  const GpaCourseRow({
    super.key,
    required this.id,
    required this.course,
    required this.onChanged,
    required this.onDelete,
  });

  /// Stable row number, used in the field keys.
  final int id;

  final GpaCourse course;
  final ValueChanged<GpaCourse> onChanged;
  final VoidCallback onDelete;

  @override
  State<GpaCourseRow> createState() => _GpaCourseRowState();
}

class _GpaCourseRowState extends State<GpaCourseRow> {
  late final TextEditingController _name = TextEditingController(
    text: widget.course.name,
  );
  late final TextEditingController _credits = TextEditingController(
    text: _plain(widget.course.credits),
  );
  late final TextEditingController _points = TextEditingController(
    text: _plain(widget.course.points),
  );

  @override
  void dispose() {
    _name.dispose();
    _credits.dispose();
    _points.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSizes.toolBreakdownPadding),
      decoration: BoxDecoration(
        border: Border.all(
          color: palette.keyNumberBorder,
          width: AppSizes.borderWidth,
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: ToolField(
                  label: 'Course',
                  child: ToolFieldBox(
                    child: ToolTextField(
                      fieldKey: Key('gpa-course-${widget.id}-name'),
                      controller: _name,
                      keyboardType: TextInputType.text,
                      onChanged: (_) => _report(),
                    ),
                  ),
                ),
              ),
              IconButton(
                key: Key('gpa-course-${widget.id}-delete'),
                onPressed: widget.onDelete,
                tooltip: 'Remove course',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: AppSizes.minTapTarget,
                  minHeight: AppSizes.minTapTarget,
                ),
                iconSize: AppSizes.toolDeleteIcon,
                color: palette.inkMuted,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.toolTenureGap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _numberField('Credits', 'credits', _credits)),
              const SizedBox(width: AppSizes.toolTenureGap),
              Expanded(child: _numberField('Grade points', 'points', _points)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numberField(
    String label,
    String field,
    TextEditingController controller,
  ) => ToolField(
    label: label,
    child: ToolFieldBox(
      child: ToolTextField(
        fieldKey: Key('gpa-course-${widget.id}-$field'),
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          LengthLimitingTextInputFormatter(6),
        ],
        onChanged: (_) => _report(),
      ),
    ),
  );

  void _report() {
    widget.onChanged(
      GpaCourse(
        name: _name.text,
        credits: _parse(_credits.text),
        points: _parse(_points.text),
      ),
    );
  }

  /// `3` and `3.5`, without the two money decimals of the other tool fields.
  static String _plain(Decimal value) => value.toString();

  static Decimal _parse(String text) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      return Decimal.zero;
    }
    final String normalised = trimmed.startsWith('.') ? '0$trimmed' : trimmed;
    return Decimal.tryParse(normalised) ?? Decimal.zero;
  }
}
