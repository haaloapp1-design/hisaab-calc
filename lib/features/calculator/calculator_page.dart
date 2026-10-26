import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/engine/angle_mode.dart';
import '../../core/engine/formatter.dart';
import '../../core/memory/memory_slots.dart';
import '../../core/programmer/word.dart';
import '../../shared/widgets/blue_header.dart';
import '../../shared/widgets/segmented.dart';
import '../../shared/widgets/white_sheet.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_tokens.dart';
import '../history/memory_controller.dart';
import '../history/widgets/memory_menu.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_format.dart';
import '../settings/settings_model.dart';
import '../settings/settings_page.dart';
import 'calc_state.dart';
import 'calculator_controller.dart';
import 'keypads/basic_keys.dart';
import 'keypads/programmer_keys.dart';
import 'keypads/scientific_keys.dart';
import 'prog_state.dart';
import 'programmer_controller.dart';
import 'widgets/angle_controls.dart';
import 'widgets/calc_key_button.dart';
import 'widgets/display.dart';
import 'widgets/keypad.dart';
import 'widgets/programmer_display.dart';
import 'widgets/word_size_menu.dart';

/// The Calculator tab (SPEC §1, screens 01–03).
///
/// Blue top area (header, mode switcher, display) and the white keypad sheet.
/// The page formats state values and forwards keys; it owns no maths. Basic
/// (T23), Scientific (T24) and Programmer (T33) are wired end to end.
class CalculatorPage extends ConsumerWidget {
  const CalculatorPage({super.key});

  static const List<String> _modes = <String>[
    'Basic',
    'Scientific',
    'Programmer',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final CalcState calc = ref.watch(calculatorProvider);
    final ProgState prog = ref.watch(programmerProvider);
    final Settings settings = ref.watch(settingsProvider);
    final memory = ref.watch(memoryProvider);
    final CalculatorController controller = ref.read(
      calculatorProvider.notifier,
    );
    final ProgrammerController progController = ref.read(
      programmerProvider.notifier,
    );

    // The angle lives in Settings (T27); the calculator keeps a mirror so its
    // previews and `=` use the same value.
    ref.listen<AngleMode>(
      settingsProvider.select((Settings value) => value.angleMode),
      (AngleMode? previous, AngleMode next) => controller.setAngleMode(next),
    );

    final bool scientific = calc.mode == CalcMode.scientific;
    final bool programmer = calc.mode == CalcMode.programmer;
    final NumberFormatOptions format = numberFormatFor(settings);

    return ColoredBox(
      color: palette.primary,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            BlueHeader(
              title: 'Hisab',
              actionIcon: Icons.tune_rounded,
              actionTooltip: 'Settings',
              onAction: () => _openSettings(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                AppSizes.segmentedTopGap,
                AppSizes.screenPadding,
                0,
              ),
              child: Segmented(
                labels: _modes,
                selectedIndex: calc.mode.index,
                onSelected: (int index) =>
                    controller.setMode(CalcMode.values[index]),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (scientific)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.displayPaddingSide,
                        0,
                        AppSizes.displayPaddingSide,
                        AppSizes.angleRowBottomGap,
                      ),
                      child: AngleControls(
                        angleMode: settings.angleMode,
                        onChanged: ref
                            .read(settingsProvider.notifier)
                            .setAngleMode,
                        openBrackets: calc.openBrackets,
                      ),
                    ),
                  if (programmer)
                    Flexible(
                      // A scroll view keeps the fixed rows usable on shorter
                      // screens instead of overflowing; it is at the bottom so
                      // the value and base rows stay in view.
                      child: SingleChildScrollView(
                        reverse: true,
                        child: ProgrammerDisplay(
                          state: prog,
                          options: format,
                          onBaseSelected: progController.selectBase,
                          onWordSizeTap: () => _showWordSizeMenu(context, ref),
                        ),
                      ),
                    )
                  else
                    Display(
                      expression: calc.justEvaluated
                          ? ''
                          : formatExpression(
                              calc.buffer.tokens,
                              options: format,
                            ),
                      result: formatNumber(calc.displayValue, options: format),
                      preview: calc.result == null && calc.preview != null,
                      error: calc.error,
                      memory: MemorySlots.showsChip(memory)
                          ? formatNumber(
                              MemorySlots.mainOrZero(memory),
                              options: format,
                            )
                          : null,
                      onMemoryLongPress: () => _showMemoryMenu(context, ref),
                      density: scientific
                          ? DisplayDensity.scientific
                          : DisplayDensity.basic,
                    ),
                ],
              ),
            ),
            WhiteSheet(
              padding: scientific || programmer
                  ? const EdgeInsets.fromLTRB(
                      AppSizes.sheetScientificPaddingSide,
                      AppSizes.sheetPaddingTop,
                      AppSizes.sheetScientificPaddingSide,
                      AppSizes.sheetPaddingBottom,
                    )
                  : null,
              contentGap: scientific || programmer
                  ? AppSizes.sheetScientificContentGap
                  : null,
              child: programmer
                  ? Keypad(
                      key: ValueKey<CalcMode>(calc.mode),
                      spec: programmerKeys(
                        onKey: progController.onKey,
                        base: prog.base,
                      ),
                      columns: 5,
                      density: CalcKeyDensity.scientific,
                      haptics: settings.haptics,
                      sounds: settings.keySounds,
                    )
                  : scientific
                  ? Keypad(
                      key: ValueKey<CalcMode>(calc.mode),
                      spec: scientificKeys(
                        onKey: controller.onKey,
                        second: calc.second,
                        onSecond: controller.toggleSecond,
                      ),
                      columns: 5,
                      density: CalcKeyDensity.scientific,
                      haptics: settings.haptics,
                      sounds: settings.keySounds,
                    )
                  : Keypad(
                      key: ValueKey<CalcMode>(calc.mode),
                      spec: basicKeys(controller.onKey),
                      columns: 4,
                      haptics: settings.haptics,
                      sounds: settings.keySounds,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// SPEC 2: a long press on the memory chip offers MS and MC.
  Future<void> _showMemoryMenu(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) => MemoryMenu(
        onStore: () {
          Navigator.of(sheetContext).pop();
          ref
              .read(memoryProvider.notifier)
              .store(ref.read(calculatorProvider).displayValue);
        },
        onClear: () {
          Navigator.of(sheetContext).pop();
          ref.read(memoryProvider.notifier).clearSlot(0);
        },
      ),
    );
  }

  /// SPEC §1.4: the word-size chip offers 8 / 16 / 32 / 64-bit.
  ///
  /// §11 asks for a short toast when the new width truncates the value.
  Future<void> _showWordSizeMenu(BuildContext context, WidgetRef ref) async {
    final WordSize? picked = await showModalBottomSheet<WordSize>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => WordSizeMenu(selected: ref.read(programmerProvider).size),
    );
    if (picked == null || !context.mounted) {
      return;
    }
    final bool truncated = ref
        .read(programmerProvider.notifier)
        .setSize(picked);
    if (!truncated) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Value truncated to ${picked.label}'),
        // Floating keeps the toast above the keypad instead of covering it.
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Pushes the Settings screen over the shell, full screen like screen 05.
  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const SettingsPage(),
      ),
    );
  }
}
