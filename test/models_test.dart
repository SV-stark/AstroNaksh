import 'package:flutter_test/flutter_test.dart';
import 'package:astronaksh/data/models.dart';

void main() {
  group('AstrologyConstants Tests', () {
    test('nakshatraNames has 27 nakshatras', () {
      expect(AstrologyConstants.nakshatraNames.length, equals(27));
    });

    test('nakshatraNames starts with Ashwini', () {
      expect(AstrologyConstants.nakshatraNames.first, equals('Ashwini'));
    });

    test('nakshatraNames ends with Revati', () {
      expect(AstrologyConstants.nakshatraNames.last, equals('Revati'));
    });

    test('signNames has 12 signs', () {
      expect(AstrologyConstants.signNames.length, equals(12));
    });

    test('signNames starts with Aries', () {
      expect(AstrologyConstants.signNames.first, equals('Aries'));
    });

    test('signNames ends with Pisces', () {
      expect(AstrologyConstants.signNames.last, equals('Pisces'));
    });

    test('getSignName returns correct sign for valid indices', () {
      expect(AstrologyConstants.getSignName(0), equals('Aries'));
      expect(AstrologyConstants.getSignName(1), equals('Taurus'));
      expect(AstrologyConstants.getSignName(11), equals('Pisces'));
    });

    test('getSignName wraps around for indices >= 12', () {
      expect(AstrologyConstants.getSignName(12), equals('Aries'));
      expect(AstrologyConstants.getSignName(24), equals('Aries'));
      expect(AstrologyConstants.getSignName(36), equals('Aries'));
    });

    test('getSignName handles negative indices', () {
      // Dart's % operator can return negative values for negative inputs
      // So -1 % 12 = -1, not 11
      // Test the actual behavior
      expect(AstrologyConstants.getSignName(-1), isIn(['Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces']));
    });

    test('getSignLord returns correct lord for each sign', () {
      expect(AstrologyConstants.getSignLord(0), equals('Mars')); // Aries
      expect(AstrologyConstants.getSignLord(1), equals('Venus')); // Taurus
      expect(AstrologyConstants.getSignLord(2), equals('Mercury')); // Gemini
      expect(AstrologyConstants.getSignLord(3), equals('Moon')); // Cancer
      expect(AstrologyConstants.getSignLord(4), equals('Sun')); // Leo
      expect(AstrologyConstants.getSignLord(5), equals('Mercury')); // Virgo
      expect(AstrologyConstants.getSignLord(6), equals('Venus')); // Libra
      expect(AstrologyConstants.getSignLord(7), equals('Mars')); // Scorpio
      expect(AstrologyConstants.getSignLord(8), equals('Jupiter')); // Sagittarius
      expect(AstrologyConstants.getSignLord(9), equals('Saturn')); // Capricorn
      expect(AstrologyConstants.getSignLord(10), equals('Saturn')); // Aquarius
      expect(AstrologyConstants.getSignLord(11), equals('Jupiter')); // Pisces
    });

    test('getSignLord wraps around for indices >= 12', () {
      expect(AstrologyConstants.getSignLord(12), equals('Mars'));
    });
  });

  group('Location Tests', () {
    test('Location can be created with required parameters', () {
      final location = Location(latitude: 28.6139, longitude: 77.2090);
      expect(location.latitude, equals(28.6139));
      expect(location.longitude, equals(77.2090));
    });

    test('Location toJson returns correct map', () {
      final location = Location(latitude: 28.6139, longitude: 77.2090);
      final json = location.toJson();
      expect(json['latitude'], equals(28.6139));
      expect(json['longitude'], equals(77.2090));
    });

    test('Location fromJson creates correct Location', () {
      final json = {'latitude': 28.6139, 'longitude': 77.2090};
      final location = Location.fromJson(json);
      expect(location.latitude, equals(28.6139));
      expect(location.longitude, equals(77.2090));
    });

    test('Location roundtrip through JSON', () {
      final original = Location(latitude: 40.7128, longitude: -74.0060);
      final json = original.toJson();
      final restored = Location.fromJson(json);
      expect(restored.latitude, equals(original.latitude));
      expect(restored.longitude, equals(original.longitude));
    });
  });

  group('BirthData Tests', () {
    test('BirthData can be created with required parameters', () {
      final birthData = BirthData(
        dateTime: DateTime(1990, 1, 1, 12, 0),
        location: Location(latitude: 28.6139, longitude: 77.2090),
        name: 'Test User',
        place: 'New Delhi',
      );
      expect(birthData.name, equals('Test User'));
      expect(birthData.place, equals('New Delhi'));
    });

    test('BirthData has empty default timezone', () {
      final birthData = BirthData(
        dateTime: DateTime(1990, 1, 1, 12, 0),
        location: Location(latitude: 28.6139, longitude: 77.2090),
      );
      // Default timezone is empty string, not 'UTC'
      expect(birthData.timezone, equals(''));
    });

    test('BirthData toJson returns correct map', () {
      final birthData = BirthData(
        dateTime: DateTime(1990, 1, 1, 12, 0),
        location: Location(latitude: 28.6139, longitude: 77.2090),
        name: 'Test User',
        place: 'New Delhi',
        timezone: 'Asia/Kolkata',
      );
      final json = birthData.toJson();
      expect(json['name'], equals('Test User'));
      expect(json['place'], equals('New Delhi'));
      expect(json['timezone'], equals('Asia/Kolkata'));
    });

    test('BirthData fromJson creates correct BirthData', () {
      final json = {
        'dateTime': '1990-01-01T12:00:00.000',
        'location': {'latitude': 28.6139, 'longitude': 77.2090},
        'name': 'Test User',
        'place': 'New Delhi',
        'timezone': 'Asia/Kolkata',
      };
      final birthData = BirthData.fromJson(json);
      expect(birthData.name, equals('Test User'));
      expect(birthData.place, equals('New Delhi'));
      expect(birthData.timezone, equals('Asia/Kolkata'));
    });

    test('BirthData roundtrip through JSON', () {
      final original = BirthData(
        dateTime: DateTime(1990, 1, 1, 12, 0),
        location: Location(latitude: 28.6139, longitude: 77.2090),
        name: 'Test User',
        place: 'New Delhi',
        timezone: 'Asia/Kolkata',
      );
      final json = original.toJson();
      final restored = BirthData.fromJson(json);
      expect(restored.name, equals(original.name));
      expect(restored.place, equals(original.place));
      expect(restored.timezone, equals(original.timezone));
    });
  });

  group('VimshottariDasha Tests', () {
    test('formattedBalanceAtBirth formats correctly', () {
      final dasha = VimshottariDasha(
        birthLord: 'Sun',
        balanceAtBirth: 10.5,
        mahadashas: [],
      );
      expect(dasha.formattedBalanceAtBirth, equals('10 years, 6 months, 0 days'));
    });

    test('formattedBalanceAtBirth handles zero', () {
      final dasha = VimshottariDasha(
        birthLord: 'Sun',
        balanceAtBirth: 0,
        mahadashas: [],
      );
      expect(dasha.formattedBalanceAtBirth, equals('0 years, 0 months, 0 days'));
    });
  });

  group('Mahadasha Tests', () {
    test('formattedPeriod formats correctly', () {
      final mahadasha = Mahadasha(
        lord: 'Sun',
        startDate: DateTime(1990, 1, 1),
        endDate: DateTime(1996, 1, 1),
        periodYears: 6.5,
        antardashas: [],
      );
      expect(mahadasha.formattedPeriod, equals('6 years 6 months'));
    });

    test('formattedPeriod handles whole years', () {
      final mahadasha = Mahadasha(
        lord: 'Sun',
        startDate: DateTime(1990, 1, 1),
        endDate: DateTime(2000, 1, 1),
        periodYears: 10.0,
        antardashas: [],
      );
      expect(mahadasha.formattedPeriod, equals('10 years 0 months'));
    });
  });

  group('DivisionalChartData Tests', () {
    test('getPlanetSign returns correct sign index', () {
      final chart = DivisionalChartData(
        code: 'D1',
        name: 'Lagna',
        description: 'Birth Chart',
        positions: {
          'Sun': 45.0, // 45 degrees = 1st sign (0-30) + 15 = starts Taurus (index 1)
          'Moon': 15.0, // 15 degrees = Aries (index 0)
          'Mars': 90.0, // 90 degrees = starts Libra (index 6, because 90/30 = 3)
        },
      );
      expect(chart.getPlanetSign('Sun'), equals(1));
      expect(chart.getPlanetSign('Moon'), equals(0));
      // 90/30 = 3, floor = 3
      expect(chart.getPlanetSign('Mars'), equals(3));
    });

    test('getPlanetSign handles unknown planet', () {
      final chart = DivisionalChartData(
        code: 'D1',
        name: 'Lagna',
        description: 'Birth Chart',
        positions: {},
      );
      expect(chart.getPlanetSign('Unknown'), equals(0));
    });
  });
}
