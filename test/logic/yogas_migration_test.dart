import 'package:astronaksh/logic/astrology/doshas/guru_chandal_dosha.dart';
import 'package:astronaksh/logic/astrology/doshas/kaal_sarp_dosha.dart';
import 'package:astronaksh/logic/astrology/doshas/mangal_dosha.dart';
import 'package:astronaksh/logic/astrology/yogas/budhaditya_yoga.dart';
import 'package:astronaksh/logic/astrology/yogas/chamara_yoga.dart';
import 'package:astronaksh/logic/astrology/yogas/chandra_mangala_yoga.dart';
import 'package:astronaksh/logic/astrology/yogas/gajakesari_yoga.dart';
import 'package:astronaksh/logic/astrology/yogas/sakat_yoga.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jyotish/jyotish.dart';

import '../utils/test_chart_builder.dart';

void main() {
  group('Yoga Migration Tests', () {
    late TestChartBuilder builder;

    setUp(() {
      builder = TestChartBuilder();
    });

    test('Gajakesari Yoga Detector - Basic Detection', () {
      final detector = GajakesariYogaDetector();
      // Moon in Aries (1), Jupiter in Cancer (4) -> 4th house from Moon
      final chart = builder
          .withAscendantSign(1)
          .withPlanetInSign(Planet.moon, 1)
          .withPlanetInSign(Planet.jupiter, 4)
          .build();

      final result = detector.detect(chart);
      expect(result.isActive, isTrue);
      expect(result.name, contains('Gajakesari'));
      expect(result.strength, greaterThanOrEqualTo(60));
    });

    test('Budhaditya Yoga Detector - Basic Detection', () {
      final detector = BudhadityaYogaDetector();
      // Sun and Mercury in Aries (1)
      final chart = builder
          .withPlanetInSign(Planet.sun, 1)
          .withPlanetInSign(Planet.mercury, 1)
          .build();

      final result = detector.detect(chart);
      expect(result.isActive, isTrue);
      expect(result.name, contains('Budhaditya'));
    });

    test('Chandra Mangala Yoga Detector - Basic Detection', () {
      final detector = ChandraMangalaYogaDetector();
      // Moon and Mars in Taurus (2)
      final chart = builder
          .withPlanetInSign(Planet.moon, 2)
          .withPlanetInSign(Planet.mars, 2)
          .build();

      final result = detector.detect(chart);
      expect(result.isActive, isTrue);
      expect(result.name, contains('Chandra Mangala'));
    });

    test('Mangal Dosha Detector - Basic Detection', () {
      final detector = MangalDoshaDetector();
      // Ascendant Aries (1), Mars in Libra (7) -> 7th House (Bad)
      // Moon in Capricorn (10), Mars in Cancer (4) -> 7th from Moon (Bad)
      final chart = builder
          .withAscendantSign(1)
          .withPlanetInSign(Planet.moon, 10)
          .withPlanetInSign(Planet.mars, 7) // 7th from Lagna, 10th from Moon
          // Wait, I need 2 out of 3.
          // Sign 7 (Libra) is 7th from Lagna (1).
          // Sign 7 is 10th from Moon (10).
          // Let's put Moon in Libra too.
          .withPlanetInSign(Planet.moon, 7) // Mars is 1st from Moon (Bad)
          .build();

      final result = detector.detect(chart);
      expect(result.isActive, isTrue);
      expect(result.status, isNot(contains('Cancelled')));
    });

    test('Kaal Sarp Dosha Detector - Axis Check', () {
      final detector = KaalSarpDoshaDetector();
      // Rahu in 1, Ketu in 7. All others in 2-6.
      final chart = builder
          .withAscendantSign(1)
          .withRahuInSign(1)
          .withPlanetInSign(Planet.sun, 2)
          .withPlanetInSign(Planet.moon, 3)
          .withPlanetInSign(Planet.mars, 4)
          .withPlanetInSign(Planet.mercury, 5)
          .withPlanetInSign(Planet.jupiter, 6)
          .withPlanetInSign(Planet.venus, 2)
          .withPlanetInSign(Planet.saturn, 3)
          .build();

      final result = detector.detect(chart);
      expect(result.isActive, isTrue);
    });
    test('Chamara Yoga Detector - Basic Detection', () {
      final detector = ChamaraYogaDetector();
      // Aries Lagna (1), Mars in Aries (1) - Exalted is actually Cancer, but wait.
      // Mars is exalted in Capricorn (10). Own sign in Aries (1) and Scorpio (8).
      // Let's use Capricorn (10) for Mars.
      // Jupiter aspects Capricorn from Cancer (4) - 7th aspect.
      final chart = builder
          .withAscendantSign(1) // Aries
          .withPlanetInSign(Planet.mars, 10) // Capricorn (Exalted)
          .withPlanetDignity(Planet.mars, PlanetaryDignity.exalted)
          .withPlanetInSign(Planet.jupiter, 4) // Cancer
          .build();

      final result = detector.detect(chart);
      expect(result.isActive, isTrue);
      expect(result.name, contains('Chamara'));
    });

    test('Sakat Yoga Detector - Basic Detection', () {
      final detector = SakatYogaDetector();
      // Ascendant Taurus (2), Moon in Aries (1) -> 12th house (Not Kendra)
      // Jupiter in Virgo (6) -> 6th from Moon
      final chart = builder
          .withAscendantSign(2)
          .withPlanetInSign(Planet.moon, 1)
          .withPlanetInSign(Planet.jupiter, 6)
          .build();

      final result = detector.detect(chart);
      expect(result.isActive, isTrue);
    });

    test('Guru Chandal Dosha Detector - Basic Detection', () {
      final detector = GuruChandalDoshaDetector();
      // Jupiter and Rahu in Aries (1)
      final chart = builder
          .withPlanetInSign(Planet.jupiter, 1)
          .withRahuInSign(1)
          .build();

      final result = detector.detect(chart);
      expect(result.isActive, isTrue);
    });
  });
}
