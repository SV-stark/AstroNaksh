import 'package:astronaksh/core/chart_customization.dart';
import 'package:astronaksh/ui/widgets/chart_widget.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

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

  group('ChartWidget Interactive Tap Tests', () {
    testWidgets('North Indian Chart taps on houses correctly', (tester) async {
      int? tappedHouseIndex;

      await tester.pumpWidget(
        ProviderScope(
          child: FluentApp(
            home: ScaffoldPage(
              content: Center(
                child: ChartWidget(
                  planetsBySign: const {},
                  ascendantSign: 1,
                  style: ChartStyle.northIndian,
                  size: 300,
                  onHouseTapped: (index) {
                    tappedHouseIndex = index;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find the ChartWidget
      final chartFinder = find.byType(ChartWidget);
      expect(chartFinder, findsOneWidget);

      // Tap top-center (House 1 center is (150, 75))
      await tester.tapAt(tester.getCenter(chartFinder) + const Offset(0, -75));
      await tester.pump();
      expect(tappedHouseIndex, equals(1));

      // Tap bottom-center (House 7 center is (150, 225))
      await tester.tapAt(tester.getCenter(chartFinder) + const Offset(0, 75));
      await tester.pump();
      expect(tappedHouseIndex, equals(7));

      // Tap far-left (House 4 center is (75, 150))
      await tester.tapAt(tester.getCenter(chartFinder) + const Offset(-75, 0));
      await tester.pump();
      expect(tappedHouseIndex, equals(4));

      // Tap far-right (House 10 center is (225, 150))
      await tester.tapAt(tester.getCenter(chartFinder) + const Offset(75, 0));
      await tester.pump();
      expect(tappedHouseIndex, equals(10));
    });

    testWidgets('South Indian Chart taps on cells correctly', (tester) async {
      int? tappedHouseIndex;

      await tester.pumpWidget(
        ProviderScope(
          child: FluentApp(
            home: ScaffoldPage(
              content: Center(
                child: ChartWidget(
                  planetsBySign: const {},
                  ascendantSign: 1, // Aries is ascendant (House 1)
                  style: ChartStyle.southIndian,
                  size: 300,
                  onHouseTapped: (index) {
                    tappedHouseIndex = index;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final chartFinder = find.byType(ChartWidget);
      expect(chartFinder, findsOneWidget);

      // South Indian chart is a 4x4 grid. Let's calculate offset from center of ChartWidget.
      // Total size: 300x300. Center is (150, 150).
      // Each cell is 75x75.
      // Cell offsets from top-left:
      // Row 0, Col 1: Aries. Center at x: 1.5 * 75 = 112.5 (offset -37.5 from center), y: 0.5 * 75 = 37.5 (offset -112.5 from center)
      final ariesOffset = const Offset(-37.5, -112.5);
      await tester.tapAt(tester.getCenter(chartFinder) + ariesOffset);
      await tester.pump();
      // Since ascendantSign = 1 (Aries), Aries is House 1
      expect(tappedHouseIndex, equals(1));

      // Row 0, Col 3: Gemini. Center at x: 3.5 * 75 = 262.5 (offset 112.5 from center), y: 37.5 (offset -112.5 from center)
      final geminiOffset = const Offset(112.5, -112.5);
      await tester.tapAt(tester.getCenter(chartFinder) + geminiOffset);
      await tester.pump();
      // Aries is 1, Taurus is 2, Gemini is 3. So Gemini is House 3
      expect(tappedHouseIndex, equals(3));

      // Row 1, Col 1: Middle empty space. Center at x: 112.5 (-37.5), y: 112.5 (-37.5)
      // This should return null (i.e. not trigger callback)
      tappedHouseIndex = null;
      await tester.tapAt(tester.getCenter(chartFinder) + const Offset(-37.5, -37.5));
      await tester.pump();
      expect(tappedHouseIndex, isNull);
    });
  });
}
