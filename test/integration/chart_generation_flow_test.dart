import 'package:flutter_test/flutter_test.dart';
import 'package:astronaksh/data/models.dart';
import 'package:astronaksh/logic/custom_chart_service.dart';
import 'package:astronaksh/core/astro_utils.dart';
import 'package:astronaksh/core/svg_chart_exporter.dart';

/// Integration tests for the chart generation flow (E12).
/// Tests: input → calculate → export pipeline without requiring
/// the native ephemeris library.
void main() {
  group('Chart generation flow integration tests', () {
    test('BirthData serialization round-trip', () {
      final original = BirthData(
        dateTime: DateTime(1990, 6, 15, 14, 30),
        location: Location(latitude: 28.6139, longitude: 77.2090),
        name: 'Test Person',
        place: 'New Delhi',
        timezone: 'Asia/Kolkata',
      );

      final json = original.toJson();
      final restored = BirthData.fromJson(json);

      expect(restored.name, original.name);
      expect(restored.place, original.place);
      expect(restored.timezone, original.timezone);
      expect(restored.dateTime, original.dateTime);
      expect(restored.location.latitude, original.location.latitude);
      expect(restored.location.longitude, original.location.longitude);
    });

    test('AstroUtils sign and nakshatra lookups', () {
      expect(AstroUtils.getSignName(0), 'Aries');
      expect(AstroUtils.getSignName(11), 'Pisces');
      expect(AstroUtils.getSignName(12), 'Aries');
      expect(AstroUtils.getNakshatraName(0), 'Ashwini');
      expect(AstroUtils.getNakshatraName(26), 'Revati');
    });

    test('AstroUtils longitude to sign/nakshatra conversion', () {
      expect(AstroUtils.longitudeToSignIndex(0), 0);
      expect(AstroUtils.longitudeToSignIndex(30), 1);
      expect(AstroUtils.longitudeToSignIndex(359), 11);
      expect(AstroUtils.longitudeToNakshatraIndex(0), 0);
      expect(AstroUtils.longitudeToNakshatraIndex(13.33), 1);
    });

    test('AstroUtils ordinal formatting', () {
      expect(AstroUtils.ordinal(1), '1st');
      expect(AstroUtils.ordinal(2), '2nd');
      expect(AstroUtils.ordinal(3), '3rd');
      expect(AstroUtils.ordinal(4), '4th');
      expect(AstroUtils.ordinal(11), '11th');
      expect(AstroUtils.ordinal(21), '21st');
    });

    test('SVG export generates valid XML', () {
      final svg = SvgChartExporter.toSvg(
        planetsBySign: {
          0: ['Sun', 'Mars'],
          4: ['Moon'],
        },
        ascendantSign: 1,
        size: 500,
        title: 'Test Chart',
      );

      expect(svg, contains('<?xml version="1.0"'));
      expect(svg, contains('<svg'));
      expect(svg, contains('</svg>'));
      expect(svg, contains('Test Chart'));
      expect(svg, contains('Sun'));
      expect(svg, contains('Mars'));
      expect(svg, contains('Moon'));
    });

    test('SVG export with empty planets', () {
      final svg = SvgChartExporter.toSvg(
        planetsBySign: {},
        ascendantSign: 0,
        size: 400,
      );

      expect(svg, contains('<?xml'));
      expect(svg, contains('</svg>'));
    });

    test('KP model serialization round-trip', () {
      final kpSubLord = KPSubLord(
        starLord: 'Moon',
        subLord: 'Venus',
        subSubLord: 'Mercury',
        nakshatraIndex: 5,
        nakshatraName: 'Ardra',
      );

      final json = kpSubLord.toJson();
      final restored = KPSubLord.fromJson(json);

      expect(restored.starLord, kpSubLord.starLord);
      expect(restored.subLord, kpSubLord.subLord);
      expect(restored.nakshatraIndex, kpSubLord.nakshatraIndex);
    });

    test('YogaDosha model serialization round-trip', () {
      final yoga = BhangaResult(
        name: 'Gaja Kesari Yoga',
        description: 'Jupiter in kendra from Moon',
        isActive: true,
        strength: 85.0,
        status: 'Active',
        manifestationPeriod: '2024-2026',
        peakDashaLord: 'Jupiter',
      );

      final json = yoga.toJson();
      final restored = BhangaResult.fromJson(json);

      expect(restored.name, yoga.name);
      expect(restored.isActive, yoga.isActive);
      expect(restored.strength, yoga.strength);
      expect(restored.status, yoga.status);
    });

    test('Prediction model serialization round-trip', () {
      final prediction = DailyRashiphal(
        date: DateTime(2024, 1, 15),
        moonSign: 'Aries',
        nakshatra: 'Ashwini',
        tithi: 'Shukla Panchami',
        overallPrediction: 'Good day for new ventures',
        keyHighlights: ['Financial gain', 'Good health'],
        auspiciousPeriods: ['10:00-12:00'],
        cautions: ['Avoid arguments'],
        recommendation: 'Start important work',
        favorableScore: 0.8,
      );

      final json = prediction.toJson();
      final restored = DailyRashiphal.fromJson(json);

      expect(restored.moonSign, prediction.moonSign);
      expect(restored.favorableScore, prediction.favorableScore);
      expect(restored.keyHighlights.length, prediction.keyHighlights.length);
    });
  });
}
