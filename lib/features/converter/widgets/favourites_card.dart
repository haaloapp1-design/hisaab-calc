import 'package:flutter/material.dart';

import '../../../core/units/converter_memory.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// The starred pairs at the top of the converter hub (SPEC §4).
///
/// Screen 06 has no favourite design, so this follows the hub's card language:
/// a white rounded card with the hub border, one row per pair and the primary
/// chevron the other cards use.
class FavouritesCard extends StatelessWidget {
  const FavouritesCard({
    super.key,
    required this.favourites,
    required this.onSelected,
  });

  final List<ConverterPair> favourites;
  final ValueChanged<ConverterPair> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final BorderRadius radius = BorderRadius.circular(AppRadii.cardLarge);

    return Material(
      color: palette.sheet,
      borderRadius: radius,
      child: Container(
        key: const Key('hub-favourites'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.hubFavouritePaddingH,
          vertical: AppSizes.hubFavouritePaddingV,
        ),
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: palette.keyNumberBorder,
            width: AppSizes.borderWidth,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Favourites',
              style: AppTypography.converterAlsoTitle.copyWith(
                color: palette.inkMuted,
              ),
            ),
            const SizedBox(height: AppSizes.hubFavouriteTitleGap),
            for (int i = 0; i < favourites.length; i++)
              _FavouriteRow(
                pair: favourites[i],
                showDivider: i > 0,
                onTap: () => onSelected(favourites[i]),
              ),
          ],
        ),
      ),
    );
  }
}

class _FavouriteRow extends StatelessWidget {
  const _FavouriteRow({
    required this.pair,
    required this.showDivider,
    required this.onTap,
  });

  final ConverterPair pair;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return MergeSemantics(
      child: InkWell(
        key: Key(
          'hub-favourite-${pair.category.name}-${pair.from.id}-${pair.to.id}',
        ),
        onTap: onTap,
        child: Container(
          height: AppSizes.hubFavouriteRowHeight,
          decoration: BoxDecoration(
            border: showDivider
                ? Border(
                    top: BorderSide(
                      color: palette.navDivider,
                      width: AppSizes.borderWidth,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.star_rounded,
                size: AppSizes.hubFavouriteIcon,
                color: palette.primary,
              ),
              const SizedBox(width: AppSizes.hubFavouriteGap),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      pair.category.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        color: palette.ink,
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                    Text(
                      '${pair.from.symbol} → ${pair.to.symbol}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.small.copyWith(
                        color: palette.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: AppSizes.hubFavouriteChevron,
                color: palette.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
