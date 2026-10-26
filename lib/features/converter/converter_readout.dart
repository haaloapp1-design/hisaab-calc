import '../../core/engine/formatter.dart';
import '../../core/units/converter.dart';
import '../../core/units/unit.dart';
import 'converter_input.dart';

/// One row of the "is also" list: a unit and the same amount in it.
final class AlsoRow {
  const AlsoRow(this.unit, this.value);

  final Unit unit;
  final String value;
}

/// Everything screen 07 shows for the current pair and typed amount.
///
/// The page builds one readout per frame, so the To card, the rule line and
/// the "is also" rows always come from the same conversion and formatting
/// rules instead of the widget doing maths.
final class ConverterReadout {
  const ConverterReadout({
    required this.category,
    required this.from,
    required this.to,
    required this.input,
    required this.options,
  });

  final UnitCategory category;
  final Unit from;
  final Unit to;
  final ConverterInput input;
  final NumberFormatOptions options;

  /// The From amount as typed, grouped and with the typographic minus.
  String get fromText => input.display(options: options);

  /// The converted amount, or the conversion error message.
  String get toText => switch (result) {
    ConversionSuccess(:final value) => formatConversionValue(
      value,
      options: options,
    ),
    ConversionFailure(:final error) => error.message,
  };

  /// True when the To card shows [ConversionError] text.
  bool get isError => result is ConversionFailure;

  /// `1 km = 0.621371 mi` for the current pair.
  String get rule => UnitConverter.ruleLine(
    category: category,
    from: from,
    to: to,
    options: options,
  );

  /// `5 km is also` above the other units.
  String get heading => '$fromText ${from.symbol} is also';

  /// The four "is also" rows, with `—` when the amount is impossible there.
  List<AlsoRow> get also => <AlsoRow>[
    for (final Unit unit in UnitConverter.isAlso(
      category: category,
      from: from,
      to: to,
    ))
      AlsoRow(unit, valueIn(unit)),
  ];

  /// The current amount in [unit], or `—` for a conversion error.
  String valueIn(Unit unit) => switch (UnitConverter.convert(
    input.value,
    category: category,
    from: from,
    to: unit,
  )) {
    ConversionSuccess(:final value) => formatConversionValue(
      value,
      options: options,
    ),
    ConversionFailure() => '—',
  };

  /// The raw result, or the failure, behind [toText].
  ConversionResult get result => UnitConverter.convert(
    input.value,
    category: category,
    from: from,
    to: to,
  );
}
