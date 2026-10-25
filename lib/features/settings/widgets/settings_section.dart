import 'package:flutter/material.dart';

import '../../../theme/app_tokens.dart';

/// A titled white card from the Settings design (screen 05).
///
/// The title sits 4 px in, 8 px above a white 20 px-radius card with 6/16
/// padding; rows are separated by 1 px dividers.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.settingsTitleInset,
          ),
          child: Text(
            title,
            style: AppTypography.sectionLabel.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.settingsTitleGap),
        Container(
          key: const Key('settings-card'),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.settingsCardPaddingH,
            vertical: AppSizes.settingsCardPaddingV,
          ),
          decoration: BoxDecoration(
            color: AppColors.sheet,
            borderRadius: BorderRadius.circular(AppRadii.cardLarge),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int index = 0; index < children.length; index++) ...<Widget>[
                children[index],
                if (index < children.length - 1)
                  Container(
                    height: AppSizes.borderWidth,
                    color: AppColors.divider,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
