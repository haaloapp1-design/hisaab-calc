import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/units/converter_memory.dart';
import '../../core/units/unit_catalog.dart';
import '../../shared/widgets/blue_header.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_tokens.dart';
import '../currency/currency_page.dart';
import 'converter_memory_controller.dart';
import 'converter_page.dart';
import 'widgets/category_grid.dart';
import 'widgets/currency_card.dart';
import 'widgets/favourites_card.dart';
import 'widgets/hub_search_field.dart';
import 'widgets/unit_search_results.dart';

/// The Convert tab: favourites, currency card, twelve category tiles and unit
/// search (SPEC §4, screen `06-converter-hub.html`).
///
/// It owns only the search text. A category or a search result opens the unit
/// converter unless the caller supplies its own callback; a favourite pair
/// opens it with both sides; the currency card opens [CurrencyPage] unless a
/// callback overrides it.
class ConverterHubPage extends ConsumerStatefulWidget {
  const ConverterHubPage({
    super.key,
    this.onCategorySelected,
    this.onUnitSelected,
    this.onCurrencyTap,
  });

  /// Overrides the default push of [ConverterPage] for a category.
  final ValueChanged<UnitCategory>? onCategorySelected;

  /// Overrides the default push of [ConverterPage] for a search result.
  final ValueChanged<UnitMatch>? onUnitSelected;

  /// Opens the currency converter (T39).
  final VoidCallback? onCurrencyTap;

  @override
  ConsumerState<ConverterHubPage> createState() => _ConverterHubPageState();
}

class _ConverterHubPageState extends ConsumerState<ConverterHubPage> {
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _search
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final String query = _search.text.trim();
    final List<UnitMatch> matches = UnitCatalog.search(query);

    return ColoredBox(
      color: palette.primary,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            BlueHeader(
              title: 'Convert',
              large: true,
              rounded: true,
              child: HubSearchField(controller: _search),
            ),
            Expanded(
              child: ColoredBox(
                color: palette.background,
                child: query.isEmpty
                    ? _buildHub(context)
                    : UnitSearchResults(
                        matches: matches,
                        onSelected: _selectUnit,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHub(BuildContext context) {
    final List<ConverterPair> favourites = ref
        .watch(converterMemoryProvider)
        .favourites;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.hubContentPaddingTop,
        AppSizes.screenPadding,
        AppSizes.hubContentPaddingTop,
      ),
      child: Column(
        children: <Widget>[
          if (favourites.isNotEmpty) ...<Widget>[
            FavouritesCard(favourites: favourites, onSelected: _openPair),
            const SizedBox(height: AppSizes.hubContentGap),
          ],
          CurrencyCard(onTap: _openCurrency),
          const SizedBox(height: AppSizes.hubContentGap),
          CategoryGrid(onSelected: _selectCategory),
        ],
      ),
    );
  }

  void _selectCategory(UnitCategory category) {
    final ValueChanged<UnitCategory>? callback = widget.onCategorySelected;
    if (callback != null) {
      callback(category);
      return;
    }
    _openConverter(category);
  }

  void _selectUnit(UnitMatch match) {
    final ValueChanged<UnitMatch>? callback = widget.onUnitSelected;
    if (callback != null) {
      callback(match);
      return;
    }
    _openConverter(match.category, from: match.unit);
  }

  void _openPair(ConverterPair pair) {
    _openConverter(pair.category, from: pair.from, to: pair.to);
  }

  void _openConverter(UnitCategory category, {Unit? from, Unit? to}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            ConverterPage(category: category, from: from, to: to),
      ),
    );
  }

  void _openCurrency() {
    final VoidCallback? callback = widget.onCurrencyTap;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const CurrencyPage(),
      ),
    );
  }
}
