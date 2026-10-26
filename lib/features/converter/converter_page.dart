import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/units/converter.dart';
import '../../core/units/converter_memory.dart';
import '../../core/units/unit_catalog.dart';
import '../../shared/widgets/blue_header.dart';
import '../../theme/app_palette.dart';
import '../history/history_controller.dart';
import '../history/history_entry.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_format.dart';
import '../settings/settings_model.dart';
import 'converter_defaults.dart';
import 'converter_input.dart';
import 'converter_key.dart';
import 'converter_memory_controller.dart';
import 'converter_readout.dart';
import 'widgets/also_list.dart';
import 'widgets/converter_cards.dart';
import 'widgets/converter_keypad.dart';
import 'widgets/unit_picker_sheet.dart';

/// The unit converter for one category (SPEC §4, screen `07-unit-converter`).
///
/// The typed amount lives in [ConverterInput]; every change converts through
/// [UnitConverter], so the To card, the rule line and the "is also" rows are
/// always in sync. The star and the last pair are stored through
/// [ConverterMemoryController] (T38).
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

  /// Overrides the star action (tests); otherwise the pair is starred.
  final VoidCallback? onFavourite;

  @override
  ConsumerState<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends ConsumerState<ConverterPage> {
  late Unit _from;
  late Unit _to;
  ConverterInput _input = const ConverterInput();

  /// True once the user picked, swapped or typed, so the stored pair no longer
  /// replaces what is on screen.
  bool _touched = false;

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
    _restorePair();
  }

  ConverterPair get _pair =>
      ConverterPair(category: widget.category, from: _from, to: _to);

  ConverterReadout get _readout => ConverterReadout(
    category: widget.category,
    from: _from,
    to: _to,
    input: _input,
    options: numberFormatFor(ref.read(settingsProvider)),
  );

  /// Adopts the remembered pair for this category, then remembers the pair
  /// actually shown. An explicit pair or a user change wins over it.
  Future<void> _restorePair() async {
    final ConverterMemoryController memory = ref.read(
      converterMemoryProvider.notifier,
    );
    await memory.restoreDone;
    if (!mounted) {
      return;
    }
    final bool explicit = widget.from != null || widget.to != null;
    final ConverterPair? last = ref.read(converterMemoryProvider).last;
    if (!explicit &&
        !_touched &&
        last != null &&
        last.category == widget.category) {
      setState(() {
        _from = last.from;
        _to = last.to;
      });
    }
    memory.remember(_pair);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Settings settings = ref.watch(settingsProvider);
    final ConverterReadout readout = _readout;
    final bool favourite = ref
        .watch(converterMemoryProvider)
        .isFavourite(_pair);

    return Scaffold(
      backgroundColor: palette.primary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            BlueHeader(
              title: widget.category.label,
              onBack: () => Navigator.of(context).maybePop(),
              actionIcon: favourite
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              actionTooltip: favourite
                  ? 'Remove from favourites'
                  : 'Add to favourites',
              onAction: _toggleFavourite,
            ),
            ConverterCards(
              from: _from,
              to: _to,
              fromText: readout.fromText,
              toText: readout.toText,
              toIsError: readout.isError,
              rule: readout.rule,
              onPickFrom: _pickFrom,
              onPickTo: _pickTo,
              onSwap: _swap,
            ),
            Expanded(
              child: AlsoList(heading: readout.heading, rows: readout.also),
            ),
            ConverterKeypad(
              onKey: _onKey,
              onLongPress: _onKeyLongPress,
              haptics: settings.haptics,
              sounds: settings.keySounds,
            ),
          ],
        ),
      ),
    );
  }

  void _onKey(ConverterKey key) {
    if (key == ConverterKey.copy) {
      _copy();
      return;
    }
    setState(() => _input = _input.apply(key));
  }

  void _onKeyLongPress(ConverterKey key) {
    if (key == ConverterKey.copy) {
      _saveToHistory();
    }
  }

  void _toggleFavourite() {
    final VoidCallback? callback = widget.onFavourite;
    if (callback != null) {
      callback();
      return;
    }
    final bool now = ref
        .read(converterMemoryProvider.notifier)
        .toggleFavourite(_pair);
    _toast(now ? 'Added to favourites' : 'Removed from favourites');
  }

  Future<void> _copy() async {
    final ConverterReadout readout = _readout;
    if (readout.result is! ConversionSuccess) {
      return;
    }
    await Clipboard.setData(
      ClipboardData(text: readout.toText.replaceAll('−', '-')),
    );
    if (!mounted) {
      return;
    }
    _toast('Copied');
  }

  /// SPEC §2/§10: a converter result can be saved to history. Long-pressing
  /// Copy keeps screen 07's keypad unchanged.
  void _saveToHistory() {
    final ConverterReadout readout = _readout;
    if (readout.result is! ConversionSuccess) {
      return;
    }
    final HistoryEntry? entry = ref
        .read(historyProvider.notifier)
        .add(
          expression: '${readout.fromText} ${_from.symbol} → ${_to.symbol}',
          result: readout.toText,
          mode: HistoryMode.converter,
        );
    _toast(entry == null ? 'Already in history' : 'Saved to history');
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
    _applyPair(unit, _to.id == unit.id ? _from : _to);
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
    _applyPair(_from.id == unit.id ? _to : _from, unit);
  }

  void _swap() => _applyPair(_to, _from);

  void _applyPair(Unit from, Unit to) {
    setState(() {
      _from = from;
      _to = to;
      _touched = true;
    });
    ref.read(converterMemoryProvider.notifier).remember(_pair);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
