import 'package:flutter/material.dart';

import '../../../core/tools/tool_catalog.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// The ten tool cards of screen 09 in a two-column grid.
class ToolGrid extends StatelessWidget {
  const ToolGrid({super.key, this.onSelected});

  final ValueChanged<Tool>? onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: const Key('tools-grid'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppSizes.toolsGridColumns,
        mainAxisSpacing: AppSizes.toolsGridGap,
        crossAxisSpacing: AppSizes.toolsGridGap,
        mainAxisExtent: AppSizes.toolsCardHeight,
      ),
      itemCount: ToolCatalog.tools.length,
      itemBuilder: (BuildContext context, int index) {
        final Tool tool = ToolCatalog.tools[index];
        return _ToolCard(
          tool: tool,
          onTap: onSelected == null ? null : () => onSelected!(tool),
        );
      },
    );
  }
}

/// One 92 px white card: symbol chip on top, name and subtitle at the bottom.
class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool, this.onTap});

  final Tool tool;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final BorderRadius radius = BorderRadius.circular(AppRadii.card);

    return Material(
      color: palette.sheet,
      borderRadius: radius,
      child: InkWell(
        key: Key('tool-card-${tool.id}'),
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.toolsCardPaddingH,
            vertical: AppSizes.toolsCardPaddingV,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: palette.keyNumberBorder,
              width: AppSizes.borderWidth,
            ),
            borderRadius: radius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                key: Key('tool-chip-${tool.id}'),
                constraints: const BoxConstraints(
                  minWidth: AppSizes.toolsChipMinWidth,
                ),
                height: AppSizes.toolsChipHeight,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.toolsChipPaddingH,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.keyOperator,
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
                child: Text(
                  tool.symbol,
                  maxLines: 1,
                  style: AppTypography.toolSymbol.copyWith(
                    color: palette.primary,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    tool.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.toolName.copyWith(color: palette.ink),
                  ),
                  const SizedBox(height: AppSizes.toolsCardTextGap),
                  Text(
                    tool.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.toolSubtitle.copyWith(
                      color: palette.inkMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
