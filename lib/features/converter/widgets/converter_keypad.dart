import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/widgets/white_sheet.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';
import '../converter_key.dart';

/// The 4×4 keypad on the white sheet of the unit converter (screen 07).
class ConverterKeypad extends StatelessWidget {
  const ConverterKeypad({
    super.key,
    required this.onKey,
    this.onLongPress,
    this.haptics = true,
    this.sounds = false,
  });

  final ValueChanged<ConverterKey> onKey;

  /// Long-press actions; `Copy` saves the result to history (T38).
  final ValueChanged<ConverterKey>? onLongPress;

  /// SPEC §3 "Vibrate on key press".
  final bool haptics;

  /// SPEC §3 "Key sounds".
  final bool sounds;

  void _feedback() {
    if (haptics) {
      HapticFeedback.selectionClick();
    }
    if (sounds) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return WhiteSheet(
      padding: EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.sheetPaddingTop,
        AppSizes.screenPadding,
        AppSizes.converterSheetPaddingBottom + bottomInset,
      ),
      contentGap: AppSizes.converterKeypadGap,
      child: Column(
        children: <Widget>[
          for (int row = 0; row < 4; row++) ...<Widget>[
            if (row > 0) const SizedBox(height: AppSizes.keyGapConverter),
            Row(
              children: <Widget>[
                for (int column = 0; column < 4; column++) ...<Widget>[
                  if (column > 0)
                    const SizedBox(width: AppSizes.keyGapConverter),
                  Expanded(
                    child: _ConverterKeyButton(
                      converterKey: ConverterKey.values[row * 4 + column],
                      onTap: () {
                        _feedback();
                        onKey(ConverterKey.values[row * 4 + column]);
                      },
                      onLongPress: onLongPress == null
                          ? null
                          : () {
                              _feedback();
                              onLongPress!(
                                ConverterKey.values[row * 4 + column],
                              );
                            },
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ConverterKeyButton extends StatelessWidget {
  const _ConverterKeyButton({
    required this.converterKey,
    required this.onTap,
    this.onLongPress,
  });

  final ConverterKey converterKey;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool isFunction = converterKey.isFunction;
    final BorderRadius radius = BorderRadius.circular(AppRadii.keyConverter);

    return SizedBox(
      height: AppSizes.keyHeightConverter,
      child: Semantics(
        button: true,
        label: converterKey.semanticLabel,
        hint: converterKey == ConverterKey.copy
            ? 'Long-press to save to history'
            : null,
        onTap: onTap,
        onLongPress: onLongPress,
        excludeSemantics: true,
        child: Material(
          color: isFunction ? palette.keyOperator : palette.keyNumber,
          borderRadius: radius,
          child: InkWell(
            key: Key('converter-key-${converterKey.name}'),
            borderRadius: radius,
            onTap: onTap,
            onLongPress: onLongPress,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: isFunction
                      ? palette.keyOperatorBorder
                      : palette.keyNumberBorder,
                  width: AppSizes.borderWidth,
                ),
              ),
              child: Text(
                converterKey.label,
                maxLines: 1,
                style:
                    (isFunction
                            ? AppTypography.converterKeyFunction
                            : AppTypography.converterKeyNumber)
                        .copyWith(
                          color: isFunction ? palette.primaryText : palette.ink,
                        ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
