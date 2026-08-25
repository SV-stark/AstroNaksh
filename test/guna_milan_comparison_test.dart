import 'package:astronaksh/core/ephemeris_manager.dart';
import 'package:astronaksh/logic/chart_comparison.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jyotish/jyotish.dart';

import 'utils/test_chart_builder.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await EphemerisManager.jyotish.initialize();
  });

  group('Guna Milan Comparison & Verification', () {
    test('calculateGunaMilan returns standard Ashtakoota breakdown', () async {
      // Boy: Moon in Ashwini (Aries, Deva gana, Horse yoni, Adi nadi)
      final boyChart = TestChartBuilder()
          .withAscendantSign(1)
          .withPlanetInSign(Planet.moon, 1, 5.0) // 5 deg Aries = Ashwini
          .build();

      // Girl: Moon in Rohini (Taurus, Manushya gana, Serpent yoni, Antya nadi)
      final girlChart = TestChartBuilder()
          .withAscendantSign(1)
          .withPlanetInSign(Planet.moon, 2, 15.0) // 45 deg = Rohini
          .build();

      final gunaScores = EphemerisManager.jyotish.calculateGunaMilan(
        boyChart.baseChart,
        girlChart.baseChart,
      );

      // Verify all 8 kootas have valid ranges
      expect(gunaScores.varna, inInclusiveRange(0, 1));
      expect(gunaScores.vashya, inInclusiveRange(0, 2));
      expect(gunaScores.tara, inInclusiveRange(0.0, 3.0));
      expect(gunaScores.yoni, inInclusiveRange(0, 4));
      expect(gunaScores.grahaMaitri, inInclusiveRange(0, 5));
      expect(gunaScores.gana, inInclusiveRange(0, 6));
      expect(gunaScores.bhakoot, inInclusiveRange(0, 7));
      expect(gunaScores.nadi, inInclusiveRange(0, 8));
      expect(gunaScores.total, inInclusiveRange(0.0, 36.0));

      final analysis = ChartComparison.analyzeCompatibility(boyChart, girlChart);
      expect(analysis.nakshatraAnalysis.totalScore, equals(gunaScores.total));
      expect(analysis.nakshatraAnalysis.varna, equals(gunaScores.varna.toDouble()));
      expect(analysis.nakshatraAnalysis.vashya, equals(gunaScores.vashya.toDouble()));
      expect(analysis.nakshatraAnalysis.tara, equals(gunaScores.tara));
      expect(analysis.nakshatraAnalysis.yoni, equals(gunaScores.yoni.toDouble()));
      expect(analysis.nakshatraAnalysis.maitri, equals(gunaScores.grahaMaitri.toDouble()));
      expect(analysis.nakshatraAnalysis.gana, equals(gunaScores.gana.toDouble()));
      expect(analysis.nakshatraAnalysis.bhakoot, equals(gunaScores.bhakoot.toDouble()));
      expect(analysis.nakshatraAnalysis.nadi, equals(gunaScores.nadi.toDouble()));
    });

    test('Same Moon Sign and Nakshatra yields high compatibility', () {
      final boyChart = TestChartBuilder()
          .withAscendantSign(1)
          .withPlanetInSign(Planet.moon, 1, 5.0)
          .build();

      final girlChart = TestChartBuilder()
          .withAscendantSign(1)
          .withPlanetInSign(Planet.moon, 1, 5.0)
          .build();

      final report = EphemerisManager.jyotish.calculateCompatibilityReport(
        boyChart.baseChart,
        girlChart.baseChart,
      );

      expect(report.gunaScores.varna, equals(1));
      expect(report.gunaScores.vashya, equals(2));
      expect(report.gunaScores.grahaMaitri, equals(5));
      expect(report.gunaScores.gana, equals(6));
      expect(report.gunaScores.bhakoot, equals(7));
    });
  });
}
