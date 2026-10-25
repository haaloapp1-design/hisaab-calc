import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';
import 'dashed_border_painter.dart';

/// The five key roles from DESIGN "Components".
enum CalcKeyKind {
  /// Digits, `.` and the constants.
  number,

  /// Function keys such as `sin`, `C`, `%` and `±`.
  function,

  /// The heavier `C`, `⌫` and `±` keys in Scientific mode (SPEC §1.3).
  functionStrong,

  /// A function key whose alternate set is on, such as `2nd`.
  active,

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
    this.onLongPress,
    this.semanticLabel,
    this.density = CalcKeyDensity.basic,
    this.haptics = true,
    this.sounds = false,
  });

  final String label;
  final CalcKeyKind kind;
  final VoidCallback? onTap;

  /// Secondary action, e.g. long-pressing `⌫` to clear (SPEC §1.2).
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final CalcKeyDensity density;

  /// SPEC §7 haptic tick; T25/T27 pass the user's setting.
  final bool haptics;

  /// SPEC §3 "Key sounds": plays the platform click on every accepted key.
  final bool sounds;

  @override
  State<CalcKeyButton> createState() => _CalcKeyButtonState();
}

class _CalcKeyButtonState extends State<CalcKeyButton> {
  bool _pressed = false;

  bool get _enabled =>
      widget.kind != CalcKeyKind.disabled && widget.onTap != null;

  void _feedback() {
    if (widget.haptics) {
      HapticFeedback.selectionClick();
    }
    if (widget.sounds) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  void _onTap() {
    _feedback();
    widget.onTap?.call();
  }

  void _onLongPress() {
    _feedback();
    widget.onLongPress?.call();
  }

  void _setPressed(bool pressed) {
    if (_pressed == pressed) {
      return;
    }
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final _KeyStyle style = _styleFor(widget.kind, widget.density, palette);
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
              : Border.all(color: style.border!, width: AppSizes.borderWidth),
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
        foregroundPainter: DashedBorderPainter(
          color: style.border ?? palette.disabledBorder,
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
      onLongPress: _enabled && widget.onLongPress != null ? _onLongPress : null,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _enabled ? _onTap : null,
        onLongPress: _enabled && widget.onLongPress != null
            ? _onLongPress
            : null,
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
    required this.pressedBackground,
    required this.foreground,
    required this.textStyle,
    this.border,
    this.dashed = false,
  });

  final Color background;
  final Color pressedBackground;
  final Color? border;
  final Color foreground;
  final TextStyle textStyle;
  final bool dashed;
}

_KeyStyle _styleFor(
  CalcKeyKind kind,
  CalcKeyDensity density,
  AppPalette palette,
) {
  final bool basic = density == CalcKeyDensity.basic;
  Color pressed(Color background, {bool accent = false}) => accent
      ? palette.primaryDeep
      : Color.lerp(background, Colors.black, AppMotion.keyPressDarken)!;

  return switch (kind) {
    CalcKeyKind.number => _KeyStyle(
      background: basic ? palette.keyNumber : palette.keyNumberScientific,
      pressedBackground: pressed(
        basic ? palette.keyNumber : palette.keyNumberScientific,
      ),
      border: palette.keyNumberBorder,
      foreground: palette.ink,
      textStyle: basic
          ? AppTypography.keyNumberBasic
          : AppTypography.keyNumberScientific,
    ),
    CalcKeyKind.function => _KeyStyle(
      background: basic ? palette.keyNumber : palette.keyFunction,
      pressedBackground: pressed(
        basic ? palette.keyNumber : palette.keyFunction,
      ),
      border: palette.keyNumberBorder,
      foreground: palette.primary,
      textStyle: basic
          ? AppTypography.keyFunctionBasic
          : AppTypography.keyFunction,
    ),
    CalcKeyKind.functionStrong => _KeyStyle(
      background: palette.keyNumberScientific,
      pressedBackground: pressed(palette.keyNumberScientific),
      border: palette.keyNumberBorder,
      foreground: palette.primary,
      textStyle: basic
          ? AppTypography.keyFunctionBasic
          : AppTypography.keyFunctionStrong,
    ),
    CalcKeyKind.active => _KeyStyle(
      background: palette.primary,
      pressedBackground: palette.primaryDeep,
      foreground: palette.onPrimary,
      textStyle: AppTypography.keyFunctionActive,
    ),
    CalcKeyKind.operator => _KeyStyle(
      background: palette.keyOperator,
      pressedBackground: pressed(palette.keyOperator),
      border: palette.keyOperatorBorder,
      foreground: palette.primary,
      textStyle: basic
          ? AppTypography.keyOperatorBasic
          : AppTypography.keyOperatorScientific,
    ),
    CalcKeyKind.equals => _KeyStyle(
      background: palette.primary,
      pressedBackground: palette.primaryDeep,
      foreground: palette.onPrimary,
      textStyle: basic
          ? AppTypography.keyEqualsBasic
          : AppTypography.keyEqualsScientific,
    ),
    CalcKeyKind.disabled => _KeyStyle(
      background: palette.sheet,
      pressedBackground: palette.sheet,
      border: palette.disabledBorder,
      foreground: palette.disabled,
      textStyle: AppTypography.keyDisabled,
      dashed: true,
    ),
  };
}
