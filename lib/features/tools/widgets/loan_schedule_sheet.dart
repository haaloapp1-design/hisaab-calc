import 'package:flutter/material.dart';

import '../../../core/engine/formatter.dart';
import '../../../core/tools/loan.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// Opens the monthly schedule of [result] as a modal sheet.
///
/// The table lists every month with its payment, interest, principal part and
/// remaining balance. It owns its surface because the rows have to scroll
/// inside a fixed height.
Future<void> showLoanScheduleSheet(
  BuildContext context, {
  required LoanResult result,
  required NumberFormatOptions options,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) =>
        _LoanScheduleSheet(result: result, options: options),
  );
}

class _LoanScheduleSheet extends StatelessWidget {
  const _LoanScheduleSheet({required this.result, required this.options});

  final LoanResult result;
  final NumberFormatOptions options;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final double height =
        MediaQuery.sizeOf(context).height * AppSizes.toolScheduleHeightFactor;

    return Container(
      key: const Key('loan-schedule-sheet'),
      height: height,
      decoration: BoxDecoration(
        color: palette.sheet,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSizes.toolSheetPaddingSide,
        AppSizes.toolSheetPaddingTop,
        AppSizes.toolSheetPaddingSide,
        AppSizes.toolSheetPaddingBottom + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              key: const Key('loan-schedule-handle'),
              width: AppSizes.handleWidth,
              height: AppSizes.handleHeight,
              decoration: BoxDecoration(
                color: palette.primary,
                borderRadius: BorderRadius.circular(AppRadii.handle),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sheetContentGap),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Monthly schedule',
                  key: const Key('loan-schedule-title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.hubItemTitle.copyWith(
                    color: palette.ink,
                  ),
                ),
              ),
              IconButton(
                key: const Key('loan-schedule-close'),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: 'Close',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: AppSizes.minTapTarget,
                  minHeight: AppSizes.minTapTarget,
                ),
                iconSize: AppSizes.toolScheduleClose,
                color: palette.inkMuted,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.toolScheduleHeaderGap),
          const _ScheduleRow(
            cells: <String>[
              'Month',
              'Payment',
              'Interest',
              'Principal',
              'Balance',
            ],
            header: true,
          ),
          Divider(
            height: AppSizes.borderWidth,
            thickness: AppSizes.borderWidth,
            color: palette.divider,
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: result.schedule.length,
              itemBuilder: (BuildContext context, int index) {
                final LoanScheduleRow row = result.schedule[index];
                return _ScheduleRow(
                  key: Key('loan-schedule-row-${row.month}'),
                  cells: <String>[
                    '${row.month}',
                    formatLoanMoney(row.payment, options: options),
                    formatLoanMoney(row.interest, options: options),
                    formatLoanMoney(row.principal, options: options),
                    formatLoanMoney(row.balance, options: options),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({super.key, required this.cells, this.header = false});

  final List<String> cells;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle style =
        (header
                ? AppTypography.toolScheduleHeader
                : AppTypography.toolScheduleCell)
            .copyWith(color: header ? palette.inkMuted : palette.ink);

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.toolScheduleRowPaddingV,
        horizontal: AppSizes.toolScheduleRowPaddingH,
      ),
      decoration: header
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: palette.divider,
                  width: AppSizes.borderWidth,
                ),
              ),
            ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: AppSizes.toolScheduleMonthWidth,
            child: Text(
              cells.first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          for (int i = 1; i < cells.length; i++)
            Expanded(
              child: Text(
                cells[i],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: style,
              ),
            ),
        ],
      ),
    );
  }
}
