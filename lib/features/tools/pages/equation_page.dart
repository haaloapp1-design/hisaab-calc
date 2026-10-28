import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/formatter.dart';
import '../../../core/tools/equation.dart';
import '../../../core/tools/tool_format.dart';
import '../../../theme/app_tokens.dart';
import '../../settings/settings_controller.dart';
import '../../settings/settings_format.dart';
import '../../settings/settings_model.dart';
import '../tool_scaffold.dart';
import '../widgets/tool_choice_chips.dart';
import '../widgets/tool_signed_field.dart';
import '../widgets/tool_summary_card.dart';

/// The two equations the solver understands (§14).
enum _EquationMode { linear, quadratic }

/// The Equation solver tool (SPEC §6, screen-10 pattern).
///
/// The page keeps one coefficient set per mode, so switching between linear and
/// quadratic keeps both; [EquationSolver] does the maths and the widgets only
/// format the roots.
class EquationPage extends ConsumerStatefulWidget {
  const EquationPage({super.key});

  @override
  ConsumerState<EquationPage> createState() => _EquationPageState();
}

class _EquationPageState extends ConsumerState<EquationPage> {
  _EquationMode _mode = _EquationMode.linear;

  Decimal _linearA = Decimal.fromInt(2);
  Decimal _linearB = Decimal.fromInt(-8);
  Decimal _quadA = Decimal.one;
  Decimal _quadB = Decimal.fromInt(-3);
  Decimal _quadC = Decimal.fromInt(2);

  EquationResult get _result => _mode == _EquationMode.linear
      ? EquationSolver.linear(a: _linearA, b: _linearB)
      : EquationSolver.quadratic(a: _quadA, b: _quadB, c: _quadC);

