import 'package:flutter_test/flutter_test.dart';
import 'package:jyotish/jyotish.dart';
import 'package:astronaksh/logic/dasha_system.dart';
import 'package:astronaksh/core/ephemeris_manager.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Ashtottari Dasha Tests', () {
    setUpAll(() async {
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            return '.'; // Return current directory for all path requests in tests
          });
      
      // We might need ephemeris data if the underlying library uses it even for manual charts
      try {
        await EphemerisManager.ensureEphemerisData();
      } catch (e) {
        // Ignore errors if we are just testing logic that doesn't need ephemeris
      }
    });

    test('calculateAshtottariDasha should not throw exception even if not applicable', () async {
      final now = DateTime(1990, 1, 1, 12, 0);
      
      PlanetPosition createPos(Planet p, double long, {double speed = 1.0}) {
        return PlanetPosition(
          planet: p,
          dateTime: now,
          longitude: long,
          latitude: 0.0,
          distance: 1.0,
          longitudeSpeed: speed,
          latitudeSpeed: 0.0,
          distanceSpeed: 0.0,
        );
      }

      VedicPlanetInfo createVedicInfo(Planet p, double long, int house, {double speed = 1.0}) {
        return VedicPlanetInfo(
          position: createPos(p, long, speed: speed),
          house: house,
          dignity: PlanetaryDignity.neutralSign,
        );
      }

      final rahuInfo = createVedicInfo(Planet.meanNode, 300.0, 11, speed: -0.05);

      final chart = VedicChart(
        dateTime: now,
        location: 'New Delhi',
        latitude: 28.61,
        longitudeCoord: 77.21,
        houses: HouseSystem(
          system: 'W',
          cusps: List.generate(12, (i) => i * 30.0),
          ascendant: 0.0,
          midheaven: 270.0,
        ),
        planets: {
          Planet.sun: createVedicInfo(Planet.sun, 250.0, 9),
          Planet.moon: createVedicInfo(Planet.moon, 310.0, 11),
          Planet.mars: createVedicInfo(Planet.mars, 200.0, 8),
          Planet.mercury: createVedicInfo(Planet.mercury, 240.0, 9),
          Planet.jupiter: createVedicInfo(Planet.jupiter, 90.0, 4),
          Planet.venus: createVedicInfo(Planet.venus, 280.0, 10),
          Planet.saturn: createVedicInfo(Planet.saturn, 285.0, 10),
          Planet.meanNode: rahuInfo,
        },
        rahu: rahuInfo,
        ketu: KetuPosition(rahuPosition: rahuInfo.position),
      );

      // This should NOT throw JyotishException because we added forceCalculation: true and try-catch
      final dasha = await DashaSystem.calculateAshtottariDasha(chart);
      
      expect(dasha, isNotNull);
      // In this case, we expect it to succeed because of forceCalculation: true
      expect(dasha.mahadashas, isNotEmpty);
    });
  });
}
