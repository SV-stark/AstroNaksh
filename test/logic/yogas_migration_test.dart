import 'package:astronaksh/logic/yoga_dosha_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jyotish/jyotish.dart';

import '../utils/test_chart_builder.dart';

void main() {
  group('Yoga and Dosha Analyzer Verification Tests', () {
    late TestChartBuilder builder;

    setUp(() {
      builder = TestChartBuilder();
    });

    test('Gajakesari Yoga Detection via YogaDoshaAnalyzer', () {
      final chart = builder
          .withAscendantSign(1)
          .withPlanetInSign(Planet.moon, 1)
          .withPlanetInSign(Planet.jupiter, 4)
          .build();

      final result = YogaDoshaAnalyzer.analyze(chart);
      final gajakesari = result.yogas.where((y) =>
          y.name.toLowerCase().contains('gaja') ||
          y.description.toLowerCase().contains('gaja'));
      expect(gajakesari, isNotEmpty);
      expect(gajakesari.first.isActive, isTrue);
    });

    test('Budhaditya / Nipuna Yoga Detection via YogaDoshaAnalyzer', () {
      final chart = builder
          .withPlanetInSign(Planet.sun, 1)
          .withPlanetInSign(Planet.mercury, 1)
          .build();

      final result = YogaDoshaAnalyzer.analyze(chart);
      final budhaditya = result.yogas.where((y) =>
          y.name.toLowerCase().contains('nipuna') ||
          y.name.toLowerCase().contains('budhaditya') ||
          y.description.toLowerCase().contains('sun and mercury'));
      expect(budhaditya, isNotEmpty);
      expect(budhaditya.first.isActive, isTrue);
    });

    test('Chandra Mangala Yoga Detection via YogaDoshaAnalyzer', () {
      final chart = builder
          .withPlanetInSign(Planet.moon, 2)
          .withPlanetInSign(Planet.mars, 2)
          .build();

      final result = YogaDoshaAnalyzer.analyze(chart);
      final chandraMangala = result.yogas.where((y) => y.name.contains('Chandra Mangala') || y.name.contains('Chandra-Mangala'));
      expect(chandraMangala, isNotEmpty);
      expect(chandraMangala.first.isActive, isTrue);
    });

    test('Kaal Sarp Dosha Detection via YogaDoshaAnalyzer', () {
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

      final result = YogaDoshaAnalyzer.analyze(chart);
      final kaalSarp = result.doshas.where((d) => d.name.contains('Kaal Sarp'));
      expect(kaalSarp, isNotEmpty);
      expect(kaalSarp.first.isActive, isTrue);
    });

    test('Guru Chandal Dosha Detection via YogaDoshaAnalyzer', () {
      final chart = builder
          .withPlanetInSign(Planet.jupiter, 1)
          .withRahuInSign(1)
          .build();

      final result = YogaDoshaAnalyzer.analyze(chart);
      final guruChandal = result.doshas.where((d) => d.name.contains('Guru Chandal') || d.name.contains('Guru-Chandal'));
      expect(guruChandal, isNotEmpty);
      expect(guruChandal.first.isActive, isTrue);
    });
  });
}
