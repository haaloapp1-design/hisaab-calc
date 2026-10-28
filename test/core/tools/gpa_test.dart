import 'package:calculator/core/tools/gpa.dart';
import 'package:calculator/core/tools/tool_format.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Decimal d(String source) => Decimal.parse(source);

  List<GpaCourse> courses() => <GpaCourse>[
    GpaCourse(name: 'Maths', credits: d('3'), points: d('4')),
    GpaCourse(name: 'Physics', credits: d('4'), points: d('3.5')),
    GpaCourse(name: 'English', credits: d('2'), points: d('3')),
  ];

  test('3 + 4 + 2 credits give 32/9 = 3.56', () {
    final GpaResult result = GpaCalculator.calculate(courses: courses())!;

    expect(formatToolNumber(result.gpa), '3.56');
    expect(result.totalCredits, d('9'));
    expect(result.courseCount, 3);
  });

  test('the percentage follows the chosen scale', () {
    expect(
      formatToolNumber(GpaCalculator.calculate(courses: courses())!.percentage),
      '88.89',
    );
    expect(
      formatToolNumber(
        GpaCalculator.calculate(
          courses: courses(),
          scale: GpaCalculator.fiveScale,
        )!.percentage,
      ),
      '71.11',
    );
    expect(
      formatToolNumber(
        GpaCalculator.calculate(
          courses: courses(),
          scale: GpaCalculator.tenScale,
        )!.percentage,
      ),
      '35.56',
    );
  });

  test('the scale does not change the weighted average', () {
    final GpaResult four = GpaCalculator.calculate(courses: courses())!;
    final GpaResult five = GpaCalculator.calculate(
      courses: courses(),
      scale: GpaCalculator.fiveScale,
    )!;

    expect(five.gpa, four.gpa);
  });

  test('a single course is its own grade', () {
    final GpaResult result = GpaCalculator.calculate(
      courses: <GpaCourse>[
        GpaCourse(name: 'One', credits: d('1'), points: d('3.7')),
      ],
    )!;

    expect(formatToolNumber(result.gpa), '3.70');
    expect(result.totalCredits, d('1'));
    expect(result.courseCount, 1);
  });

  test('zero-credit courses are counted but do not weigh', () {
    final GpaResult result = GpaCalculator.calculate(
      courses: <GpaCourse>[
        ...courses(),
        GpaCourse(name: 'Club', credits: Decimal.zero, points: d('1')),
      ],
    )!;

    expect(formatToolNumber(result.gpa), '3.56');
    expect(result.totalCredits, d('9'));
    expect(result.courseCount, 4);
  });

  test('points above the scale are not capped', () {
    final GpaResult result = GpaCalculator.calculate(
      courses: <GpaCourse>[
        GpaCourse(name: 'Honours', credits: d('2'), points: d('4.5')),
      ],
    )!;

    expect(formatToolNumber(result.gpa), '4.50');
    expect(formatToolNumber(result.percentage), '112.50');
  });

  test('no credits means no average', () {
    expect(
      GpaCalculator.calculate(
        courses: <GpaCourse>[
          GpaCourse(name: 'Zero', credits: Decimal.zero, points: d('4')),
        ],
      ),
      isNull,
    );
    expect(GpaCalculator.calculate(courses: <GpaCourse>[]), isNull);
  });

  test('negative credits, points or scale are rejected', () {
    expect(
      () => GpaCalculator.calculate(
        courses: <GpaCourse>[
          GpaCourse(name: 'Bad', credits: d('-1'), points: d('4')),
        ],
      ),
      throwsArgumentError,
    );
    expect(
      () => GpaCalculator.calculate(
        courses: <GpaCourse>[
          GpaCourse(name: 'Bad', credits: d('1'), points: d('-4')),
        ],
      ),
      throwsArgumentError,
    );
    expect(
      () => GpaCalculator.calculate(courses: courses(), scale: Decimal.zero),
      throwsArgumentError,
    );
    expect(
      () => GpaCalculator.calculate(courses: courses(), scale: d('-4')),
      throwsArgumentError,
    );
  });

  test('the result prints its value, credits and percentage', () {
    final GpaResult result = GpaCalculator.calculate(courses: courses())!;

    expect(result.toString(), contains('9 credits'));
    expect(result.toString(), contains('88.89%'));
    expect(result.toString(), contains('3 courses'));
  });
}
