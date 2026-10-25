import 'package:calculator/shared/widgets/segmented.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:calculator/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const List<String> modes = <String>[
    'Basic',
    'Scientific',
    'Programmer',
  ];

  Widget wrap(Segmented segmented) =>
      MaterialApp(theme: AppTheme.light(), home: Scaffold(body: segmented));

  Container track(WidgetTester tester) =>
      tester.widget<Container>(find.byKey(const Key('segmented')));

  Container pill(WidgetTester tester, int index) => tester.widget<Container>(
    find.byKey(Key('segment-pill-$index')),
  );

  testWidgets('lays out the labels on the 44 px design track', (tester) async {
    await tester.pumpWidget(
      wrap(
        const Segmented(
          labels: modes,
          selectedIndex: 0,
          onSelected: _ignore,
        ),
      ),
    );

    for (final String label in modes) {
      expect(find.text(label), findsOneWidget);
    }

    final Container box = track(tester);
    expect(
      tester.getSize(find.byKey(const Key('segmented'))).height,
      AppSizes.segmentedHeight,
    );
    expect(box.padding, const EdgeInsets.all(AppSizes.segmentTrackPadding));

    final BoxDecoration decoration = box.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.primaryTrack);
    expect(
      decoration.borderRadius,
      BorderRadius.circular(AppRadii.segmentedTrack),
    );

    // Three equal pills separated by 4 px gaps inside the 4 px track padding.
    final double pillWidth =
        (800 - AppSizes.segmentTrackPadding * 2 - AppSizes.segmentGap * 2) / 3;
    expect(
      tester.getSize(find.byKey(const Key('segment-pill-1'))).width,
      closeTo(pillWidth, 0.01),
    );
    expect(
      tester.getSize(find.byKey(const Key('segment-pill-1'))).height,
      AppSizes.segmentedHeight - AppSizes.segmentTrackPadding * 2,
    );
  });

  testWidgets('the selected pill is white with a primary 500 label', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const Segmented(
          labels: modes,
          selectedIndex: 1,
          onSelected: _ignore,
        ),
      ),
    );

    expect(
      (pill(tester, 1).decoration! as BoxDecoration).color,
      AppColors.sheet,
    );
    expect(
      pill(tester, 1).decoration! as BoxDecoration,
      isA<BoxDecoration>().having(
        (BoxDecoration d) => d.borderRadius,
        'pill radius',
        BorderRadius.circular(AppRadii.segmentedPill),
      ),
    );

    final Text selected = tester.widget<Text>(find.text('Scientific'));
    expect(selected.style?.fontSize, 14);
    expect(selected.style?.fontWeight, AppTypography.medium);
    expect(selected.style?.color, AppColors.primary);

    expect(
      (pill(tester, 0).decoration! as BoxDecoration).color,
      Colors.transparent,
    );
    final Text inactive = tester.widget<Text>(find.text('Basic'));
    expect(inactive.style?.fontWeight, AppTypography.regular);
    expect(inactive.style?.color, AppColors.segmentedInactive);
  });

  testWidgets('tapping a label reports its index', (tester) async {
    final List<int> taps = <int>[];

    await tester.pumpWidget(
      wrap(
        Segmented(
          labels: modes,
          selectedIndex: 0,
          onSelected: taps.add,
        ),
      ),
    );

    await tester.tap(find.text('Scientific'));
    await tester.tap(find.text('Programmer'));

    expect(taps, <int>[1, 2]);
  });

  testWidgets('each label is a selectable button for screen readers', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      wrap(
        const Segmented(
          labels: modes,
          selectedIndex: 2,
          onSelected: _ignore,
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byKey(const Key('segment-2'))),
      matchesSemantics(
        label: 'Programmer',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.byKey(const Key('segment-0'))),
      matchesSemantics(
        label: 'Basic',
        isButton: true,
        hasSelectedState: true,
        isSelected: false,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
      ),
    );

    semantics.dispose();
  });
}

void _ignore(int _) {}
