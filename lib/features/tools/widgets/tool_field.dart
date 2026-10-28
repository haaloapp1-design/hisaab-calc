import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// A labelled input on a tool page (SPEC §6, screen 10).
///
/// The label is the 13 px muted line above the 50 px box; [child] is usually a
/// [ToolTextField] but a row also puts a unit toggle or a second field beside
/// one.
class ToolField extends StatelessWidget {
  const ToolField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.toolFieldLabel.copyWith(color: palette.inkMuted),
        ),
        const SizedBox(height: AppSizes.toolLabelGap),
        child,
      ],
    );
  }
}

/// The 50 px rounded box that holds one tool input.
///
/// It is the surface only: a white/blue-tinted fill, the 1 px border and the
/// 14 px side padding from `10-loan-emi.html`.
class ToolFieldBox extends StatelessWidget {
  const ToolFieldBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Container(
      height: AppSizes.toolFieldHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.toolFieldPaddingH,
      ),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: palette.keyNumber,
        border: Border.all(
          color: palette.keyOperatorBorder,
          width: AppSizes.borderWidth,
        ),
        borderRadius: BorderRadius.circular(AppRadii.toolField),
      ),
      child: child,
    );
  }
}

/// The 18 px text field inside a [ToolFieldBox].
///
/// The page owns the [controller] so it can read the typed value on every
/// change and rebuild the result; the field itself is a pure view.
class ToolTextField extends StatelessWidget {
  const ToolTextField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.keyboardType,
    this.inputFormatters = const <TextInputFormatter>[],
    this.fieldKey,
    this.textAlign = TextAlign.left,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;

  /// The key on the inner [TextField], used by the tests.
  final Key? fieldKey;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return TextField(
      key: fieldKey,
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textAlign: textAlign,
      textInputAction: TextInputAction.done,
      maxLines: 1,
      style: AppTypography.toolFieldValue.copyWith(color: palette.ink),
      cursorColor: palette.primaryText,
      decoration: const InputDecoration(
        border: InputBorder.none,
        isCollapsed: true,
      ),
      onChanged: onChanged,
    );
  }
}
