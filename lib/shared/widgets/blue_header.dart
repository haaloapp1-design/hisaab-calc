import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// The blue top area of every screen (DESIGN "Components").
///
/// Two variants:
/// * standard — a centred 17 px title between a 44 px back slot and a 44 px
///   action slot (`01-basic.html`, `04-history-memory.html`).
/// * `large` — a left-aligned 26 px title with an optional subtitle and no
///   back/action slots, used by the hub screens (`06-converter-hub.html`,
///   `09-tools-hub.html`).
///
/// The header is only the blue block: the background of the page behind it
/// stays the caller's responsibility.
class BlueHeader extends StatelessWidget {
  const BlueHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.backTooltip = 'Back',
    this.actionIcon,
    this.onAction,
    this.actionTooltip,
    this.large = false,
    this.rounded = false,
  }) : assert(
         (actionIcon == null) == (onAction == null),
         'actionIcon and onAction must be given together',
       ),
       assert(
         actionTooltip == null || actionIcon != null,
         'actionTooltip needs an actionIcon',
       ),
       assert(
         subtitle == null || large,
         'a subtitle is only part of the large header',
       );

  /// The screen name.
  final String title;

  /// The one-line explanation under a large title (hub screens only).
  final String? subtitle;

  /// Shows a back button in the leading slot when set.
  final VoidCallback? onBack;

  /// Accessibility label of the back button.
  final String backTooltip;

  /// The trailing action icon, for example settings, search or share.
  final IconData? actionIcon;

  /// Called when the trailing action is tapped.
  final VoidCallback? onAction;

  /// Accessibility label of the trailing action.
  final String? actionTooltip;

  /// Hub variant: 26 px left-aligned title, optional subtitle, taller
  /// padding and no side slots.
  final bool large;

  /// Rounds the bottom corners over the page background (Settings, hubs).
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('blue-header'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: rounded
            ? const BorderRadius.vertical(
                bottom: Radius.circular(AppRadii.header),
              )
            : null,
      ),
      padding: large
          ? const EdgeInsets.fromLTRB(
              AppSizes.screenPadding,
              AppSizes.hubHeaderPaddingTop,
              AppSizes.screenPadding,
              AppSizes.hubHeaderPaddingBottom,
            )
          : const EdgeInsets.fromLTRB(
              AppSizes.screenPadding,
              AppSizes.headerPaddingTop,
              AppSizes.screenPadding,
              0,
            ),
      child: large ? _buildLarge() : _buildStandard(),
    );
  }

  Widget _buildLarge() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.hubTitle.copyWith(color: AppColors.onPrimary),
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: AppSizes.headerSubtitleGap),
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.hubSubtitle.copyWith(
              color: AppColors.onPrimaryMuted,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStandard() {
    return Row(
      children: <Widget>[
        if (onBack == null)
          const _HeaderSlot()
        else
          _HeaderAction(
            key: const Key('blue-header-back'),
            icon: Icons.chevron_left,
            tooltip: backTooltip,
            onTap: onBack!,
          ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.screenTitle.copyWith(
              color: AppColors.onPrimary,
            ),
          ),
        ),
        if (actionIcon == null)
          const _HeaderSlot()
        else
          _HeaderAction(
            key: const Key('blue-header-action'),
            icon: actionIcon!,
            tooltip: actionTooltip,
            onTap: onAction!,
          ),
      ],
    );
  }
}

/// The invisible 44 px slot that keeps the standard title centred.
class _HeaderSlot extends StatelessWidget {
  const _HeaderSlot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: AppSizes.minTapTarget,
      height: AppSizes.minTapTarget,
    );
  }
}

/// A 44 px icon button sitting in a header slot.
class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String? tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizes.minTapTarget,
      height: AppSizes.minTapTarget,
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        iconSize: AppSizes.headerIcon,
        color: AppColors.onPrimary,
        icon: Icon(icon),
      ),
    );
  }
}
