import 'package:flutter/material.dart';

import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';
import '../history_entry.dart';
import '../history_log.dart';
import 'history_entry_tile.dart';

/// The grouped History list from screen 04.
///
/// Day labels are 13/700 muted; each group is separated by 10 px and the rows
/// by 6 px, with 16 px above and 24 px at the sides. An empty result shows the
/// matching empty state instead of an empty scroll view.
class HistoryList extends StatelessWidget {
  const HistoryList({
    super.key,
    required this.groups,
    required this.searching,
    required this.onTap,
    required this.onLongPress,
  });

  final List<HistoryDayGroup> groups;

  /// True when a search query is active, which changes the empty message.
  final bool searching;

  final ValueChanged<HistoryEntry> onTap;
  final ValueChanged<HistoryEntry> onLongPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    if (groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenPadding,
          ),
          child: Text(
            searching
                ? 'No matching calculations'
                : 'No saved calculations yet',
            key: const Key('history-empty'),
            textAlign: TextAlign.center,
            style: AppTypography.historyEmpty.copyWith(
              color: palette.onPrimaryMuted,
            ),
          ),
        ),
      );
    }

    return ListView(
      key: const Key('history-list'),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.historyListPaddingSide,
        AppSizes.historyListPaddingTop,
        AppSizes.historyListPaddingSide,
        AppSizes.historyListPaddingBottom,
      ),
      children: <Widget>[
        for (int groupIndex = 0; groupIndex < groups.length; groupIndex++)
          ..._group(
            groups[groupIndex],
            first: groupIndex == 0,
            palette: palette,
          ),
      ],
    );
  }

  List<Widget> _group(
    HistoryDayGroup group, {
    required bool first,
    required AppPalette palette,
  }) {
    return <Widget>[
      if (!first) const SizedBox(height: AppSizes.historyGroupTopGap),
      Text(
        group.label,
        style: AppTypography.historyDay.copyWith(color: palette.onPrimaryMuted),
      ),
      const SizedBox(height: AppSizes.historyGroupGap),
      for (int index = 0; index < group.entries.length; index++) ...<Widget>[
        if (index > 0) const SizedBox(height: AppSizes.historyGroupGap),
        HistoryEntryTile(
          entry: group.entries[index],
          onTap: () => onTap(group.entries[index]),
          onLongPress: () => onLongPress(group.entries[index]),
        ),
      ],
    ];
  }
}
