import 'package:flutter/material.dart';

import '../../../core/units/unit_catalog.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// The twelve category tiles under the currency card (screen 06).
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key, this.onSelected});

  final ValueChanged<UnitCategory>? onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: const Key('hub-category-grid'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppSizes.hubGridColumns,
        mainAxisSpacing: AppSizes.hubGridGap,
        crossAxisSpacing: AppSizes.hubGridGap,
        mainAxisExtent: AppSizes.hubCellHeight,
      ),
      itemCount: UnitCatalog.categories.length,
      itemBuilder: (BuildContext context, int index) {
        final UnitCategory category = UnitCatalog.categories[index].category;
        return _CategoryCell(
          category: category,
          onTap: onSelected == null ? null : () => onSelected!(category),
        );
      },
    );
  }
}

class _CategoryCell extends StatelessWidget {
  const _CategoryCell({required this.category, this.onTap});

  final UnitCategory category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final BorderRadius radius = BorderRadius.circular(AppRadii.card);

    return Material(
      color: palette.sheet,
      borderRadius: radius,
      child: InkWell(
        key: Key('hub-category-${category.name}'),
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: palette.keyNumberBorder,
              width: AppSizes.borderWidth,
            ),
            borderRadius: radius,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                key: Key('hub-chip-${category.name}'),
                constraints: const BoxConstraints(
                  minWidth: AppSizes.hubChipMinWidth,
                ),
                height: AppSizes.hubChipHeight,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.hubChipPaddingH,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.keyOperator,
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
                child: Text(
                  category.hubSymbol,
                  maxLines: 1,
                  style: AppTypography.hubChip.copyWith(color: palette.primary),
                ),
              ),
              const SizedBox(height: AppSizes.hubCellGap),
              Text(
                category.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.small.copyWith(color: palette.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
