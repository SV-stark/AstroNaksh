import 'package:flutter_test/flutter_test.dart';
import 'package:astronaksh/logic/yoga_dosha_analyzer.dart';
import 'package:astronaksh/data/models.dart';
import 'package:jyotish/jyotish.dart'; // For Planet enum
import 'utils/test_chart_builder.dart'; // Relative import for helper

void main() {
  group('Yoga/Dosha Bhanga Logic', () {
    late TestChartBuilder builder;

    setUp(() {
      builder = TestChartBuilder();
    });

    // --- Manglik Dosha Tests ---
    test('Manglik Dosha detected (Mars in 7th)', () {
      // Ascendant Aries (1), Mars in Libra (7) -> 7th House
      final chart = builder
          .withAscendantSign(1) // Aries
          .withPlanetInSign(Planet.mars, 7) // Libra
          .build();

      final analysis = YogaDoshaAnalyzer.analyze(chart);
      final manglik = analysis.doshas.firstWhere(
        (d) => d.name.contains('Manglik'),
        orElse: () => BhangaResult(
          name: 'None',
          isActive: false,
          description: '',
          status: '',
          strength: 0,
          cancellationReasons: [],
        ),
      );

      expect(manglik.name, contains('Manglik'));
      expect(manglik.isActive, isTrue);
    });

    test('Manglik Dosha Cancelled (Mars in Own Sign Aries)', () {
      // Ascendant Libra (7), Mars in Aries (1) -> 7th House but Own Sign
      final chart = builder
          .withAscendantSign(7) // Libra
          .withPlanetInSign(Planet.mars, 1) // Aries (Own Sign)
          .build();

      final analysis = YogaDoshaAnalyzer.analyze(chart);
      final manglik = analysis.doshas.firstWhere(
        (d) => d.name.contains('Manglik'),
        orElse: () => BhangaResult(
          name: 'None',
          isActive: false,
          description: '',
          status: '',
          strength: 0,
          cancellationReasons: [],
        ),
      );

      // Should be active but have cancellation
      expect(manglik.isActive, isTrue);
      expect(manglik.status, contains('Cancelled'));
      expect(manglik.cancellationReasons, isNotEmpty);
    });

    // --- Kaal Sarp Dosha Tests ---
    test('Kaal Sarp Dosha Detected (All planets between Rahu/Ketu)', () {
      // Rahu in 1 (Aries), Ketu in 7 (Libra)
      // All others in 2, 3, 4
      final chart = builder
          .withAscendantSign(1)
          .withRahuInSign(1) // Aries
          // Ketu in 7 automatically
          .withPlanetInSign(Planet.sun, 2)
          .withPlanetInSign(Planet.moon, 2)
          .withPlanetInSign(Planet.mars, 3)
          .withPlanetInSign(Planet.mercury, 3)
          .withPlanetInSign(Planet.jupiter, 4)
          .withPlanetInSign(Planet.venus, 4)
          .withPlanetInSign(Planet.saturn, 4)
          .build();

      final analysis = YogaDoshaAnalyzer.analyze(chart);
      final ksd = analysis.doshas.firstWhere(
        (d) => d.name.contains('Kaal Sarp'),
        orElse: () => BhangaResult(
          name: 'None',
          isActive: false,
          description: '',
          status: '',
          strength: 0,
          cancellationReasons: [],
        ),
      );

      expect(ksd.name, contains('Kaal Sarp'));
      expect(ksd.isActive, isTrue);
    });

    test('Kaal Sarp Dosha Cancelled (One planet outside)', () {
      final chart = builder
          .withAscendantSign(1)
          .withRahuInSign(1)
          // Ketu in 7
          .withPlanetInSign(Planet.sun, 2) // Side A
          .withPlanetInSign(Planet.jupiter, 9) // Side B (Outside Side A)
          .build();

      final analysis = YogaDoshaAnalyzer.analyze(chart);
      final ksd = analysis.doshas.firstWhere(
        (d) => d.name.contains('Kaal Sarp'),
        orElse: () => BhangaResult(
          name: 'None',
          isActive: false,
          description: '',
          status: '',
          strength: 0,
          cancellationReasons: [],
        ),
      );

      // Should NOT be active or should be cancelled
      expect(ksd.isActive, isFalse);
    });
  });
}
