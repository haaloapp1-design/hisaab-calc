import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_tokens.dart';

/// The five key roles from DESIGN "Components".
enum CalcKeyKind {
  /// Digits, `.` and the constants.
  number,

  /// Function keys such as `sin`, `C`, `%` and `±`.
  function,

  /// `+ − × ÷` and the other operators.
  operator,

  /// The primary `=` key.
  equals,

  /// A key the current mode cannot use (programmer bases, T33).
  disabled,
}

/// Keypad density: Basic uses the taller 60 px keys, Scientific/Programmer the
/// compact 46 px ones (DESIGN "Shape and spacing").
enum CalcKeyDensity { basic, scientific }

/// Measurements that go with each density. They live here so both the button
/// and the grid read the same tokens.
extension CalcKeyDensityMetrics on CalcKeyDensity {
  double get keyHeight => switch (this) {
    CalcKeyDensity.basic => AppSizes.keyHeightBasic,
    CalcKeyDensity.scientific => AppSizes.keyHeightScientific,
  };

  double get keyGap => switch (this) {
    CalcKeyDensity.basic => AppSizes.keyGapBasic,
    CalcKeyDensity.scientific => AppSizes.keyGapScientific,
  };

  double get keyRadius => switch (this) {
    CalcKeyDensity.basic => AppRadii.keyBasic,
    CalcKeyDensity.scientific => AppRadii.keyScientific,
  };
}

/// One calculator key: 60 px tall (Basic) or 46 px (Scientific) with the
/// colour, radius and type for its [CalcKeyKind].
///
/// Feedback follows DESIGN: scale to 0.96 and darken the background for 80 ms,
/// plus a selection haptic. The semantic label is [semanticLabel] when given
/// (e.g. "Divide" for `÷`), otherwise the visible [label].
class CalcKeyButton extends StatefulWidget {
  const CalcKeyButton({
    super.key,
    required this.label,
    required this.kind,
    this.onTap,
    this.semanticLabel,
    this.density = CalcKeyDensity.basic,
    this.haptics = true,
  });

  final String label;
  final CalcKeyKind kind;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final CalcKeyDensity density;

  /// SPEC §7 haptic tick; T25/T27 pass the user's setting.
  final bool haptics;

  @override
  State<CalcKeyButton> createState() => _CalcKeyButtonState();
}

class _CalcKeyButtonState extends State<CalcKeyButton> {
  bool _pressed = false;

  bool get _enabled =>
      widget.kind != CalcKeyKind.disabled && widget.onTap != null;

  void _onTap() {
    if (widget.haptics) {
      HapticFeedback.selectionClick();
    }
    widget.onTap?.call();
  }

  void _setPressed(bool pressed) {
    if (_pressed == pressed) {
      return;
    }
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final _KeyStyle style = _styleFor(widget.kind, widget.density);
    final bool pressed = _pressed && _enabled;

    Widget key = AnimatedScale(
      scale: pressed ? AppMotion.keyPressScale : 1,
      duration: AppMotion.keyPress,
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: AppMotion.keyPress,
        height: widget.density.keyHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: pressed ? style.pressedBackground : style.background,
          borderRadius: BorderRadius.circular(widget.density.keyRadius),
          border: style.border == null || style.dashed
              ? null
              : Border.all(
                  color: style.border!,
                  width: AppSizes.borderWidth,
                ),
        ),
        child: Text(
          widget.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style.textStyle.copyWith(color: style.foreground),
        ),
      ),
    );

    if (style.dashed) {
      key = CustomPaint(
        foregroundPainter: _DashedBorderPainter(
          color: style.border ?? AppColors.disabledBorder,
          radius: widget.density.keyRadius,
        ),
        child: key,
      );
    }

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel ?? widget.label,
      onTap: _enabled ? _onTap : null,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _enabled ? _onTap : null,
        onTapDown: _enabled ? (_) => _setPressed(true) : null,
        onTapUp: _enabled ? (_) => _setPressed(false) : null,
        onTapCancel: _enabled ? () => _setPressed(false) : null,
        child: key,
      ),
    );
  }
}

/// The paint values of one kind + density.
final class _KeyStyle {
  const _KeyStyle({
    required this.background,
    required this.foreground,
    required this.textStyle,
    this.border,
    this.dashed = false,
  });

  final Color background;
  final Color? border;
  final Color foreground;
  final TextStyle textStyle;
  final bool dashed;

  Color get pressedBackground => background == AppColors.primary
      ? AppColors.primaryDeep
      : Color.lerp(
          background,
          Colors.black,
          AppMotion.keyPressDarken,
        )!;
}

_KeyStyle _styleFor(CalcKeyKind kind, CalcKeyDensity density) {
  final bool basic = density == CalcKeyDensity.basic;

  return switch (kind) {
    CalcKeyKind.number => _KeyStyle(
      background: basic ? AppColors.keyNumber : AppColors.keyNumberScientific,
      border: AppColors.keyNumberBorder,
      foreground: AppColors.ink,
      textStyle: basic
          ? AppTypography.keyNumberBasic
          : AppTypography.keyNumberScientific,
    ),
    CalcKeyKind.function => _KeyStyle(
      background: basic ? AppColors.keyNumber : AppColors.keyFunction,
      border: AppColors.keyNumberBorder,
      foreground: AppColors.primary,
      textStyle: basic
          ? AppTypography.keyFunctionBasic
          : AppTypography.keyFunction,
    ),
    CalcKeyKind.operator => _KeyStyle(
      background: AppColors.keyOperator,
      border: AppColors.keyOperatorBorder,
      foreground: AppColors.primary,
      textStyle: basic
          ? AppTypography.keyOperatorBasic
          : AppTypography.keyOperatorScientific,
    ),
    CalcKeyKind.equals => _KeyStyle(
      background: AppColors.primary,
      foreground: AppColors.onPrimary,
      textStyle: basic
          ? AppTypography.keyEqualsBasic
          : AppTypography.keyEqualsScientific,
    ),
    CalcKeyKind.disabled => const _KeyStyle(
      background: AppColors.sheet,
      border: AppColors.disabledBorder,
      foreground: AppColors.disabled,
      textStyle: AppTypography.keyDisabled,
      dashed: true,
    ),
  };
}

/// The dashed border of a disabled key (`03-programmer.html`).
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

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
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
