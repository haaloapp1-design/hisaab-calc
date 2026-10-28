import 'package:flutter/material.dart';

import '../../../core/tools/tool_catalog.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';
import '../tool_scaffold.dart';

/// The temporary page behind every tool tile (T41).
///
/// It already uses [ToolScaffold], so T42–T47 only replace the sheet content
/// and the result with the real inputs and maths.
class ToolPlaceholderPage extends StatelessWidget {
  const ToolPlaceholderPage({super.key, required this.tool});

  final Tool tool;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return ToolScaffold(
      title: tool.name,
      resultLabel: tool.subtitle,
      resultValue: '—',
      children: <Widget>[
        Container(
          key: Key('tool-note-${tool.id}'),
          padding: const EdgeInsets.all(AppSizes.toolNotePadding),
          decoration: BoxDecoration(
            border: Border.all(
              color: palette.keyNumberBorder,
              width: AppSizes.borderWidth,
            ),
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Column(
            children: <Widget>[
              Container(
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
                  style: AppTypography.toolSymbol.copyWith(
                    color: palette.primaryText,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.toolNoteGap),
              Text(
                tool.name,
                textAlign: TextAlign.center,
                style: AppTypography.toolName.copyWith(color: palette.ink),
              ),
              const SizedBox(height: AppSizes.toolsCardTextGap),
              Text(
                tool.subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.toolSubtitle.copyWith(
                  color: palette.inkMuted,
                ),
              ),
              const SizedBox(height: AppSizes.toolSheetGap),
              Text(
                'Coming soon',
                key: const Key('tool-coming-soon'),
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: palette.inkMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
