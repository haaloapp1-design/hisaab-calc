import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/engine/formatter.dart';
import '../../core/units/converter.dart';
import '../../core/units/unit_catalog.dart';
import '../../shared/widgets/blue_header.dart';
import '../../theme/app_palette.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_format.dart';
import '../settings/settings_model.dart';
import 'converter_defaults.dart';
import 'converter_input.dart';
import 'converter_key.dart';
import 'widgets/also_list.dart';
import 'widgets/converter_cards.dart';
import 'widgets/converter_keypad.dart';
import 'widgets/unit_picker_sheet.dart';

/// The unit converter for one category (SPEC §4, screen `07-unit-converter`).
///
/// The typed amount lives in [ConverterInput]; every change converts through
/// [UnitConverter], so the To card, the rule line and the "is also" rows are
/// always in sync. T38 adds the favourite star and the remembered pair.
class ConverterPage extends ConsumerStatefulWidget {
  const ConverterPage({
    super.key,
    required this.category,
    this.from,
    this.to,
    this.onFavourite,
  });

  final UnitCategory category;

  /// The From unit, e.g. one opened from the hub search.
  final Unit? from;

  /// The To unit; [defaultUnits] fills it when omitted.
  final Unit? to;

  /// T38's favourite action; the star is shown either way (screen 07).
  final VoidCallback? onFavourite;

  @override
  ConsumerState<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends ConsumerState<ConverterPage> {
  late Unit _from;
  late Unit _to;
  ConverterInput _input = const ConverterInput();

  @override
  void initState() {
    super.initState();
    final ({Unit from, Unit to}) pair = defaultUnits(
      widget.category,
      from: widget.from,
      to: widget.to,
    );
    _from = pair.from;
    _to = pair.to;
  }

  NumberFormatOptions get _options =>
      numberFormatFor(ref.read(settingsProvider));

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Settings settings = ref.watch(settingsProvider);
    final NumberFormatOptions options = numberFormatFor(settings);
    final ConversionResult result = UnitConverter.convert(
      _input.value,
      category: widget.category,
      from: _from,
      to: _to,
    );
    final String toText = switch (result) {
      ConversionSuccess(:final Decimal value) => formatConversionValue(
        value,
        options: options,
      ),
      ConversionFailure(:final ConversionError error) => error.message,
    };
    final String fromText = _input.display(options: options);
    final List<AlsoRow> also = <AlsoRow>[
      for (final Unit unit in UnitConverter.isAlso(
        category: widget.category,
        from: _from,
        to: _to,
      ))
        AlsoRow(unit, _valueIn(unit, _input.value, options)),
    ];

    return Scaffold(
      backgroundColor: palette.primary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            BlueHeader(
              title: widget.category.label,
              onBack: () => Navigator.of(context).maybePop(),
              actionIcon: Icons.star_border_rounded,
              actionTooltip: 'Add to favourites',
              onAction: widget.onFavourite ?? () {},
            ),
            ConverterCards(
              from: _from,
              to: _to,
              fromText: fromText,
              toText: toText,
              toIsError: result is ConversionFailure,
              rule: UnitConverter.ruleLine(
                category: widget.category,
                from: _from,
                to: _to,
                options: options,
              ),
              onPickFrom: _pickFrom,
              onPickTo: _pickTo,
              onSwap: _swap,
            ),
            Expanded(
              child: AlsoList(
                heading: '$fromText ${_from.symbol} is also',
                rows: also,
              ),
            ),
            ConverterKeypad(
              onKey: _onKey,
              haptics: settings.haptics,
              sounds: settings.keySounds,
            ),
          ],
        ),
      ),
    );
  }

  String _valueIn(Unit unit, Decimal value, NumberFormatOptions options) {
    final ConversionResult result = UnitConverter.convert(
      value,
      category: widget.category,
      from: _from,
      to: unit,
    );
    return switch (result) {
      ConversionSuccess(:final Decimal value) => formatConversionValue(
        value,
        options: options,
      ),
      ConversionFailure() => '—',
    };
  }

  void _onKey(ConverterKey key) {
    if (key == ConverterKey.copy) {
      _copy();
      return;
    }
    setState(() {
      _input = switch (key) {
        ConverterKey.zero => _input.digit('0'),
        ConverterKey.one => _input.digit('1'),
        ConverterKey.two => _input.digit('2'),
        ConverterKey.three => _input.digit('3'),
        ConverterKey.four => _input.digit('4'),
        ConverterKey.five => _input.digit('5'),
        ConverterKey.six => _input.digit('6'),
        ConverterKey.seven => _input.digit('7'),
        ConverterKey.eight => _input.digit('8'),
        ConverterKey.nine => _input.digit('9'),
        ConverterKey.doubleZero => _input.doubleZero(),
        ConverterKey.dot => _input.dot(),
        ConverterKey.toggleSign => _input.toggleSign(),
        ConverterKey.backspace => _input.backspace(),
        ConverterKey.clear => _input.clear(),
        ConverterKey.copy => _input,
      };
    });
  }

  Future<void> _copy() async {
    final ConversionResult result = UnitConverter.convert(
      _input.value,
      category: widget.category,
      from: _from,
      to: _to,
    );
    if (result is! ConversionSuccess) {
      return;
    }
    final String text = formatConversionValue(
      result.value,
      options: _options,
    ).replaceAll('−', '-');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Copied')));
  }

  Future<void> _pickFrom() async {
    final Unit? unit = await showUnitPickerSheet(
      context,
      category: widget.category,
      selected: _from,
      title: 'From unit',
    );
    if (unit == null || !mounted) {
      return;
    }
    final Unit previousFrom = _from;
    setState(() {
      _from = unit;
      if (_to.id == unit.id) {
        _to = previousFrom;
      }
    });
  }

  Future<void> _pickTo() async {
    final Unit? unit = await showUnitPickerSheet(
      context,
      category: widget.category,
      selected: _to,
      title: 'To unit',
    );
    if (unit == null || !mounted) {
      return;
    }
    final Unit previousTo = _to;
    setState(() {
      _to = unit;
      if (_from.id == unit.id) {
        _from = previousTo;
      }
    });
  }

  void _swap() {
    setState(() {
      final Unit from = _from;
      _from = _to;
      _to = from;
    });
  }
}
