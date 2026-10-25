import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../../theme/app_tokens.dart';

/// The dashed border of a disabled key (`03-programmer.html`).
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final double half = AppSizes.borderWidth / 2;
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSizes.borderWidth;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            half,
            half,
            size.width - AppSizes.borderWidth,
            size.height - AppSizes.borderWidth,
          ),
          Radius.circular(radius),
        ),
      );

    for (final PathMetric metric in path.computeMetrics()) {
      double start = 0;
      while (start < metric.length) {
        canvas.drawPath(
          metric.extractPath(start, start + AppSizes.disabledDash),
          paint,
        );
        start += AppSizes.disabledDash + AppSizes.disabledDashGap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
