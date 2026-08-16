import 'package:astronaksh/core/ephemeris_manager.dart';
import 'package:astronaksh/data/models.dart';
import 'package:astronaksh/logic/kp_prashna_service.dart';
import 'package:astronaksh/logic/remedies_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jyotish/jyotish.dart';

import 'utils/test_chart_builder.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await EphemerisManager.ensureEphemerisData();
  });

  group('RemediesService Tests', () {

    test('generateRemediesProfile returns valid gemstones and remedies', () {
      final completeData = TestChartBuilder()
          .withAscendantSign(5) // Leo Ascendant (Sun is Lagna Lord)
          .withPlanetInSign(Planet.sun, 2)
          .withPlanetInSign(Planet.jupiter, 9)
          .build();

      final chart = completeData.baseChart;
      final profile = RemediesService.generateRemediesProfile(chart);

      expect(profile.gemstones, isNotEmpty);
      expect(profile.planetaryRemedies.length, equals(9));
      expect(profile.primaryRudraksha, contains('Rudraksha'));
      expect(profile.overallGuidanceNote, isNotEmpty);

      // Verify Lagna gemstone for Leo Ascendant
      final lagnaGem = profile.gemstones.firstWhere((g) => g.type == GemstoneType.life);
      expect(lagnaGem.planet, equals('Sun'));
      expect(lagnaGem.primaryGemstone, equals('Ruby (Manik)'));
      expect(lagnaGem.metal, equals('Gold or Copper'));
    });
  });

  group('KPPrashnaService Tests', () {
    test('analyzePrashna calculates verdict and significators for seed 108', () async {
      final service = KPPrashnaService();

      final result = await service.analyzePrashna(
        seedNumber: 108,
        category: PrashnaCategory.career,
        dateTime: DateTime(2026, 7, 22, 12, 0),
        location: GeographicLocation(latitude: 28.6139, longitude: 77.2090),

      );

      expect(result.seedNumber, equals(108));
      expect(result.category, equals(PrashnaCategory.career));
      expect(result.queryTitle, contains('Job'));
      expect(result.primaryHouses, contains(10));
      expect(result.confidencePercentage, greaterThan(50.0));
      expect(result.significatorBreakdown, isNotEmpty);
      expect(result.detailedInterpretation, isNotEmpty);
      expect(result.timingGuidance, isNotEmpty);
    });
  });
}
