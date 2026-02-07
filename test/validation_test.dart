import 'package:flutter_test/flutter_test.dart';
import 'package:astronaksh/core/ayanamsa_calculator.dart';

/// Validation Tests against known astronomical values
void main() {
  group('Panchang Validation', () {
    test('Validate Lahiri Ayanamsa for J2000', () async {
      // Date: January 1, 2000, 12:00 UTC
      // Approximate Lahiri Ayanamsa: ~23° 51'
      // Reference: Swiss Eph or standard calculations

      final date = DateTime.utc(2000, 1, 1, 12, 0);
      final ayanamsa = await AyanamsaCalculator.calculate('Lahiri', date);

      // 23 degrees 51 minutes = 23 + 51/60 = 23.85 degrees
      // Allowing a small tolerance because exact models vary slightly (True vs Mean etc)
      expect(
        ayanamsa,
        closeTo(23.85, 0.1),
        reason: 'Lahiri Ayanamsa for J2000 should be approx 23.85°',
      );
    });

    test('Validate Ayanamsa values increase with time', () async {
      final date1 = DateTime.utc(1900, 1, 1);
      final date2 = DateTime.utc(2000, 1, 1);

      final val1 = await AyanamsaCalculator.calculate('Lahiri', date1);
      final val2 = await AyanamsaCalculator.calculate('Lahiri', date2);

      // Precession moves backwards, so Ayanamsa (difference between Sayana and Nirayana) increases.
      expect(
        val2,
        greaterThan(val1),
        reason: 'Ayanamsa should increase over time due to precession',
      );

      // Difference over 100 years is approx 1.4 degrees (50 arcsec/year * 100 / 3600)
      // 50 * 100 = 5000 arcsec = 1.38 degrees
      final diff = val2 - val1;
      expect(
        diff,
        closeTo(1.39, 0.1),
        reason: 'Precession for 100 years should be approx 1.4°',
      );
    });
  });
}
