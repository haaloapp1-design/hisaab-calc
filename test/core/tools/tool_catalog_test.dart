import 'package:calculator/core/tools/tool_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lists the ten screen 09 tools in grid order', () {
    expect(ToolCatalog.tools.map((Tool tool) => tool.id), <String>[
      'loan',
      'percentage',
      'discount',
      'tip',
      'age',
      'date-diff',
      'bmi',
      'gpa',
      'equation',
      'statistics',
    ]);
    expect(ToolCatalog.tools.length, 10);
  });

  test(
    'every tool has a unique id and the design symbol, name and subtitle',
    () {
      final Set<String> ids = <String>{};
      for (final Tool tool in ToolCatalog.tools) {
        expect(tool.id, isNotEmpty);
        expect(ids.add(tool.id), isTrue, reason: tool.id);
        expect(tool.symbol, isNotEmpty, reason: tool.id);
        expect(tool.name, isNotEmpty, reason: tool.id);
        expect(tool.subtitle, isNotEmpty, reason: tool.id);
      }

      expect(ToolCatalog.byId('loan')!.symbol, 'EMI');
      expect(ToolCatalog.byId('loan')!.name, 'Loan / EMI');
      expect(ToolCatalog.byId('loan')!.subtitle, 'Monthly instalment');
      expect(ToolCatalog.byId('discount')!.symbol, '−%');
      expect(ToolCatalog.byId('tip')!.symbol, '÷n');
      expect(ToolCatalog.byId('date-diff')!.symbol, 'Δd');
      expect(ToolCatalog.byId('equation')!.symbol, 'ax²');
      expect(ToolCatalog.byId('statistics')!.symbol, 'Σ');
      expect(ToolCatalog.byId('gpa')!.name, 'GPA / grades');
    },
  );

  test('byId returns the catalog entry and null for an unknown id', () {
    expect(ToolCatalog.byId('bmi'), same(ToolCatalog.tools[6]));
    expect(ToolCatalog.byId('BMI'), isNull);
    expect(ToolCatalog.byId(''), isNull);
    expect(ToolCatalog.contains('age'), isTrue);
    expect(ToolCatalog.contains('nope'), isFalse);
  });
}
