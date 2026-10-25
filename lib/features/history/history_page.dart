import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/blue_header.dart';
import '../../shared/widgets/segmented.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_tokens.dart';
import '../calculator/calc_state.dart';
import '../calculator/calculator_controller.dart';
import 'history_controller.dart';
import 'history_entry.dart';
import 'history_log.dart';
import 'widgets/history_actions.dart';
import 'widgets/history_entry_sheet.dart';
import 'widgets/history_list.dart';
import 'widgets/history_search_field.dart';

/// The History tab (SPEC §2, screen `04-history-memory.html`).
///
/// Blue header with a search action, the History | Memory switcher and the
/// grouped list of saved calculations. The white sheet holds "Copy all" and
/// "Clear history". Tapping an entry loads it into the calculator and switches
/// to that tab through [onOpenCalculator]; long-pressing offers copy/delete.
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key, this.onOpenCalculator});

  /// Switches the shell to the Calculator tab after an entry is loaded.
  final VoidCallback? onOpenCalculator;

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  static const List<String> _tabs = <String>['History', 'Memory'];

  final TextEditingController _search = TextEditingController();
  bool _searching = false;
  int _tab = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final List<HistoryEntry> entries = ref.watch(historyProvider);
    final List<HistoryEntry> visible = HistoryLog.search(entries, _search.text);
    final bool historyTab = _tab == 0;

    return ColoredBox(
      color: palette.primary,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            BlueHeader(
              title: 'History',
              onBack: widget.onOpenCalculator,
              actionIcon: Icons.search_rounded,
              actionIconSize: AppSizes.searchIcon,
              actionTooltip: 'Search history',
              onAction: _toggleSearch,
            ),
            if (_searching)
              HistorySearchField(
                controller: _search,
                onChanged: _refreshSearch,
                onClose: _toggleSearch,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                AppSizes.segmentedTopGap,
                AppSizes.screenPadding,
                0,
              ),
              child: Segmented(
                labels: _tabs,
                selectedIndex: _tab,
                onSelected: (int index) => setState(() => _tab = index),
              ),
            ),
            Expanded(
              child: historyTab
                  ? HistoryList(
                      groups: HistoryLog.groupByDay(
                        visible,
                        now: DateTime.now(),
                      ),
                      searching: _search.text.trim().isNotEmpty,
                      onTap: _load,
                      onLongPress: _showEntryActions,
                    )
                  : const _MemoryPlaceholder(),
            ),
            HistoryActions(
              onCopyAll: () => _copyAll(visible),
              onClear: _confirmClear,
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (_searching) {
        _tab = 0;
      } else {
        _search.clear();
      }
    });
  }

  void _refreshSearch() => setState(() {});

  /// SPEC §2 tap: load the expression in the entry's mode and show the
  /// calculator. Converter/tool entries have no calculator mode yet (T37+).
  void _load(HistoryEntry entry) {
    final CalcMode? mode = switch (entry.mode) {
      HistoryMode.basic => CalcMode.basic,
      HistoryMode.scientific => CalcMode.scientific,
      HistoryMode.programmer => CalcMode.programmer,
      HistoryMode.converter || HistoryMode.tool => null,
    };
    if (mode == null) {
      return;
    }
    final bool loaded = ref
        .read(calculatorProvider.notifier)
        .loadExpression(entry.expression, mode: mode);
    if (loaded) {
      widget.onOpenCalculator?.call();
    }
  }

  Future<void> _copyAll(List<HistoryEntry> entries) async {
    if (entries.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: HistoryLog.asText(entries)));
    _toast('History copied');
  }

  Future<void> _copyEntry(HistoryEntry entry) async {
    await Clipboard.setData(ClipboardData(text: HistoryLog.entryText(entry)));
    _toast('Calculation copied');
  }

  void _toast(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showEntryActions(HistoryEntry entry) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) => HistoryEntrySheet(
        entry: entry,
        onCopy: () {
          Navigator.of(sheetContext).pop();
          _copyEntry(entry);
        },
        onDelete: () {
          Navigator.of(sheetContext).pop();
          ref.read(historyProvider.notifier).remove(entry.id);
        },
      ),
    );
  }

  Future<void> _confirmClear() async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            key: const Key('history-clear-dialog'),
            title: const Text('Clear history?'),
            content: const Text(
              'Every saved calculation will be removed. This cannot be undone.',
            ),
            actions: <Widget>[
              TextButton(
                key: const Key('history-clear-cancel'),
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                key: const Key('history-clear-confirm'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  'Clear',
                  style: AppTypography.body.copyWith(
                    color: AppPalette.of(context).danger,
                    fontWeight: AppTypography.medium,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) {
      return;
    }
    await ref.read(historyProvider.notifier).clear();
  }
}

/// The Memory tab is T30; until then it explains the empty state.
class _MemoryPlaceholder extends StatelessWidget {
  const _MemoryPlaceholder();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
        child: Text(
          'No saved memory yet',
          key: const Key('history-memory-placeholder'),
          textAlign: TextAlign.center,
          style: AppTypography.historyEmpty.copyWith(
            color: palette.onPrimaryMuted,
          ),
        ),
      ),
    );
  }
}
