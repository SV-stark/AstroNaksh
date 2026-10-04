import 'package:astronaksh/core/chart_customization.dart';
import 'package:astronaksh/data/models/location.dart';
import 'package:astronaksh/ui/chart/chart_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartCustomization.fromJson hardening', () {
    test('falls back to defaults instead of throwing on wrong types', () {
      final settings = ChartCustomization.fromJson({
        'showDegrees': 'yes',
        'dashaYearsToShow': 'twenty',
        'transitDaysToShow': 100000,
        'chartStyle': 42,
        'pdfPageMargins': 'gigantic',
        'webdavUrl': 7,
      });

      expect(settings.showDegrees, isTrue); // fallback, not the string 'yes'
      expect(settings.dashaYearsToShow, 20);
      expect(settings.chartStyle, ChartStyle.northIndian);
      expect(settings.pdfPageMargins, 'medium');
      expect(settings.webdavUrl, isEmpty);
    });

    test('clamps numeric settings to the slider range', () {
      final low = ChartCustomization.fromJson({
        'dashaYearsToShow': -10,
        'transitDaysToShow': 1,
      });
      expect(low.dashaYearsToShow, ChartCustomization.minDashaYears);
      expect(low.transitDaysToShow, ChartCustomization.minTransitDays);

      final high = ChartCustomization.fromJson({
        'dashaYearsToShow': 9999,
        'transitDaysToShow': 9999,
      });
      expect(high.dashaYearsToShow, ChartCustomization.maxDashaYears);
      expect(high.transitDaysToShow, ChartCustomization.maxTransitDays);
    });

    test('one bad field no longer wipes every other setting', () {
      final original = ChartCustomization()
        ..showRetrograde = false
        ..showNakshatras = true
        ..webdavUrl = 'https://dav.example.com'
        ..webdavUsername = 'user';

      final round = ChartCustomization.fromJson({
        ...original.toJson(),
        'showDegrees': <String>['not', 'a', 'bool'],
      });

      expect(round.showRetrograde, isFalse);
      expect(round.showNakshatras, isTrue);
      expect(round.webdavUrl, 'https://dav.example.com');
      expect(round.webdavUsername, 'user');
    });
  });

  group('ChartHelpers.formatLabel', () {
    ChartCustomization settingsWith({
      bool degrees = false,
      bool nakshatras = false,
      bool retrograde = false,
      bool combust = false,
      bool dignity = false,
    }) {
      return ChartCustomization()
        ..showDegrees = degrees
        ..showNakshatras = nakshatras
        ..showRetrograde = retrograde
        ..showCombust = combust
        ..showExaltedDebilitated = dignity;
    }

    String label(
      ChartCustomization settings, {
      double longitude = 95.5,
      bool isRetrograde = false,
      double? sunLongitude,
      String abbreviation = 'Mo',
    }) {
      return ChartHelpers.formatLabel(
        label: abbreviation,
        longitude: longitude,
        isRetrograde: isRetrograde,
        settings: settings,
        sunLongitude: sunLongitude,
      );
    }

    test('hides the retrograde marker when the setting is off', () {
      expect(
        label(settingsWith(), isRetrograde: true, abbreviation: 'Sa'),
        'Sa',
      );
      expect(
        label(
          settingsWith(retrograde: true),
          isRetrograde: true,
          abbreviation: 'Sa',
        ),
        'Sa(R)',
      );
    });

    test('renders degrees within the sign when enabled', () {
      // 95.5 deg = Taurus 5 deg 30'.
      expect(label(settingsWith(degrees: true)), "Mo 5\u00b030'");
    });

    test('renders the nakshatra abbreviation when enabled', () {
      // 95.5 deg falls in Pushya, the 8th nakshatra (index 7).
      expect(label(settingsWith(nakshatras: true)), 'Mo Pus');
    });

    test('marks exaltation and debilitation', () {
      // Moon is exalted in Taurus (sign index 1) and debilitated in Scorpio
      // (sign index 7).
      expect(label(settingsWith(dignity: true), longitude: 45), 'MoEx');
      expect(label(settingsWith(dignity: true), longitude: 225), 'MoDeb');
      // Libra is neither.
      expect(label(settingsWith(dignity: true), longitude: 195), 'Mo');
    });

    test(
      'marks combustion only when enabled and never for retrograde bodies',
      () {
        expect(
          label(settingsWith(), longitude: 100, sunLongitude: 95),
          isNot(contains('*')),
        );
        expect(
          label(settingsWith(combust: true), longitude: 100, sunLongitude: 95),
          contains('*'),
        );
        expect(
          label(
            settingsWith(combust: true),
            longitude: 100,
            isRetrograde: true,
            sunLongitude: 95,
          ),
          isNot(contains('*')),
        );
      },
    );

    test('tolerates a null sun longitude', () {
      expect(() => label(settingsWith(combust: true)), returnsNormally);
    });
  });

  group('BirthData JSON round-trip', () {
    test('nested location survives serialisation', () {
      final birth = BirthData(
        dateTime: DateTime(1990, 5, 15, 10, 30),
        location: const Location(latitude: 19.076, longitude: 72.8777),
        name: 'Test',
        place: 'Mumbai',
        timezone: 'Asia/Kolkata',
      );

      final decoded = BirthData.fromJson(birth.toJson());

      expect(decoded.location.latitude, birth.location.latitude);
      expect(decoded.location.longitude, birth.location.longitude);
      expect(decoded.dateTime, birth.dateTime);
      expect(decoded.name, 'Test');
      expect(decoded.place, 'Mumbai');
      expect(decoded.timezone, 'Asia/Kolkata');
    });
  });
}
