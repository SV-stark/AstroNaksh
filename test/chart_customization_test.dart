import 'package:flutter_test/flutter_test.dart';
import 'package:astronaksh/core/chart_customization.dart';

void main() {
  group('ChartCustomization Tests', () {
    test('default constructor creates instance with default values', () {
      final settings = ChartCustomization();
      
      expect(settings.chartStyle, equals(ChartStyle.northIndian));
      expect(settings.colorScheme, equals(ColorScheme.classic));
      expect(settings.showHouses, isTrue);
      expect(settings.showSigns, isTrue);
      expect(settings.showDegrees, isTrue);
      expect(settings.showNakshatras, isFalse);
    });

    test('resetToDefaults restores all defaults', () {
      final settings = ChartCustomization();
      
      // Modify some values
      settings.chartStyle = ChartStyle.western;
      settings.colorScheme = ColorScheme.night;
      settings.showHouses = false;
      
      // Reset
      settings.resetToDefaults();
      
      expect(settings.chartStyle, equals(ChartStyle.northIndian));
      expect(settings.colorScheme, equals(ColorScheme.classic));
      expect(settings.showHouses, isTrue);
    });

    test('toJson creates valid JSON map', () {
      final settings = ChartCustomization();
      final json = settings.toJson();
      
      expect(json, isA<Map<String, dynamic>>());
      expect(json.containsKey('chartStyle'), isTrue);
      expect(json.containsKey('colorScheme'), isTrue);
      expect(json.containsKey('showHouses'), isTrue);
    });

    test('fromJson creates instance from JSON map', () {
      final json = {
        'chartStyle': 'ChartStyle.southIndian',
        'colorScheme': 'ColorScheme.vedic',
        'showHouses': false,
        'showSigns': false,
        'showDegrees': true,
        'showNakshatras': true,
      };
      
      final settings = ChartCustomization.fromJson(json);
      
      expect(settings.chartStyle, equals(ChartStyle.southIndian));
      expect(settings.colorScheme, equals(ColorScheme.vedic));
      expect(settings.showHouses, isFalse);
      expect(settings.showSigns, isFalse);
    });

    test('fromJson uses defaults for missing keys', () {
      final json = <String, dynamic>{};
      
      final settings = ChartCustomization.fromJson(json);
      
      expect(settings.chartStyle, equals(ChartStyle.northIndian));
      expect(settings.colorScheme, equals(ColorScheme.classic));
    });

    test('toJson and fromJson roundtrip preserves values', () {
      final original = ChartCustomization();
      original.chartStyle = ChartStyle.eastIndian;
      original.colorScheme = ColorScheme.oled;
      original.showNakshatras = true;
      original.dashaYearsToShow = 25;
      
      final json = original.toJson();
      final restored = ChartCustomization.fromJson(json);
      
      expect(restored.chartStyle, equals(original.chartStyle));
      expect(restored.colorScheme, equals(original.colorScheme));
      expect(restored.showNakshatras, equals(original.showNakshatras));
      expect(restored.dashaYearsToShow, equals(original.dashaYearsToShow));
    });
  });

  group('ChartPresets Tests', () {
    test('beginner preset has expected values', () {
      final preset = ChartPresets.beginner;
      
      expect(preset.chartStyle, equals(ChartStyle.northIndian));
      expect(preset.colorScheme, equals(ColorScheme.modern));
      expect(preset.showHouses, isTrue);
      expect(preset.showDegrees, isFalse);
      expect(preset.showNakshatras, isFalse);
    });

    test('professional preset has expected values', () {
      final preset = ChartPresets.professional;
      
      expect(preset.chartStyle, equals(ChartStyle.northIndian));
      expect(preset.colorScheme, equals(ColorScheme.vedic));
      expect(preset.showDegrees, isTrue);
      expect(preset.showNakshatras, isTrue);
      expect(preset.dashaYearsToShow, equals(30));
    });

    test('minimal preset has expected values', () {
      final preset = ChartPresets.minimal;
      
      expect(preset.chartStyle, equals(ChartStyle.southIndian));
      expect(preset.colorScheme, equals(ColorScheme.print));
      expect(preset.showSigns, isFalse);
      expect(preset.showDegrees, isFalse);
      expect(preset.showRetrograde, isFalse);
    });

    test('printFriendly preset has expected values', () {
      final preset = ChartPresets.printFriendly;
      
      expect(preset.colorScheme, equals(ColorScheme.print));
      expect(preset.showDegrees, isTrue);
    });
  });

  group('ChartColors Tests', () {
    test('classic colors are defined correctly', () {
      final colors = ColorScheme.classic.colors;
      
      expect(colors.background, isNotNull);
      expect(colors.houseBorder, isNotNull);
      expect(colors.houseFill, isNotNull);
      expect(colors.planetText, isNotNull);
    });

    test('all color schemes have valid colors', () {
      for (final scheme in ColorScheme.values) {
        final colors = scheme.colors;
        expect(colors.background, isNotNull);
        expect(colors.houseBorder, isNotNull);
        expect(colors.houseFill, isNotNull);
        expect(colors.planetText, isNotNull);
        expect(colors.retrogradeIndicator, isNotNull);
        expect(colors.ascendantMarker, isNotNull);
        expect(colors.beneficPlanet, isNotNull);
        expect(colors.maleficPlanet, isNotNull);
        expect(colors.neutralPlanet, isNotNull);
      }
    });
  });

  group('Enum Values Tests', () {
    test('ChartStyle has expected values', () {
      expect(ChartStyle.values.length, equals(4));
      expect(ChartStyle.values, contains(ChartStyle.northIndian));
      expect(ChartStyle.values, contains(ChartStyle.southIndian));
      expect(ChartStyle.values, contains(ChartStyle.eastIndian));
      expect(ChartStyle.values, contains(ChartStyle.western));
    });

    test('ColorScheme has expected values', () {
      expect(ColorScheme.values.length, equals(6));
      expect(ColorScheme.values, contains(ColorScheme.classic));
      expect(ColorScheme.values, contains(ColorScheme.modern));
      expect(ColorScheme.values, contains(ColorScheme.vedic));
      expect(ColorScheme.values, contains(ColorScheme.print));
      expect(ColorScheme.values, contains(ColorScheme.night));
      expect(ColorScheme.values, contains(ColorScheme.oled));
    });

    test('PlanetSize has expected values', () {
      expect(PlanetSize.values.length, equals(3));
      expect(PlanetSize.values, contains(PlanetSize.small));
      expect(PlanetSize.values, contains(PlanetSize.medium));
      expect(PlanetSize.values, contains(PlanetSize.large));
    });

    test('HouseSystem has expected values', () {
      expect(HouseSystem.values.length, equals(7));
    });
  });
}
