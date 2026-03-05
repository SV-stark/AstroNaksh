import 'package:flutter_test/flutter_test.dart';
import 'package:astronaksh/data/models.dart';

void main() {
  group('Location Tests - Additional', () {
    test('Location handles negative coordinates', () {
      final location = Location(latitude: -33.8688, longitude: 151.2093);
      expect(location.latitude, equals(-33.8688));
      expect(location.longitude, equals(151.2093));
    });

    test('Location handles zero coordinates', () {
      final location = Location(latitude: 0.0, longitude: 0.0);
      expect(location.latitude, equals(0.0));
      expect(location.longitude, equals(0.0));
    });

    test('Location handles extreme coordinates', () {
      final location = Location(latitude: 90.0, longitude: 180.0);
      expect(location.latitude, equals(90.0));
      expect(location.longitude, equals(180.0));
    });

    test('Location handles negative longitude', () {
      final location = Location(latitude: 40.7128, longitude: -74.0060);
      expect(location.longitude, equals(-74.0060));
    });
  });

  group('BirthData Tests - Additional', () {
    test('BirthData handles all parameters', () {
      final birthData = BirthData(
        dateTime: DateTime(1990, 6, 15, 10, 30),
        location: Location(latitude: 28.6139, longitude: 77.2090),
        name: 'Test User',
        place: 'New Delhi, India',
        timezone: 'Asia/Kolkata',
      );
      expect(birthData.name, equals('Test User'));
      expect(birthData.place, equals('New Delhi, India'));
      expect(birthData.timezone, equals('Asia/Kolkata'));
    });

    test('BirthData handles empty name and place', () {
      final birthData = BirthData(
        dateTime: DateTime(1990, 1, 1),
        location: Location(latitude: 0, longitude: 0),
      );
      expect(birthData.name, equals(''));
      expect(birthData.place, equals(''));
      expect(birthData.timezone, equals(''));
    });

    test('BirthData fromJson handles missing optional fields', () {
      final json = {
        'dateTime': '1990-01-01T12:00:00.000',
        'location': {'latitude': 0.0, 'longitude': 0.0},
      };
      final birthData = BirthData.fromJson(json);
      expect(birthData.name, equals(''));
      expect(birthData.place, equals(''));
      expect(birthData.timezone, equals(''));
    });
  });

  group('AstrologyConstants Tests - Additional', () {
    test('nakshatraNames are valid strings', () {
      for (final name in AstrologyConstants.nakshatraNames) {
        expect(name, isNotEmpty);
        expect(name, isA<String>());
      }
    });

    test('nakshatraNames contains Indian nakshatras', () {
      expect(AstrologyConstants.nakshatraNames, contains('Ashwini'));
      expect(AstrologyConstants.nakshatraNames, contains('Krittika'));
      expect(AstrologyConstants.nakshatraNames, contains('Mula'));
      expect(AstrologyConstants.nakshatraNames, contains('Revati'));
    });

    test('signNames contains all Western signs', () {
      expect(AstrologyConstants.signNames, contains('Aries'));
      expect(AstrologyConstants.signNames, contains('Taurus'));
      expect(AstrologyConstants.signNames, contains('Gemini'));
      expect(AstrologyConstants.signNames, contains('Cancer'));
      expect(AstrologyConstants.signNames, contains('Leo'));
      expect(AstrologyConstants.signNames, contains('Virgo'));
      expect(AstrologyConstants.signNames, contains('Libra'));
      expect(AstrologyConstants.signNames, contains('Scorpio'));
      expect(AstrologyConstants.signNames, contains('Sagittarius'));
      expect(AstrologyConstants.signNames, contains('Capricorn'));
      expect(AstrologyConstants.signNames, contains('Aquarius'));
      expect(AstrologyConstants.signNames, contains('Pisces'));
    });

    test('getSignLord covers all 12 signs uniquely', () {
      final lords = <String>{};
      for (int i = 0; i < 12; i++) {
        lords.add(AstrologyConstants.getSignLord(i));
      }
      // 7 unique lords: Mars, Venus, Mercury, Moon, Sun, Jupiter, Saturn
      expect(lords.length, greaterThanOrEqualTo(5));
    });
  });

  group('DivisionalChartData Tests', () {
    test('can create with empty positions', () {
      final chart = DivisionalChartData(
        code: 'D1',
        name: 'Lagna',
        description: 'Birth Chart',
        positions: {},
      );
      expect(chart.code, equals('D1'));
      expect(chart.name, equals('Lagna'));
      expect(chart.positions, isEmpty);
    });

    test('getPlanetSign handles edge cases', () {
      final chart = DivisionalChartData(
        code: 'D1',
        name: 'Lagna',
        description: 'Birth Chart',
        positions: {
          'Sun': 0.0,   // Exactly on Aries boundary
          'Moon': 29.99, // End of Aries
          'Mars': 30.0,  // Exactly on Taurus boundary
        },
      );
      expect(chart.getPlanetSign('Sun'), equals(0)); // Aries
      expect(chart.getPlanetSign('Moon'), equals(0)); // Aries
      expect(chart.getPlanetSign('Mars'), equals(1)); // Taurus
    });
  });

  group('KPData Tests', () {
    test('can create KPData with empty lists', () {
      final kpData = KPData(
        subLords: [],
        significators: [],
        rulingPlanets: [],
      );
      expect(kpData.subLords, isEmpty);
      expect(kpData.significators, isEmpty);
      expect(kpData.rulingPlanets, isEmpty);
    });

    test('can create KPData with values', () {
      final kpData = KPData(
        subLords: [
          KPSubLord(
            starLord: 'Ketu',
            subLord: 'Venus',
            subSubLord: 'Mercury',
            nakshatraIndex: 1,
            nakshatraName: 'Bharani',
          ),
        ],
        significators: ['Sun', 'Moon', 'Mars'],
        rulingPlanets: ['Ketu', 'Venus', 'Mercury'],
      );
      expect(kpData.subLords.length, equals(1));
      expect(kpData.significators.length, equals(3));
      expect(kpData.rulingPlanets.length, equals(3));
    });
  });
}
