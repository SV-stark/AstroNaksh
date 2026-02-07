import 'package:flutter_test/flutter_test.dart';
import 'package:astronaksh/core/rashiphal_rules.dart';
import 'package:astronaksh/logic/horary_service.dart';
import 'package:astronaksh/logic/yoga_dosha_analyzer.dart';
import 'package:astronaksh/data/models.dart';
import 'package:jyotish/jyotish.dart';

// Mock or stub classes if necessary, but we try to use real logic where possible
void main() {
  group('Astronomy Fixes Verification', () {
    test('Rashiphal Rules - Rahu Kaalam with Sunrise/Sunset', () {
      final date = DateTime(2023, 10, 23); // Monday
      // Rise: 6:00, Set: 18:00 -> 12 hours duration
      // Monday Rahu Kaalam is 2nd part (7:30 - 9:00 for 6am-6pm)
      final sunrise = DateTime(2023, 10, 23, 6, 0);
      final sunset = DateTime(2023, 10, 23, 18, 0);

      final timings = RashiphalRules.getMuhurtaTimings(
        date,
        sunrise: sunrise,
        sunset: sunset,
      );

      bool foundRahu = false;
      for (var t in timings) {
        if (t.contains('Rahu Kalam')) {
          foundRahu = true;
          // Expected: 07:30 - 09:00
          expect(t.contains('07:30'), true, reason: 'Start time mismatch: $t');
          expect(t.contains('09:00'), true, reason: 'End time mismatch: $t');
        }
      }
      expect(foundRahu, true);
    });

    test('Yoga Dosha - Kala Sarp Precision', () {
      // 1. Create Dummy Objects for CompleteChartData
      final dummyLoc = Location(latitude: 0, longitude: 0);
      final dummyBirth = BirthData(
        dateTime: DateTime.now(),
        location: dummyLoc,
      );

      final dummyKP = KPData(
        subLords: [],
        significators: [],
        rulingPlanets: [],
      );
      final dummyDasha = DashaData(
        vimshottari: VimshottariDasha(
          birthLord: 'Sun',
          balanceAtBirth: 0,
          mahadashas: [],
        ),
        yogini: YoginiDasha(startYogini: 'Mangala', mahadashas: []),
        chara: CharaDasha(startSign: 1, periods: []),
      );

      // 2. Construct VedicChart with Rahu=0, Ketu=180, and others in between
      final date = DateTime.now();

      // Helper to create PlanetInfo
      VedicPlanetInfo createInfo(Planet p, double lon) {
        final pos = PlanetPosition(
          planet: p,
          dateTime: date,
          longitude: lon,
          latitude: 0,
          distance: 1,
          longitudeSpeed: 0,
          latitudeSpeed: 0,
          distanceSpeed: 0,
          isCombust: false,
        );
        return VedicPlanetInfo(
          position: pos,
          house: (lon / 30).floor() + 1,
          dignity: PlanetaryDignity.neutralSign,
          isCombust: false,
        );
      }

      final planetsMap = <Planet, VedicPlanetInfo>{
        Planet.sun: createInfo(Planet.sun, 10),
        Planet.moon: createInfo(Planet.moon, 20),
        Planet.mars: createInfo(Planet.mars, 30),
        Planet.mercury: createInfo(Planet.mercury, 40),
        Planet.jupiter: createInfo(Planet.jupiter, 50),
        Planet.venus: createInfo(Planet.venus, 60),
        Planet.saturn: createInfo(Planet.saturn, 70),
      };

      final rahuInfo = createInfo(Planet.meanNode, 0);
      // KetuPosition is a subclass of PlanetPosition or separate?
      // In custom_chart_service: final ketu = KetuPosition(rahuPosition: rahuPosition);
      // Let's assume KetuPosition is available from jyotish
      final ketuPos = KetuPosition(rahuPosition: rahuInfo.position);

      final houses = HouseSystem(
        system: 'Placidus',
        cusps: List.filled(12, 0.0), // Dummy cusps
        ascendant: 90,
        midheaven: 180,
      );

      final vedicChart = VedicChart(
        dateTime: date,
        location: '0,0',
        latitude: 0,
        longitudeCoord: 0,
        houses: houses,
        planets: planetsMap,
        rahu: rahuInfo,
        ketu: ketuPos,
      );

      final chart = CompleteChartData(
        baseChart: vedicChart,
        kpData: dummyKP,
        dashaData: dummyDasha,
        divisionalCharts: {},
        significatorTable: {},
        birthData: dummyBirth,
      );

      // 3. Analyze
      // Assuming YogaDoshaAnalyzer.analyze returns List<String> based on previous observations
      // If it implies modifying a list passed in, I'd check that.
      // But looking at code usage: yogas.add(...) -> usually implies it builds a list.
      // Wait, previously I saw analyze(chart) signature.
      // Let's assume it returns a list of results (YogaDoshaAnalysisResult or similar).
      // Logic file says: static YogaDoshaAnalysisResult analyze(CompleteChartData chart)
      // I need to check models for YogaDoshaAnalysisResult structure.
      // It has `List<BhangaResult> yogas` and `doshas`.

      final result = YogaDoshaAnalyzer.analyze(chart);

      // Check doshas
      // BhangaResult has `name`.
      // We expect 'Kaal Sarp Dosha' or similar.
      // Wait, _hasKaalSarpDosha returns bool.
      // Where is it added?
      // In `_findDoshas`:
      // if (_hasKaalSarpDosha(chart)) { doshas.add(BhangaResult(name: 'Kaal Sarp Dosha', ...)); }

      bool hasKaalSarp = result.doshas.any((d) => d.name.contains('Kaal Sarp'));
      expect(hasKaalSarp, true, reason: 'Kaal Sarp Dosha should be detected');
    });

    // We cannot easily test HoraryService's async logic without mocking _chartService or running full integration
    // But we can verify it compiles and basic instantiation works.
    test('Horary Service Instantiation', () {
      final service = HoraryService();
      expect(service, isNotNull);
    });
  });
}
