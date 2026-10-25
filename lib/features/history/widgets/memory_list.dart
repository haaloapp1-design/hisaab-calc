import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/formatter.dart';
import '../../../core/memory/memory_slots.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';
import '../../calculator/calculator_controller.dart';
import '../../settings/settings_controller.dart';
import '../../settings/settings_format.dart';
import '../memory_controller.dart';
import 'memory_slot_card.dart';

/// The Memory tab (SPEC 2, screen `04-history-memory.html`).
///
/// Lists the slots that hold a value, M1 first. `MR` inserts that value into
/// the calculator and switches to it; `M+` / `M-` change the slot by the
/// calculator's current display value (BUSINESS_LOGIC 9).
class MemoryList extends ConsumerWidget {
  const MemoryList({super.key, this.onOpenCalculator});

  /// Switches the shell to the Calculator tab after a recall.
  final VoidCallback? onOpenCalculator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Decimal?> slots = ref.watch(memoryProvider);
    final List<int> used = MemorySlots.usedSlots(slots);
    final AppPalette palette = AppPalette.of(context);

    if (used.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'No saved memory yet',
                key: const Key('memory-empty'),
                textAlign: TextAlign.center,
                style: AppTypography.historyEmpty.copyWith(
                  color: palette.onPrimaryMuted,
                ),
              ),
              const SizedBox(height: AppSizes.historyActionGap),
              // The chip is hidden while memory is empty, so the first `MS`
              // needs a visible home (T30 decision).
              Semantics(
                button: true,
                child: GestureDetector(
                  key: const Key('memory-empty-store'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => ref
                      .read(memoryProvider.notifier)
                      .store(ref.read(calculatorProvider).displayValue),
                  child: Container(
                    height: AppSizes.memoryButtonHeight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.memoryButtonPaddingH,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: palette.onPrimary,
                      borderRadius: BorderRadius.circular(
                        AppRadii.memoryButton,
                      ),
                    ),
                    child: Text(
                      'Store current value',
                      style: AppTypography.memoryRecall.copyWith(
                        color: palette.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final NumberFormatOptions format = numberFormatFor(
      ref.watch(settingsProvider),
    );

    return ListView.separated(
      key: const Key('memory-list'),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.memoryListPaddingSide,
        AppSizes.memoryListPaddingTop,
        AppSizes.memoryListPaddingSide,
        0,
      ),
      itemCount: used.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: AppSizes.memoryCardGap),
      itemBuilder: (BuildContext context, int row) {
        final int index = used[row];
        final Decimal value = slots[index]!;

        return MemorySlotCard(
          index: index,
          value: formatNumber(value, options: format),
          onRecall: () {
            ref.read(calculatorProvider.notifier).insertMemory(value);
            onOpenCalculator?.call();
          },
          onAdd: () => ref
              .read(memoryProvider.notifier)
              .addTo(index, ref.read(calculatorProvider).displayValue),
          onSubtract: () => ref
              .read(memoryProvider.notifier)
              .subtractFrom(index, ref.read(calculatorProvider).displayValue),
        );
      },
    );
  }
}
