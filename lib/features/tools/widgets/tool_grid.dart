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
    final double textScale = MediaQuery.textScalerOf(context).scale(1);

    return GridView.builder(
      key: const Key('tools-grid'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppSizes.toolsGridColumns,
        mainAxisSpacing: AppSizes.toolsGridGap,
        crossAxisSpacing: AppSizes.toolsGridGap,
        // The 92 px design card fits the 1.0× type. At a larger text scale the
        // chip and the two text lines need more room, so the card grows with
        // the scale instead of overflowing (SPEC §7).
        mainAxisExtent:
            AppSizes.toolsCardHeight * (textScale < 1 ? 1 : textScale),
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

/// One 92 px white card at 1.0× (taller at a larger text scale): symbol chip on
/// top, name and subtitle at the bottom. The whole card is one semantics node
/// labelled with its name and subtitle.
class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool, this.onTap});

  final Tool tool;
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
                      style: AppTypography.toolName.copyWith(
                        color: palette.ink,
                      ),
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
      ),
    );
  }
}
