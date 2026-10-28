import 'package:calculator/features/tools/widgets/tool_date_field.dart';
import 'package:calculator/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );

  /// The screens in `docs/screens/` are 390×844.
  void designSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('shows the label and the formatted date', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(
      app(
        ToolDateField(
          label: 'Date of birth',
          value: DateTime.utc(1990, 1, 1),
          fieldKey: const Key('dob'),
          onChanged: (DateTime _) {},
        ),
      ),
    );

    expect(find.text('Date of birth'), findsOneWidget);
    expect(find.text('1 Jan 1990'), findsOneWidget);
    expect(find.byKey(const Key('dob')), findsOneWidget);
  });

  testWidgets('a picked date is reported as a date-only value', (tester) async {
    designSurface(tester);
    DateTime? picked;
    DateTime? initial;
    DateTime? first;
    DateTime? last;

    await tester.pumpWidget(
      app(
        ToolDateField(
          label: 'Start date',
          value: DateTime.utc(2026, 10, 28),
          fieldKey: const Key('start'),
          firstDate: DateTime.utc(2000, 1, 1),
          lastDate: DateTime.utc(2030, 12, 31),
          picker:
              (BuildContext context, DateTime i, DateTime f, DateTime l) async {
                initial = i;
                first = f;
                last = l;
                return DateTime.utc(2024, 2, 29, 18, 45);
              },
          onChanged: (DateTime date) => picked = date,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('start')));
    await tester.pumpAndSettle();

    expect(picked, DateTime.utc(2024, 2, 29));
    expect(initial, DateTime.utc(2026, 10, 28));
    expect(first, DateTime.utc(2000, 1, 1));
    expect(last, DateTime.utc(2030, 12, 31));
  });

  testWidgets('cancelling the picker keeps the value', (tester) async {
    designSurface(tester);
    DateTime? picked;

    await tester.pumpWidget(
      app(
        ToolDateField(
          label: 'End date',
          value: DateTime.utc(2026, 10, 28),
          fieldKey: const Key('end'),
          picker: (
            BuildContext context,
            DateTime i,
            DateTime f,
            DateTime l,
          ) async => null,
          onChanged: (DateTime date) => picked = date,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('end')));
    await tester.pumpAndSettle();

    expect(picked, isNull);
    expect(find.text('28 Oct 2026'), findsOneWidget);
  });

  testWidgets('the default picker opens the Material dialog', (tester) async {
    designSurface(tester);
    await tester.pumpWidget(
      app(
        ToolDateField(
          label: 'Date of birth',
          value: DateTime.utc(1990, 1, 1),
          fieldKey: const Key('dob'),
          onChanged: (DateTime _) {},
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('dob')));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsNothing);
  });
}
