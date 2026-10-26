import 'package:flutter/material.dart';

import '../../../core/units/unit_catalog.dart';
import '../../../shared/widgets/white_sheet.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// Opens the bottom-sheet list of [category]'s units and returns the pick.
Future<Unit?> showUnitPickerSheet(
  BuildContext context, {
  required UnitCategory category,
  required Unit selected,
  required String title,
}) {
  return showModalBottomSheet<Unit>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) =>
        _UnitPickerSheet(category: category, selected: selected, title: title),
  );
}

class _UnitPickerSheet extends StatelessWidget {
  const _UnitPickerSheet({
    required this.category,
    required this.selected,
    required this.title,
  });

  final UnitCategory category;
  final Unit selected;
  final String title;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final List<Unit> units = UnitCatalog.of(category).units;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.sizeOf(context).height *
            AppSizes.converterPickerMaxHeight,
      ),
      child: WhiteSheet(
        padding: EdgeInsets.fromLTRB(
          AppSizes.screenPadding,
          AppSizes.sheetPaddingTop,
          AppSizes.screenPadding,
          AppSizes.converterSheetPaddingBottom +
              MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              title,
              style: AppTypography.hubItemTitle.copyWith(color: palette.ink),
            ),
            const SizedBox(height: AppSizes.converterPickerTitleGap),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: units.length,
                itemBuilder: (BuildContext context, int index) {
                  final Unit unit = units[index];
                  return _UnitRow(unit: unit, selected: unit.id == selected.id);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({required this.unit, required this.selected});

  final Unit unit;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return SizedBox(
      height: AppSizes.converterPickerRowHeight,
      child: InkWell(
        key: Key('picker-unit-${unit.id}'),
        onTap: () => Navigator.of(context).pop(unit),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: palette.divider,
                width: AppSizes.borderWidth,
              ),
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  unit.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    color: selected ? palette.primary : palette.ink,
                    fontWeight: selected
                        ? AppTypography.medium
                        : AppTypography.regular,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_rounded,
                  size: AppSizes.converterPickerCheck,
                  color: palette.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
