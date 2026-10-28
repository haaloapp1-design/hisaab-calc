import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/currency/currency_catalog.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_tokens.dart';

/// Opens the searchable currency list and returns the picked code.
///
/// [excluded] keeps the base and currencies already on the list out of the
/// picker; the currently selected code is still shown with its check mark.
Future<String?> showCurrencyPickerSheet(
  BuildContext context, {
  required String title,
  required String selected,
  Set<String> excluded = const <String>{},
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) => _CurrencyPickerSheet(
      title: title,
      selected: selected,
      excluded: excluded,
    ),
  );
}

class _CurrencyPickerSheet extends StatefulWidget {
  const _CurrencyPickerSheet({
    required this.title,
    required this.selected,
    required this.excluded,
  });

  final String title;
  final String selected;
  final Set<String> excluded;

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  final TextEditingController _search = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _search.addListener(_onChanged);
    // Open on the current currency instead of the top of a long list.
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
  }

  @override
  void dispose() {
    _search
      ..removeListener(_onChanged)
      ..dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  /// The catalog rows the sheet lists for [query].
  List<Currency> _visible(String query) => CurrencyCatalog.search(query)
      .where(
        (Currency currency) =>
            currency.code == widget.selected ||
            !widget.excluded.contains(currency.code),
      )
      .toList(growable: false);

  void _revealSelected() {
    if (!mounted || !_scroll.hasClients) {
      return;
    }
    final int index = _visible('')
        .indexWhere((Currency currency) => currency.code == widget.selected);
    if (index <= 0) {
      return;
    }
    _scroll.jumpTo(
      math.min(
        index * AppSizes.currencyPickerRowHeight,
        _scroll.position.maxScrollExtent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final List<Currency> currencies = _visible(_search.text);

    final double screen = MediaQuery.sizeOf(context).height;
    final double height = math.min(
      screen * AppSizes.currencyPickerMaxHeight,
      screen - MediaQuery.viewInsetsOf(context).bottom - AppSizes.screenPadding,
    );

    // The picker owns its surface instead of using [WhiteSheet]: the list has
    // to scroll inside a fixed height, and WhiteSheet's shrink-wrapping column
    // gives its child an unbounded height.
    return SizedBox(
      height: height,
      child: Container(
        key: const Key('currency-picker-sheet'),
        width: double.infinity,
        decoration: BoxDecoration(
          color: palette.sheet,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          AppSizes.screenPadding,
          AppSizes.sheetPaddingTop,
          AppSizes.screenPadding,
          AppSizes.converterSheetPaddingBottom +
              MediaQuery.paddingOf(context).bottom +
              MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                key: const Key('currency-picker-handle'),
                width: AppSizes.handleWidth,
                height: AppSizes.handleHeight,
                decoration: BoxDecoration(
                  color: palette.primary,
                  borderRadius: BorderRadius.circular(AppRadii.handle),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.sheetContentGap),
            Text(
              widget.title,
              key: const Key('currency-picker-title'),
              style: AppTypography.hubItemTitle.copyWith(color: palette.ink),
            ),
            const SizedBox(height: AppSizes.currencyPickerTitleGap),
            SizedBox(
              height: AppSizes.currencyPickerSearchHeight,
              child: TextField(
                key: const Key('currency-picker-search'),
                controller: _search,
                textInputAction: TextInputAction.search,
                style: AppTypography.body.copyWith(color: palette.ink),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search currencies',
                  hintStyle: AppTypography.body.copyWith(
                    color: palette.inkMuted,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: AppSizes.searchIcon,
                    color: palette.inkMuted,
                  ),
                  filled: true,
                  fillColor: palette.keyNumberScientific,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.historySearchPaddingH,
                    vertical: AppSizes.currencyPickerTitleGap,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppSizes.historySearchRadius,
                    ),
                    borderSide: BorderSide(
                      color: palette.keyNumberBorder,
                      width: AppSizes.borderWidth,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppSizes.historySearchRadius,
                    ),
                    borderSide: BorderSide(
                      color: palette.keyNumberBorder,
                      width: AppSizes.borderWidth,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.currencyPickerTitleGap),
            Expanded(
              child: currencies.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSizes.currencyPickerTitleGap,
                      ),
                      child: Text(
                        'No currencies found',
                        key: const Key('currency-picker-empty'),
                        textAlign: TextAlign.center,
                        style: AppTypography.body.copyWith(
                          color: palette.inkMuted,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      itemCount: currencies.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Currency currency = currencies[index];
                        return _CurrencyPickerRow(
                          currency: currency,
                          selected: currency.code == widget.selected,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyPickerRow extends StatelessWidget {
  const _CurrencyPickerRow({required this.currency, required this.selected});

  final Currency currency;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: '${currency.code}, ${currency.name}',
      onTap: () => Navigator.of(context).pop(currency.code),
      excludeSemantics: true,
      child: SizedBox(
        height: AppSizes.currencyPickerRowHeight,
        child: InkWell(
          key: Key('currency-pick-${currency.code}'),
          onTap: () => Navigator.of(context).pop(currency.code),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: palette.divider,
                  width: AppSizes.borderWidth,
                ),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: AppSizes.currencyPickerChipWidth,
                  height: AppSizes.currencyPickerChipHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.keyOperator,
                    borderRadius: BorderRadius.circular(
                      AppSizes.currencyCodeRadius,
                    ),
                  ),
                  child: Text(
                    currency.code,
                    style: AppTypography.currencyCode.copyWith(
                      color: palette.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.currencyRowGap),
                Expanded(
                  child: Text(
                    currency.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      color: selected ? palette.primary : palette.ink,
                      fontWeight: selected
                          ? AppTypography.medium
                          : AppTypography.regular,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_rounded,
                    size: AppSizes.currencyPickerCheck,
                    color: palette.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
