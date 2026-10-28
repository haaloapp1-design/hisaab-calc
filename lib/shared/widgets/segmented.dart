import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import '../../theme/app_tokens.dart';

/// The pill row that switches Basic / Scientific / Programmer (DESIGN
/// "Components", `01-basic.html`).
///
/// It is a pure view: the caller keeps the selected index and rebuilds with
/// the new [selectedIndex]. Every label gets an equal share of the 44 px
/// track, which the 4 px gaps and 4 px track padding carve up.
class Segmented extends StatelessWidget {
  const Segmented({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  }) : assert(selectedIndex >= 0, 'selectedIndex cannot be negative');

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final double pillHeight =
        AppSizes.segmentedHeight - AppSizes.segmentTrackPadding * 2;

    return Container(
      key: const Key('segmented'),
      height: AppSizes.segmentedHeight,
      padding: const EdgeInsets.all(AppSizes.segmentTrackPadding),
      decoration: BoxDecoration(
        color: palette.primaryTrack,
        borderRadius: BorderRadius.circular(AppRadii.segmentedTrack),
      ),
      child: Row(
        children: <Widget>[
          for (int index = 0; index < labels.length; index++) ...<Widget>[
            if (index > 0) const SizedBox(width: AppSizes.segmentGap),
            Expanded(
              child: _Segment(
                index: index,
                label: labels[index],
                height: pillHeight,
                selected: index == selectedIndex,
                onTap: () => onSelected(index),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.index,
    required this.label,
    required this.height,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final String label;
  final double height;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Semantics(
      key: Key('segment-$index'),
      container: true,
      excludeSemantics: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      label: label,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          key: Key('segment-pill-$index'),
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? palette.sheet : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.segmentedPill),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.segmentedLabel.copyWith(
              color: selected ? palette.primaryText : palette.segmentedInactive,
              fontWeight: selected
                  ? AppTypography.medium
                  : AppTypography.regular,
            ),
          ),
        ),
      ),
    );
  }
}
