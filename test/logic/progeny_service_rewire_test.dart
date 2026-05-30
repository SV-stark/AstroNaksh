import 'package:astronaksh/logic/progeny_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jyotish/jyotish.dart' hide ProgenyService;
import '../utils/test_chart_builder.dart';

void main() {
  group('Progeny Service Rewire Test Suite', () {
    test('Rewired progeny analysis returns valid structure and values', () {
      // Build a test chart with some basic planet positions
      final chart = TestChartBuilder()
          .withAscendantSign(1) // Aries rising
          .withPlanetInSign(Planet.jupiter, 1, 15.0) // Jupiter in Aries (1st house)
          .withPlanetInSign(Planet.venus, 5, 10.0) // Venus in Leo (5th house)
          .build();

      final service = ProgenyService();
      final analysis = service.analyzeProgeny(chart);

      // Verify the returned structure
      expect(analysis, isNotNull);
      expect(analysis.overallScore, isA<int>());
      expect(analysis.overallScore, greaterThanOrEqualTo(0));
      expect(analysis.overallScore, lessThanOrEqualTo(100));

      expect(analysis.prospects, isNotEmpty);
      expect(analysis.prediction, isNotEmpty);
      expect(analysis.recommendations, isNotEmpty);

      expect(analysis.factors, hasLength(3));
      
      final fifthHouse = analysis.factors.firstWhere((f) => f.name == '5th House');
      expect(fifthHouse.score, isA<int>());
      expect(fifthHouse.description, contains('5th House'));

      final jupiter = analysis.factors.firstWhere((f) => f.name == 'Jupiter (Karaka)');
      expect(jupiter.score, isA<int>());
      expect(jupiter.description, contains('Jupiter'));

      final d7 = analysis.factors.firstWhere((f) => f.name == 'Saptamsha (D7)');
      expect(d7.score, isA<int>());
      expect(d7.description, contains('Saptamsha'));
    });
  });
}
