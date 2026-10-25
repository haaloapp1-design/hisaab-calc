import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import 'settings_model.dart';

/// Maps the stored [AccentSwatch] to the colour that replaces `primary`
/// (DESIGN "Accent swatches").
extension AccentSwatchColor on AccentSwatch {
  Color get color => switch (this) {
    AccentSwatch.cobalt => AppColors.primary,
    AccentSwatch.teal => AppColors.accentTeal,
    AccentSwatch.violet => AppColors.accentViolet,
    AccentSwatch.rust => AppColors.accentRust,
  };
}
