import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/formatter.dart';
import '../../../core/tools/gpa.dart';
import '../../../core/tools/tool_format.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';
import '../../settings/settings_controller.dart';
import '../../settings/settings_format.dart';
import '../../settings/settings_model.dart';
import '../tool_scaffold.dart';
import '../widgets/gpa_course_row.dart';
import '../widgets/tool_choice_chips.dart';
import '../widgets/tool_summary_card.dart';

/// The three grade scales the GPA tool offers (§14 GPA).
enum _Scale { four, five, ten }

/// One course in the page's list, with the stable id used by the row keys.
final class _CourseEntry {
  const _CourseEntry(this.id, this.course);

  final int id;
  final GpaCourse course;
}

/// The GPA / grades tool (SPEC §6, screen-10 pattern).
///
/// The page owns the editable course list and the grade scale; the weighted
/// average comes from [GpaCalculator]. Rows report whole [GpaCourse] values so
/// the page never reads the text controllers itself.
class GpaPage extends ConsumerStatefulWidget {
  const GpaPage({super.key});

  @override
  ConsumerState<GpaPage> createState() => _GpaPageState();
}

class _GpaPageState extends ConsumerState<GpaPage> {
  _Scale _scaleChoice = _Scale.four;
  int _nextId = 4;
  final List<_CourseEntry> _courses = <_CourseEntry>[
    _CourseEntry(
      1,
      GpaCourse(
        name: 'Maths',
        credits: Decimal.fromInt(3),
        points: Decimal.fromInt(4),
      ),
    ),
    _CourseEntry(
      2,
      GpaCourse(
        name: 'Physics',
        credits: Decimal.fromInt(4),
        points: Decimal.parse('3.5'),
      ),
    ),
    _CourseEntry(
      3,
      GpaCourse(
        name: 'English',
        credits: Decimal.fromInt(2),
        points: Decimal.fromInt(3),
      ),
    ),
  ];

  Decimal get _scale => switch (_scaleChoice) {
    _Scale.four => GpaCalculator.defaultScale,
    _Scale.five => GpaCalculator.fiveScale,
    _Scale.ten => GpaCalculator.tenScale,
  };

  GpaResult? get _result => GpaCalculator.calculate(
    courses: <GpaCourse>[
      for (final _CourseEntry entry in _courses) entry.course,
    ],
    scale: _scale,
  );

  @override
  Widget build(BuildContext context) {
    final Settings settings = ref.watch(settingsProvider);
    final NumberFormatOptions options = numberFormatFor(settings);
    final GpaResult? result = _result;

    return ToolScaffold(
      title: 'GPA / grades',
      resultLabel: 'GPA',
      resultValue: result == null
          ? '—'
          : formatToolNumber(result.gpa, options: options),
      resultCaption: _caption(result, options),
      onShare: _share,
      actionLabel: 'Copy result',
      onAction: _copyResult,
      children: <Widget>[
        ToolChoiceChips(
          labels: const <String>['4.0 scale', '5.0 scale', '10 scale'],
          selectedIndex: _scaleChoice.index,
          onSelected: (int index) =>
              setState(() => _scaleChoice = _Scale.values[index]),
          keyPrefix: 'gpa-scale',
        ),
        const SizedBox(height: AppSizes.toolSheetGap),
        for (final _CourseEntry entry in _courses) ...<Widget>[
          GpaCourseRow(
            key: ValueKey<int>(entry.id),
            id: entry.id,
            course: entry.course,
            onChanged: (GpaCourse course) => _update(entry.id, course),
            onDelete: () => _remove(entry.id),
          ),
          const SizedBox(height: AppSizes.toolSheetGap),
        ],
        _AddCourseButton(onTap: _addCourse),
        if (result != null) ...<Widget>[
          const SizedBox(height: AppSizes.toolSheetGap),
          ToolSummaryCard(
            rows: <ToolSummaryRow>[
              ToolSummaryRow(
                label: 'Total credits',
                value: _creditsText(result.totalCredits, options),
                valueKey: const Key('gpa-total-credits'),
              ),
              ToolSummaryRow(
                label: 'Courses',
                value: formatToolCount(result.courseCount, options: options),
                valueKey: const Key('gpa-course-count'),
              ),
              ToolSummaryRow(
                label: 'Scale',
                value: formatToolNumber(
                  _scale,
                  options: options,
                  decimalPlaces: 1,
                ),
                valueKey: const Key('gpa-scale-value'),
              ),
            ],
            total: ToolSummaryRow(
              label: 'Percentage',
              value:
                  '${formatToolNumber(result.percentage, options: options)}%',
              valueKey: const Key('gpa-percentage'),
            ),
          ),
        ],
      ],
    );
  }

  String _caption(GpaResult? result, NumberFormatOptions options) {
    if (result == null) {
      return 'Add a course with credits';
    }
    final String courses = result.courseCount == 1 ? 'course' : 'courses';
    return '${_creditsText(result.totalCredits, options)} credits · '
        '${formatToolCount(result.courseCount, options: options)} $courses';
  }

  /// `9` for whole credits, `3.5` when a course has half credits.
  String _creditsText(Decimal credits, NumberFormatOptions options) {
    final Decimal whole = credits.truncate();
    if (credits == whole) {
      return formatToolCount(whole.toBigInt().toInt(), options: options);
    }
    return formatToolNumber(credits, options: options);
  }

  void _update(int id, GpaCourse course) {
    final int index = _courses.indexWhere(
      (_CourseEntry entry) => entry.id == id,
    );
    if (index == -1) {
      return;
    }
    setState(() => _courses[index] = _CourseEntry(id, course));
  }

  void _remove(int id) {
    setState(
      () => _courses.removeWhere((_CourseEntry entry) => entry.id == id),
    );
  }

  void _addCourse() {
    setState(() {
      _courses.add(
        _CourseEntry(
          _nextId++,
          GpaCourse(name: '', credits: Decimal.zero, points: Decimal.zero),
        ),
      );
    });
  }

  Future<void> _copyResult() async {
    final NumberFormatOptions options = numberFormatFor(
      ref.read(settingsProvider),
    );
    final GpaResult? result = _result;
    await _copy(
      result == null ? '—' : formatToolNumber(result.gpa, options: options),
    );
  }

  Future<void> _share() async {
    final NumberFormatOptions options = numberFormatFor(
      ref.read(settingsProvider),
    );
    final GpaResult? result = _result;
    if (result == null) {
      await _copy('GPA\nAdd a course with credits');
      return;
    }
    await _copy(
      <String>[
        'GPA / grades',
        'Scale: ${formatToolNumber(_scale, options: options, decimalPlaces: 1)}',
        'Courses: ${formatToolCount(result.courseCount, options: options)}',
        'Total credits: ${_creditsText(result.totalCredits, options)}',
        'GPA: ${formatToolNumber(result.gpa, options: options)}',
        'Percentage: ${formatToolNumber(result.percentage, options: options)}%',
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

/// The outlined "Add course" button at the end of the list.
class _AddCourseButton extends StatelessWidget {
  const _AddCourseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final BorderRadius radius = BorderRadius.circular(AppRadii.toolRateChip);

    return SizedBox(
      height: AppSizes.toolRateChipHeight,
      child: Material(
        color: palette.keyNumber,
        borderRadius: radius,
        child: InkWell(
          key: const Key('gpa-add'),
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: palette.keyOperatorBorder,
                width: AppSizes.borderWidth,
              ),
            ),
            child: Text(
              'Add course',
              style: AppTypography.toolRateChip.copyWith(
                color: palette.primary,
                fontWeight: AppTypography.regular,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
