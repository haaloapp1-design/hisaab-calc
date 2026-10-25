import '../../core/engine/formatter.dart';
import 'settings_model.dart';

/// The number format every screen uses for the current [Settings].
///
/// The calculator display and the history entries it saves must share these
/// options (SPEC §3: the decimal separator follows the device locale, the
/// separators and decimal count come from Settings), so both call this instead
/// of building their own copy.
NumberFormatOptions numberFormatFor(Settings settings) =>
    NumberFormatOptions.localized(
      decimalPlaces: settings.decimalPlaces,
      useGrouping: settings.thousandsSeparator,
    );
