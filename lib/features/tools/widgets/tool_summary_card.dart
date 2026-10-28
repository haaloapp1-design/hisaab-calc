import 'package:flutter/material.dart';

import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// One label / value line in a [ToolSummaryCard].
class ToolSummaryRow {
  const ToolSummaryRow({
    required this.label,
    required this.value,
    this.valueKey,
  });

  final String label;
  final String value;

  /// Optional key on the value text, used by the page tests.
  final Key? valueKey;
}

/// The bordered breakdown card shared by the tool pages.
///
/// It is the loan breakdown without the bar: a few 14 px rows and an optional
/// emphasised total behind a divider. The page formats every value.
class ToolSummaryCard extends StatelessWidget {
  const ToolSummaryCard({super.key, required this.rows, this.total});

  final List<ToolSummaryRow> rows;

  /// The bold last row, drawn above a divider.
  final ToolSummaryRow? total;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSizes.toolBreakdownPadding),
      decoration: BoxDecoration(
        border: Border.all(
          color: palette.keyNumberBorder,
          width: AppSizes.borderWidth,
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: AppSizes.toolBreakdownGap),
            _SummaryLine(row: rows[i], emphasis: false),
          ],
          if (total != null) ...<Widget>[
            const SizedBox(height: AppSizes.toolBreakdownGap),
            Container(
              padding: const EdgeInsets.only(top: AppSizes.toolTotalPaddingTop),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: palette.divider,
                    width: AppSizes.borderWidth,
                  ),
                ),
              ),
              child: _SummaryLine(row: total!, emphasis: true),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.row, required this.emphasis});

  final ToolSummaryRow row;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle style =
        (emphasis
                ? AppTypography.toolBreakdownTotal
                : AppTypography.toolBreakdownRow)
            .copyWith(color: palette.ink);

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            row.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        Text(row.value, key: row.valueKey, style: style),
      ],
    );
  }
}
