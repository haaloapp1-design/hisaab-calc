import 'package:flutter/material.dart';

import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// The white search field inside the converter hub header (screen 06).
///
/// It only renders the field; [ConverterHubPage] owns the controller and
/// rebuilds the body from its text.
class HubSearchField extends StatelessWidget {
  const HubSearchField({super.key, required this.controller});

  /// Placeholder from `06-converter-hub.html`.
  static const String hint = 'Search units, e.g. inch or psi';

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return SizedBox(
      key: const Key('hub-search-box'),
      width: double.infinity,
      height: AppSizes.hubSearchHeight,
      child: Material(
        color: palette.sheet,
        borderRadius: BorderRadius.circular(AppSizes.hubSearchRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.hubSearchPaddingH,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.search_rounded,
                size: AppSizes.hubSearchIcon,
                color: palette.inkMuted,
              ),
              const SizedBox(width: AppSizes.hubSearchGap),
              Expanded(
                child: TextField(
                  key: const Key('hub-search-field'),
                  controller: controller,
                  style: AppTypography.body.copyWith(color: palette.ink),
                  cursorColor: palette.primary,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: hint,
                    hintStyle: AppTypography.body.copyWith(
                      color: palette.inkMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
