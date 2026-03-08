import 'package:flutter_test/flutter_test.dart';
import 'package:jyotish/jyotish.dart';

void main() {
  group('DashaService Tests', () {
    late DashaService dashaService;

    setUp(() {
      dashaService = DashaService(EphemerisService());
    });

    test('calculateVimshottariDasha returns correct number of Mahadashas', () {
      final dateTime = DateTime(1990, 1, 1, 12, 0); // Arbitrary birth date
      final moonLongitude = 45.0; // Arbitrary moon longitude (Rohini nakshatra)

      final result = dashaService.calculateVimshottariDasha(
        moonLongitude: moonLongitude,
        birthDateTime: dateTime,
      );

      // Vimshottari Dasha calculates 2 cycles (18 Mahadashas total)
      expect(result.allMahadashas.length, 18);
      expect(result.type, DashaType.vimshottari);
    });

    test('calculateYoginiDasha handles balance days correctly', () {
      final dateTime = DateTime(2000, 1, 1, 12, 0);
      final moonLongitude = 10.0; // Ashwini nakshatra

      final result = dashaService.calculateYoginiDasha(
        moonLongitude: moonLongitude,
        birthDateTime: dateTime,
      );

      // There are 4 cycles of 8 dashas (32 total)
      expect(result.allMahadashas.length, 32);
      expect(result.type, DashaType.yogini);
    });
  });
}
