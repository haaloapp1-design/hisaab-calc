import 'package:flutter/material.dart';

import '../../../core/units/unit_catalog.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// The list shown while the hub search has text (screen 06).
class UnitSearchResults extends StatelessWidget {
  const UnitSearchResults({super.key, required this.matches, this.onSelected});

  final List<UnitMatch> matches;
  final void Function(UnitMatch match)? onSelected;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    if (matches.isEmpty) {
      return Center(
        key: const Key('hub-search-empty'),
        child: Text(
          'No units found',
          style: AppTypography.body.copyWith(color: palette.inkMuted),
        ),
      );
    }

    return ListView.separated(
      key: const Key('hub-search-results'),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.hubContentPaddingTop,
        AppSizes.screenPadding,
        AppSizes.hubContentPaddingTop,
      ),
      itemCount: matches.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: AppSizes.hubCellGap),
      itemBuilder: (BuildContext context, int index) {
        final UnitMatch match = matches[index];
        return _UnitResultTile(
          match: match,
          onTap: onSelected == null ? null : () => onSelected!(match),
        );
      },
    );
  }
}

class _UnitResultTile extends StatelessWidget {
  const _UnitResultTile({required this.match, this.onTap});

  final UnitMatch match;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final BorderRadius radius = BorderRadius.circular(AppRadii.card);

    return MergeSemantics(
      child: Material(
        color: palette.sheet,
        borderRadius: radius,
        child: InkWell(
          key: Key('hub-result-${match.category.name}-${match.unit.id}'),
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.hubResultPaddingH,
              vertical: AppSizes.hubResultPaddingV,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: palette.keyNumberBorder,
                width: AppSizes.borderWidth,
              ),
              borderRadius: radius,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        match.unit.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(color: palette.ink),
                      ),
                      const SizedBox(height: AppSizes.hubResultGap),
                      Text(
                        match.category.label,
                        style: AppTypography.small.copyWith(
                          color: palette.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: AppSizes.hubCurrencyChevron,
                  color: palette.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