  @override
  Widget build(BuildContext context) {
    final Settings settings = ref.watch(settingsProvider);
    final NumberFormatOptions options = numberFormatFor(settings);
    final EquationResult result = _result;
    final String value = _resultValue(result, options);

    return ToolScaffold(
      title: 'Equation solver',
      resultLabel: _resultLabel(result),
      resultValue: value,
      resultCaption: _caption(result, options),
      onShare: _share,
      actionLabel: 'Copy result',
      onAction: _copyResult,
      children: <Widget>[
        ToolChoiceChips(
          labels: const <String>['Linear', 'Quadratic'],
          selectedIndex: _mode.index,
          onSelected: (int index) =>
              setState(() => _mode = _EquationMode.values[index]),
          keyPrefix: 'equation-mode',
        ),
        const SizedBox(height: AppSizes.toolSheetGap),
        if (_mode == _EquationMode.linear)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: ToolSignedField(
                  key: const ValueKey<String>('equation-a-linear'),
                  label: 'a',
                  fieldKey: const Key('equation-a'),
                  initialValue: _linearA,
                  options: options,
                  onChanged: (Decimal value) =>
                      setState(() => _linearA = value),
                ),
              ),
              const SizedBox(width: AppSizes.toolTenureGap),
              Expanded(
                child: ToolSignedField(
                  key: const ValueKey<String>('equation-b-linear'),
                  label: 'b',
                  fieldKey: const Key('equation-b'),
                  initialValue: _linearB,
                  options: options,
                  onChanged: (Decimal value) =>
                      setState(() => _linearB = value),
                ),
              ),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: ToolSignedField(
                  key: const ValueKey<String>('equation-a-quadratic'),
                  label: 'a',
                  fieldKey: const Key('equation-a'),
                  initialValue: _quadA,
                  options: options,
                  onChanged: (Decimal value) => setState(() => _quadA = value),
                ),
              ),
              const SizedBox(width: AppSizes.toolTenureGap),
              Expanded(
                child: ToolSignedField(
                  key: const ValueKey<String>('equation-b-quadratic'),
                  label: 'b',
                  fieldKey: const Key('equation-b'),
                  initialValue: _quadB,
                  options: options,
                  onChanged: (Decimal value) => setState(() => _quadB = value),
                ),
              ),
              const SizedBox(width: AppSizes.toolTenureGap),
              Expanded(
                child: ToolSignedField(
                  key: const ValueKey<String>('equation-c-quadratic'),
                  label: 'c',
                  fieldKey: const Key('equation-c'),
                  initialValue: _quadC,
                  options: options,
                  onChanged: (Decimal value) => setState(() => _quadC = value),
                ),
              ),
            ],
          ),
        const SizedBox(height: AppSizes.toolSheetGap),
        _summary(result, value, options),
      ],
    );
  }

  ToolSummaryCard _summary(
    EquationResult result,
    String value,
    NumberFormatOptions options,
  ) {
    final List<ToolSummaryRow> rows = <ToolSummaryRow>[
      ToolSummaryRow(
        label: 'a',
        value: _number(result.a, options),
        valueKey: const Key('equation-value-a'),
      ),
      ToolSummaryRow(
        label: 'b',
        value: _number(result.b, options),
        valueKey: const Key('equation-value-b'),
      ),
      if (result.c != null)
        ToolSummaryRow(
          label: 'c',
          value: _number(result.c!, options),
          valueKey: const Key('equation-value-c'),
        ),
      if (result.discriminant != null)
        ToolSummaryRow(
          label: 'Discriminant',
          value: _number(result.discriminant!, options),
          valueKey: const Key('equation-discriminant'),
        ),
    ];

    return ToolSummaryCard(
      rows: rows,
      total: ToolSummaryRow(
        label: _resultLabel(result),
        value: value,
        valueKey: const Key('equation-solution'),
      ),
    );
  }

  /// `Root`, `Roots` or `Solution`, for the header and the summary.
  String _resultLabel(EquationResult result) => switch (result.type) {
    EquationType.oneRoot => 'Root',
    EquationType.twoRoots || EquationType.complexRoots => 'Roots',
    EquationType.noSolution || EquationType.everyX => 'Solution',
  };

  /// The header value: one root, a pair, a compact `±` or a sentence.
  String _resultValue(EquationResult result, NumberFormatOptions options) {
    switch (result.type) {
      case EquationType.noSolution:
        return 'No solution';
      case EquationType.everyX:
        return 'Every x';
      case EquationType.oneRoot:
        return _rootText(result.roots.single, options);
      case EquationType.twoRoots:
        return result.roots
            .map((EquationRoot root) => _rootText(root, options))
            .join(', ');
      case EquationType.complexRoots:
        final EquationRoot root = result.roots.first;
        return '${formatToolNumber(root.real, options: options)} '
            '± ${formatToolNumber(root.imaginary.abs(), options: options)}i';
    }
  }

  String _rootText(EquationRoot root, NumberFormatOptions options) {
    final String real = formatToolNumber(root.real, options: options);
    if (!root.isComplex) {
      return real;
    }
    final String sign = root.imaginary.sign < 0 ? '−' : '+';
    return '$real $sign '
        '${formatToolNumber(root.imaginary.abs(), options: options)}i';
  }

  /// `D = 1 · two real roots`, or the reason there is no quadratic.
  String _caption(EquationResult result, NumberFormatOptions options) {
    if (result.isLinearFallback) {
      return 'a = 0 → solved as linear';
    }
    if (result.discriminant == null) {
      return switch (result.type) {
        EquationType.noSolution => 'a = 0 and b ≠ 0',
        EquationType.everyX => 'a = 0 and b = 0',
        _ => 'Linear equation',
      };
    }
    final String discriminant = _number(result.discriminant!, options);
    return switch (result.type) {
      EquationType.twoRoots => 'D = $discriminant · two real roots',
      EquationType.oneRoot => 'D = $discriminant · one real root',
      EquationType.complexRoots => 'D = $discriminant · complex roots',
      _ => 'D = $discriminant',
    };
  }

  /// A coefficient or discriminant without forced decimals (`2`, `−8`, `1.5`).
  String _number(Decimal value, NumberFormatOptions options) {
    final Decimal whole = value.truncate();
    return value == whole
        ? formatToolCount(whole.toBigInt().toInt(), options: options)
        : formatToolNumber(value, options: options);
  }

  Future<void> _copyResult() async {
    final NumberFormatOptions options = numberFormatFor(
      ref.read(settingsProvider),
    );
    await _copy(_resultValue(_result, options));
  }

  Future<void> _share() async {
    final NumberFormatOptions options = numberFormatFor(
      ref.read(settingsProvider),
    );
    final EquationResult result = _result;
    final List<String> lines = <String>[
      'Equation solver',
      'Type: ${_mode == _EquationMode.linear ? 'Linear' : 'Quadratic'}',
      'a: ${_number(result.a, options)}',
      'b: ${_number(result.b, options)}',
      if (result.c != null) 'c: ${_number(result.c!, options)}',
      if (result.discriminant != null)
        'Discriminant: ${_number(result.discriminant!, options)}',
      '${_resultLabel(result)}: ${_resultValue(result, options)}',
    ];
    await _copy(lines.join('\n'));
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
