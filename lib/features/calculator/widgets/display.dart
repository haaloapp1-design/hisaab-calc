import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/engine/calc_result.dart';
import '../../../theme/app_tokens.dart';

/// Display density: Basic uses 60 px results and 20 px expressions,
/// Scientific/Programmer 52 px and 19 px (DESIGN "Type", `01`/`02` screens).
enum DisplayDensity { basic, scientific }

/// The calculator's blue display area (SPEC §1.1).
///
/// It renders values only — the page formats them (`formatNumber`) and passes
/// the strings. Three lines, from top:
/// * the memory chip (`M = 128`) when [memory] is set, and the expression,
///   which scrolls horizontally and keeps its end in view;
/// * the 1 px divider;
/// * the result, right aligned, auto-shrinking from the density's size to
///   [AppTypography.resultBasicMin] so a long number stays on one line.
///
/// [preview] paints the result in the lighter `onPrimaryMuted`; [error] takes
/// the line over with its plain-word message.
class Display extends StatelessWidget {
  const Display({
    super.key,
    this.expression = '',
    required this.result,
    this.preview = false,
    this.error,
    this.memory,
    this.density = DisplayDensity.basic,
  });

  /// Line 1: what the user has typed.
  final String expression;

  /// Line 2: the formatted result or live preview.
  final String result;

  /// Whether [result] is a live preview rather than a committed answer.
  final bool preview;

  /// When set, its message replaces the result.
  final CalcError? error;

  /// Formatted memory value; the chip is hidden when null.
  final String? memory;

  final DisplayDensity density;

  @override
  Widget build(BuildContext context) {
    final _DisplayMetrics metrics = _metricsFor(density);
    final Color resultColour = error != null
        ? AppColors.warning
        : (preview ? AppColors.onPrimaryMuted : AppColors.onPrimary);

    return Padding(
      key: const Key('display'),
      padding: EdgeInsets.fromLTRB(
        AppSizes.displayPaddingSide,
        0,
        AppSizes.displayPaddingSide,
        metrics.bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (memory != null) ...<Widget>[
                _MemoryChip(memory: memory!),
                const SizedBox(width: AppSizes.displayGap),
              ],
              Expanded(
                child: _ExpressionLine(
                  expression: expression,
                  style: metrics.expressionStyle.copyWith(
                    color: AppColors.onPrimaryMuted,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: metrics.gap),
          Container(
            key: const Key('display-divider'),
            height: AppSizes.borderWidth,
            color: AppColors.dividerOnPrimary,
          ),
          SizedBox(height: metrics.gap),
          _ResultLine(
            text: error?.displayText ?? result,
            style: metrics.resultStyle,
            colour: resultColour,
          ),
        ],
      ),
    );
  }
}

final class _DisplayMetrics {
  const _DisplayMetrics({
    required this.resultStyle,
    required this.expressionStyle,
    required this.bottomPadding,
    required this.gap,
  });

  final TextStyle resultStyle;
  final TextStyle expressionStyle;
  final double bottomPadding;
  final double gap;
}

_DisplayMetrics _metricsFor(DisplayDensity density) => switch (density) {
  DisplayDensity.basic => const _DisplayMetrics(
    resultStyle: AppTypography.resultBasic,
    expressionStyle: AppTypography.expression,
    bottomPadding: AppSizes.displayPaddingBottom,
    gap: AppSizes.displayGap,
  ),
  DisplayDensity.scientific => const _DisplayMetrics(
    resultStyle: AppTypography.resultScientific,
    expressionStyle: AppTypography.expressionScientific,
    bottomPadding: AppSizes.displayScientificPaddingBottom,
    gap: AppSizes.displayScientificGap,
  ),
};

/// The `M = 128` chip (13 px `#C7D1FF` on a 1 px `dividerOnPrimary` border).
class _MemoryChip extends StatelessWidget {
  const _MemoryChip({required this.memory});

  final String memory;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('display-memory'),
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.chipPaddingV,
        horizontal: AppSizes.chipPaddingH,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.chip),
        border: Border.all(
          color: AppColors.dividerOnPrimary,
          width: AppSizes.borderWidth,
        ),
      ),
      child: Text(
        'M = $memory',
        maxLines: 1,
        style: AppTypography.small.copyWith(color: AppColors.onPrimaryFaint),
      ),
    );
  }
}

/// The expression line: horizontal scroll, reversed so the end of a long
/// expression is the visible start, and re-anchored to the end whenever the
/// text changes.
class _ExpressionLine extends StatefulWidget {
  const _ExpressionLine({required this.expression, required this.style});

  final String expression;
  final TextStyle style;

  @override
  State<_ExpressionLine> createState() => _ExpressionLineState();
}

class _ExpressionLineState extends State<_ExpressionLine> {
  final ScrollController _controller = ScrollController();

  @override
  void didUpdateWidget(_ExpressionLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expression != widget.expression) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients) {
          _controller.jumpTo(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('display-expression-scroll'),
      controller: _controller,
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Text(
        widget.expression,
        key: const Key('display-expression'),
        maxLines: 1,
        softWrap: false,
        style: widget.style,
      ),
    );
  }
}

/// The result line with the 60→32 px (or 52→32 px) auto-shrink.
class _ResultLine extends StatelessWidget {
  const _ResultLine({
    required this.text,
    required this.style,
    required this.colour,
  });

  final String text;
  final TextStyle style;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double size = _fittedSize(context, constraints);

        return Semantics(
          liveRegion: true,
          child: Text(
            text,
            key: const Key('display-result'),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
            textAlign: TextAlign.right,
            style: style.copyWith(fontSize: size, color: colour),
          ),
        );
      },
    );
  }

  double _fittedSize(BuildContext context, BoxConstraints constraints) {
    final double maxSize = style.fontSize ?? 60;
    final double minSize = AppTypography.resultBasicMin.fontSize ?? 32;
    if (!constraints.hasBoundedWidth) {
      return maxSize;
    }

    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextPainter painter = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 1,
      textScaler: scaler,
    );
    double size = maxSize;
    while (size > minSize) {
      painter.text = TextSpan(text: text, style: style.copyWith(fontSize: size));
      painter.layout();
      if (painter.width <= constraints.maxWidth) {
        break;
      }
      size = math.max(minSize, size - 2);
    }
    painter.dispose();
    return size;
  }
}
