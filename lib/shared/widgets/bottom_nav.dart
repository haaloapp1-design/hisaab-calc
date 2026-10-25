import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import '../../theme/app_tokens.dart';

/// The four destinations of the app's bottom navigation (DESIGN "BottomNav").
enum NavDestination {
  calculator('Calculator', Icons.calculate_outlined),
  convert('Convert', Icons.swap_horiz_rounded),
  tools('Tools', Icons.grid_view_rounded),
  history('History', Icons.schedule_rounded);

  const NavDestination(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// The active-pill bottom navigation shared by the four tabs.
///
/// It renders only the bar; the shell supplies the white surface and the
/// device's bottom safe area. Sizes come from `docs/screens/01-basic.html`.
class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Container(
      key: const Key('bottom-nav'),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: palette.navDivider,
            width: AppSizes.borderWidth,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.navPaddingTop,
        AppSizes.screenPadding,
        AppSizes.navPaddingBottom,
      ),
      child: Row(
        children: <Widget>[
          for (int index = 0; index < NavDestination.values.length; index++) ...<
            Widget
          >[
            if (index > 0) const SizedBox(width: AppSizes.navGap),
            Expanded(
              child: _NavItem(
                destination: NavDestination.values[index],
                selected: index == currentIndex,
                onTap: () => onSelected(index),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Color color = selected ? palette.primary : palette.inkMuted;

    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      child: Material(
        color: selected ? palette.keyOperator : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.navItem),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSizes.navItemPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(destination.icon, size: AppSizes.navIcon, color: color),
                const SizedBox(height: AppSizes.navItemGap),
                Text(
                  destination.label,
                  style: AppTypography.navLabel.copyWith(
                    color: color,
                    fontWeight: selected
                        ? AppTypography.medium
                        : AppTypography.regular,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
