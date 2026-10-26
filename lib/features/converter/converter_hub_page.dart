import 'package:flutter/material.dart';

import '../../core/units/unit_catalog.dart';
import '../../shared/widgets/blue_header.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_tokens.dart';
import 'widgets/category_grid.dart';
import 'widgets/currency_card.dart';
import 'widgets/hub_search_field.dart';
import 'widgets/unit_search_results.dart';

/// The Convert tab: currency card, twelve category tiles and unit search
/// (SPEC §4, screen `06-converter-hub.html`).
///
/// It owns only the search text; picking a category, a unit or currency is
/// forwarded to the callbacks, which T37/T39 wire to the next pages.
class ConverterHubPage extends StatefulWidget {
  const ConverterHubPage({
    super.key,
    this.onCategorySelected,
    this.onUnitSelected,
    this.onCurrencyTap,
  });

  /// Opens the unit converter for [UnitCategory] (T37).
  final ValueChanged<UnitCategory>? onCategorySelected;

  /// Opens the unit converter on the found [UnitMatch] (T37).
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
                        onSelected: widget.onUnitSelected,
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
          CategoryGrid(onSelected: widget.onCategorySelected),
        ],
      ),
    );
  }
}
