import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';
import '../currency_readout.dart';
import 'currency_row.dart';

/// The white sheet of screen 08: handle, scrolling rows and the add button.
///
/// A [RefreshIndicator] wraps the rows so pulling down refreshes the rates.
/// The add button stays below the list, inside the sheet, like the design.
class CurrencySheet extends StatelessWidget {
  const CurrencySheet({
    super.key,
    required this.rows,
    required this.onRowTap,
    required this.onRowLongPress,
    required this.onAdd,
    required this.onRefresh,
  });

  final List<CurrencyRowReadout> rows;
  final ValueChanged<CurrencyRowReadout> onRowTap;
  final ValueChanged<CurrencyRowReadout> onRowLongPress;
  final VoidCallback onAdd;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Container(
      key: const Key('currency-sheet'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.sheet,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.currencySheetPaddingSide,
        AppSizes.currencySheetPaddingTop,
        AppSizes.currencySheetPaddingSide,
        0,
      ),
      child: Column(
        children: <Widget>[
          Container(
            key: const Key('currency-sheet-handle'),
            width: AppSizes.handleWidth,
            height: AppSizes.handleHeight,
            decoration: BoxDecoration(
              color: palette.primaryText,
              borderRadius: BorderRadius.circular(AppRadii.handle),
            ),
          ),
          const SizedBox(height: AppSizes.currencySheetGap),
          Expanded(
            child: RefreshIndicator(
              color: palette.primaryText,
              onRefresh: onRefresh,
              child: rows.isEmpty
                  ? _EmptyRows(palette: palette)
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: rows.length,
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(height: AppSizes.currencySheetGap),
                      itemBuilder: (BuildContext context, int index) {
                        final CurrencyRowReadout row = rows[index];
                        return CurrencyRow(
                          row: row,
                          onTap: () => onRowTap(row),
                          onLongPress: () => onRowLongPress(row),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: AppSizes.currencySheetGap),
          Padding(
            padding: EdgeInsets.only(
              bottom:
                  AppSizes.currencyAddBottom +
                  MediaQuery.paddingOf(context).bottom,
            ),
            child: _AddCurrencyButton(onTap: onAdd),
          ),
        ],
      ),
    );
  }
}

class _EmptyRows extends StatelessWidget {
  const _EmptyRows({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: <Widget>[
        SizedBox(
          height: 160,
          child: Center(
            child: Text(
              'No currencies yet',
              key: const Key('currency-empty'),
              style: AppTypography.historyEmpty.copyWith(
                color: palette.inkMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The dashed 48 px "Add currency" button from screen 08.
class _AddCurrencyButton extends StatelessWidget {
  const _AddCurrencyButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return SizedBox(
      height: AppSizes.currencyAddHeight,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: palette.converterCardBorder,
          radius: AppSizes.currencyAddRadius,
          dash: AppSizes.currencyAddDash,
          gap: AppSizes.currencyAddDashGap,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.currencyAddRadius),
          child: Semantics(
            button: true,
            label: 'Add currency',
            onTap: onTap,
            excludeSemantics: true,
            child: InkWell(
              key: const Key('currency-add'),
              borderRadius: BorderRadius.circular(AppSizes.currencyAddRadius),
              onTap: onTap,
              child: Center(
                child: Text(
                  'Add currency',
                  style: AppTypography.currencyAdd.copyWith(
                    color: palette.primaryText,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.dash,
    required this.gap,
  });

  final Color color;
  final double radius;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSizes.borderWidth;
    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            AppSizes.borderWidth / 2,
            AppSizes.borderWidth / 2,
            size.width - AppSizes.borderWidth,
            size.height - AppSizes.borderWidth,
          ),
          Radius.circular(radius),
        ),
      );
    for (final PathMetric metric in path.computeMetrics()) {
      for (double start = 0; start < metric.length; start += dash + gap) {
        canvas.drawPath(
          metric.extractPath(start, math.min(start + dash, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.dash != dash ||
      oldDelegate.gap != gap;
}
