import 'dart:io';

import 'package:astronaksh/core/chart_customization.dart';
import 'package:astronaksh/core/ephemeris_manager.dart';
import 'package:astronaksh/logic/matching/matching_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jyotish/jyotish.dart';
import 'package:path/path.dart' as p;

import '../utils/test_chart_builder.dart';

void main() {
  setUpAll(() async {
    try {
      final exeDir = p.dirname(Platform.resolvedExecutable);
      final projectDll = File('swisseph.dll');
      if (projectDll.existsSync()) {
        final targetDll = File(p.join(exeDir, 'swisseph.dll'));
        if (!targetDll.existsSync()) {
          projectDll.copySync(targetDll.path);
        }
      }
    } catch (e) {
      // Ignore copy error (might have been copied or already exists/in use)
    }

    // Initialize the Jyotish library with Swiss Ephemeris data path
    await EphemerisManager.jyotish.initialize(ephemerisPath: 'assets/ephe');
  });

  group('Advanced Jyotish Feature Suite (v2.11.0) Tests', () {
    test('VargaConfiguration settings serialization and defaults in ChartCustomization', () {
      final config = ChartCustomization();
      expect(config.horaMethod, HoraMethod.parashara);
      expect(config.drekkanaMethod, DrekkanaMethod.parashara);
      expect(config.navamshaMethod, NavamshaMethod.parashara);
      expect(config.dashamshaMethod, DashamshaMethod.parashara);

      final json = config.toJson();
      final parsed = ChartCustomization.fromJson(json);
      expect(parsed.horaMethod, HoraMethod.parashara);
      expect(parsed.drekkanaMethod, DrekkanaMethod.parashara);
      expect(parsed.navamshaMethod, NavamshaMethod.parashara);
      expect(parsed.dashamshaMethod, DashamshaMethod.parashara);
    });

    test('Special Lagnas computation', () {
      final chart = TestChartBuilder()
          .withAscendantSign(1) // Aries
          .withLocation(28.6139, 77.2090) // Delhi
          .build();

      final sunrise = DateTime.utc(2000, 1, 1, 6, 30);
      final specialLagnas = EphemerisManager.jyotish.calculateSpecialLagnas(chart.baseChart, sunrise);

      expect(specialLagnas.horaLagna, isNotNull);
      expect(specialLagnas.ghatiLagna, isNotNull);
      expect(specialLagnas.sreeLagna, isNotNull);
    });

    test('Graha Yuddha check', () {
      final chart = TestChartBuilder()
          .withAscendantSign(1)
          .withPlanetInSign(Planet.mars, 2, 10.5) // Taurus 10.5 deg
          .withPlanetInSign(Planet.mercury, 2, 10.6) // Taurus 10.6 deg
          .build();

      final war = EphemerisManager.jyotish.checkGrahaYuddha(chart.baseChart);
      expect(war, isNotNull);
      expect(war!.planet1, Planet.mars);
      expect(war.planet2, Planet.mercury);
      expect(war.longitudeDifference, closeTo(0.1, 0.001));
      expect(war.winnerId, isNotNull);
    });

    test('Kundali Matching with CompatibilityReport API', () {
      final groom = TestChartBuilder()
          .withAscendantSign(1)
          .withPlanetInSign(Planet.moon, 1, 15.0) // Aries Moon (Aswini)
          .build();

      final bride = TestChartBuilder()
          .withAscendantSign(4)
          .withPlanetInSign(Planet.moon, 4, 15.0) // Cancer Moon (Pushya)
          .build();

      final report = MatchingService.analyzeCompatibility(groom, bride);
      expect(report, isNotNull);
      expect(report.ashtakootaScore, isA<double>());
      expect(report.kootaResults.length, equals(8));
      expect(report.manglikMatch, isNotNull);
    });
  });
}
