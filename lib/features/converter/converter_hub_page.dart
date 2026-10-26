import 'package:flutter/material.dart';

import '../../core/units/unit_catalog.dart';
import '../../shared/widgets/blue_header.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_tokens.dart';
import 'converter_page.dart';
import 'widgets/category_grid.dart';
import 'widgets/currency_card.dart';
import 'widgets/hub_search_field.dart';
import 'widgets/unit_search_results.dart';

/// The Convert tab: currency card, twelve category tiles and unit search
/// (SPEC §4, screen `06-converter-hub.html`).
///
/// It owns only the search text. A category or a search result opens the unit
/// converter (T37) unless the caller supplies its own callback; the currency
/// card stays a callback for T39.
class ConverterHubPage extends StatefulWidget {
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
  State<ConverterHubPage> createState() => _ConverterHubPageState();
}

class _ConverterHubPageState extends State<ConverterHubPage> {
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.hubContentPaddingTop,
        AppSizes.screenPadding,
        AppSizes.hubContentPaddingTop,
      ),
      child: Column(
        children: <Widget>[
          CurrencyCard(onTap: widget.onCurrencyTap),
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

  void _openConverter(UnitCategory category, {Unit? from}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            ConverterPage(category: category, from: from),
      ),
    );
  }
}
