import 'package:flutter_test/flutter_test.dart';
import 'package:astronaksh/core/rashiphal_rules.dart';

void main() {
  group('RashiphalRules Tests', () {
    test('Moon Sign Predictions', () {
      // Test all 12 houses
      for (int i = 1; i <= 12; i++) {
        final prediction = RashiphalRules.getMoonSignPrediction(0, i);
        expect(prediction, isNotEmpty);
        expect(prediction, isNot(contains('neutral'))); // Unless default
      }
    });

    test('Nakshatra Predictions', () {
      // Test all 27 nakshatras
      for (int i = 0; i < 27; i++) {
        final prediction = RashiphalRules.getNakshatraPrediction(i);
        expect(prediction, isNotEmpty);
      }
    });

    test('Tithi Recommendations', () {
      // Test Nanda (1)
      expect(RashiphalRules.getTithiRecommendation(1), contains('Nanda'));
      // Test Rikta (4)
      expect(RashiphalRules.getTithiRecommendation(4), contains('Rikta'));
      // Test Purna (5)
      expect(RashiphalRules.getTithiRecommendation(5), contains('Purna'));
    });

    test('Muhurta Timings', () {
      final now = DateTime.now();
      final timings = RashiphalRules.getMuhurtaTimings(now);
      expect(timings, isNotEmpty);
      expect(timings.first, contains('Abhijit'));
    });
  });
}
