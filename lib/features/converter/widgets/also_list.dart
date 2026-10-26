import 'package:flutter/material.dart';

import '../../../core/units/unit_catalog.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// One row of the "is also" list: a unit and the same amount in it.
class AlsoRow {
  const AlsoRow(this.unit, this.value);

  final Unit unit;
  final String value;
}

/// The "5 km is also" list under the rule line (screen 07).
class AlsoList extends StatelessWidget {
  const AlsoList({super.key, required this.heading, required this.rows});

  final String heading;
  final List<AlsoRow> rows;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.converterAlsoPaddingSide,
        AppSizes.converterAlsoPaddingTop,
        AppSizes.converterAlsoPaddingSide,
        AppSizes.converterAlsoPaddingBottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            heading,
            key: const Key('converter-also-heading'),
            style: AppTypography.converterAlsoTitle.copyWith(
              color: palette.onPrimaryMuted,
            ),
          ),
          const SizedBox(height: AppSizes.converterAlsoTitleGap),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: rows.length,
              itemBuilder: (BuildContext context, int index) {
                final AlsoRow row = rows[index];
                return Container(
                  key: Key('converter-also-${row.unit.id}'),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSizes.converterAlsoRowPaddingV,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: palette.dividerOnPrimary,
                        width: AppSizes.borderWidth,
                      ),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          row.unit.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body.copyWith(
                            color: palette.onPrimaryMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.converterAlsoValueGap),
                      Text(
                        row.value,
                        style: AppTypography.body.copyWith(
                          color: palette.onPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
