import 'package:flutter/material.dart';

import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// The search bar that replaces nothing but sits under the History header
/// when the header's search action is on.
///
/// It is the blue counterpart of the settings inputs: same 14 px radius,
/// white text and a muted hint, because it lives on the primary surface. The
/// hint and the magnifier use `onPrimaryMuted` (4.81:1 on the track) rather
/// than `onPrimaryFaint` (4.07:1) so the small text stays at AA (T48).
class HistorySearchField extends StatelessWidget {
  const HistorySearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClose,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.historySearchTopGap,
        AppSizes.screenPadding,
        0,
      ),
      child: Container(
        height: AppSizes.historyActionHeight,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.historySearchPaddingH,
        ),
        decoration: BoxDecoration(
          color: palette.primaryTrack,
          borderRadius: BorderRadius.circular(AppRadii.historySearch),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.search_rounded,
              size: AppSizes.searchIcon,
              color: palette.onPrimaryMuted,
            ),
            const SizedBox(width: AppSizes.historySearchPaddingH),
            Expanded(
              child: TextField(
                key: const Key('history-search'),
                controller: controller,
                autofocus: true,
                cursorColor: palette.onPrimary,
                style: AppTypography.body.copyWith(color: palette.onPrimary),
                textInputAction: TextInputAction.search,
                onChanged: (String _) => onChanged(),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Search history',
                  hintStyle: AppTypography.body.copyWith(
                    color: palette.onPrimaryMuted,
                  ),
                ),
              ),
            ),
            IconButton(
              key: const Key('history-search-close'),
              onPressed: onClose,
              tooltip: 'Close search',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: AppSizes.minTapTarget,
                minHeight: AppSizes.minTapTarget,
              ),
              iconSize: AppSizes.searchIcon,
              color: palette.onPrimaryMuted,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
