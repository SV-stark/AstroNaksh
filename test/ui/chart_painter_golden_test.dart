import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astronaksh/ui/painters/north_indian_chart_painter.dart';
import 'package:astronaksh/ui/painters/south_indian_chart_painter.dart';
import 'package:astronaksh/core/chart_customization.dart';

/// Golden tests for chart painters (E11).
void main() {
  const testColors = ChartColors(
    background: Color(0xFF1a1a2e),
    houseBorder: Color(0xFFe0e0e0),
    houseFill: Color(0xFF16213e),
    planetText: Color(0xFFFFFFFF),
    retrogradeIndicator: Color(0xFFff6b6b),
    ascendantMarker: Color(0xFF00e5ff),
    beneficPlanet: Color(0xFF69f0ae),
    maleficPlanet: Color(0xFFff8a80),
    neutralPlanet: Color(0xFF82b1ff),
  );

  group('NorthIndianChartPainter golden tests', () {
    testWidgets('renders basic chart with planets', (tester) async {
      await tester.pumpWidget(
        RepaintBoundary(
          child: SizedBox(
            width: 400,
            height: 400,
            child: CustomPaint(
              painter: NorthIndianChartPainter(
                planetsBySign: {
                  0: ['Sun', 'Mars'],
                  4: ['Moon'],
                  8: ['Jupiter'],
                },
                ascendantSign: 1,
                colors: testColors,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(CustomPaint),
        matchesGoldenFile('goldens/north_indian_basic_chart.png'),
      );
    });

    testWidgets('renders chart with many planets', (tester) async {
      await tester.pumpWidget(
        RepaintBoundary(
          child: SizedBox(
            width: 400,
            height: 400,
            child: CustomPaint(
              painter: NorthIndianChartPainter(
                planetsBySign: {
                  0: ['Sun', 'Mars', 'Venus'],
                  1: ['Moon'],
                  2: ['Mercury'],
                  3: ['Jupiter'],
                  4: ['Saturn'],
                  5: ['Rahu'],
                  6: ['Ketu'],
                },
                ascendantSign: 0,
                colors: testColors,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(CustomPaint),
        matchesGoldenFile('goldens/north_indian_full_chart.png'),
      );
    });

    testWidgets('renders empty chart', (tester) async {
      await tester.pumpWidget(
        RepaintBoundary(
          child: SizedBox(
            width: 400,
            height: 400,
            child: CustomPaint(
              painter: NorthIndianChartPainter(
                planetsBySign: {},
                ascendantSign: 0,
                colors: testColors,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(CustomPaint),
        matchesGoldenFile('goldens/north_indian_empty_chart.png'),
      );
    });
  });

  group('SouthIndianChartPainter golden tests', () {
    testWidgets('renders basic chart with planets', (tester) async {
      await tester.pumpWidget(
        RepaintBoundary(
          child: SizedBox(
            width: 400,
            height: 400,
            child: CustomPaint(
              painter: SouthIndianChartPainter(
                planetsBySign: {
                  0: ['Sun', 'Mars'],
                  4: ['Moon'],
                  8: ['Jupiter'],
                },
                ascendantSign: 1,
                colors: testColors,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(CustomPaint),
        matchesGoldenFile('goldens/south_indian_basic_chart.png'),
      );
    });

    testWidgets('renders empty chart', (tester) async {
      await tester.pumpWidget(
        RepaintBoundary(
          child: SizedBox(
            width: 400,
            height: 400,
            child: CustomPaint(
              painter: SouthIndianChartPainter(
                planetsBySign: {},
                ascendantSign: 0,
                colors: testColors,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(CustomPaint),
        matchesGoldenFile('goldens/south_indian_empty_chart.png'),
      );
    });
  });
}
