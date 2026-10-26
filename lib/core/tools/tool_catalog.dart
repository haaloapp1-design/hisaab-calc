/// One ready-made calculator on the Tools tab (SPEC §6).
///
/// The catalog is pure data: the hub renders the tiles from it and each tool
/// page looks itself up by [id], so the tile and the page title can never
/// disagree.
final class Tool {
  const Tool({
    required this.id,
    required this.symbol,
    required this.name,
    required this.subtitle,
  });

  /// Stable identifier used for routes, keys and tests, e.g. `loan`.
  final String id;

  /// The glyph in the tile's chip, e.g. `EMI`, `%`, `Σ`.
  final String symbol;

  /// The tool name shown on the tile and in the page header.
  final String name;

  /// The one-line explanation under the name on the tile.
  final String subtitle;

  @override
  String toString() => 'Tool($id)';
}

/// The ten tools of screen 09, in the order the grid shows them.
abstract final class ToolCatalog {
  static const List<Tool> tools = <Tool>[
    Tool(
      id: 'loan',
      symbol: 'EMI',
      name: 'Loan / EMI',
      subtitle: 'Monthly instalment',
    ),
    Tool(
      id: 'percentage',
      symbol: '%',
      name: 'Percentage',
      subtitle: 'Of, change, ratio',
    ),
    Tool(
      id: 'discount',
      symbol: '−%',
      name: 'Discount and tax',
      subtitle: 'Sale price, GST',
    ),
    Tool(
      id: 'tip',
      symbol: '÷n',
      name: 'Tip and split',
      subtitle: 'Share a bill',
    ),
    Tool(id: 'age', symbol: 'yrs', name: 'Age', subtitle: 'Exact age in days'),
    Tool(
      id: 'date-diff',
      symbol: 'Δd',
      name: 'Date difference',
      subtitle: 'Days between dates',
    ),
    Tool(id: 'bmi', symbol: 'BMI', name: 'BMI', subtitle: 'Body mass index'),
    Tool(
      id: 'gpa',
      symbol: 'GPA',
      name: 'GPA / grades',
      subtitle: 'Weighted average',
    ),
    Tool(
      id: 'equation',
      symbol: 'ax²',
      name: 'Equation solver',
      subtitle: 'Linear, quadratic',
    ),
    Tool(
      id: 'statistics',
      symbol: 'Σ',
      name: 'Statistics',
      subtitle: 'Mean, median, SD',
    ),
  ];

  /// The tool with [id], or null when the id is unknown.
  static Tool? byId(String id) {
    for (final Tool tool in tools) {
      if (tool.id == id) {
        return tool;
      }
    }
    return null;
  }

  /// True when [id] names a catalog tool.
  static bool contains(String id) => byId(id) != null;
}
