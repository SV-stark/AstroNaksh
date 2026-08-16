import 'package:astronaksh/core/ephemeris_manager.dart';
import 'package:astronaksh/data/models.dart';
import 'package:astronaksh/logic/rashiphal_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await EphemerisManager.ensureEphemerisData();
  });

  group('Standalone Rashifal Tests', () {
    test('RashiInfo has all 12 signs with complete metadata', () {
      expect(RashiInfo.all.length, 12);
      for (var i = 0; i < 12; i++) {
        final rashi = RashiInfo.all[i];
        expect(rashi.index, i);
        expect(rashi.name, isNotEmpty);
        expect(rashi.sanskrit, isNotEmpty);
        expect(rashi.symbol, isNotEmpty);
        expect(rashi.lord, isNotEmpty);
        expect(rashi.element, isNotEmpty);
        expect(rashi.luckyColor, isNotEmpty);
        expect(rashi.luckyNumber, greaterThan(0));
        expect(rashi.luckyDirection, isNotEmpty);
      }
    });

    test('generateDailyPredictionForSign calculates prediction for Aries', () async {
      final service = RashiphalService();
      const loc = Location(latitude: 28.6139, longitude: 77.2090);
      final date = DateTime(2026, 8, 16);

      final prediction = await service.generateDailyPredictionForSign(0, loc, date);

      expect(prediction.moonSign, isNotEmpty);
      expect(prediction.nakshatra, isNotEmpty);
      expect(prediction.tithi, isNotEmpty);
      expect(prediction.overallPrediction, isNotEmpty);
      expect(prediction.favorableScore, inInclusiveRange(0.35, 0.95));
      expect(prediction.transitContext, isNotEmpty);
      expect(prediction.auspiciousPeriods, isNotEmpty);
    });

    test('getDashboardForSign generates today, tomorrow, and 7-day overview for Scorpio', () async {
      final service = RashiphalService();
      const loc = Location(latitude: 28.6139, longitude: 77.2090);

      // Sign 7: Scorpio
      final dashboard = await service.getDashboardForSign(7, location: loc);

      expect(dashboard.today, isNotNull);
      expect(dashboard.tomorrow, isNotNull);
      expect(dashboard.weeklyOverview.length, 7);
      expect(dashboard.today.moonSign, isNotEmpty);
    });
  });
}
