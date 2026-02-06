import 'package:jyotish/jyotish.dart';
import 'package:jyotish/src/services/strength_analysis_service.dart';
import '../data/models.dart';
import 'shadbala.dart';

/// Bhava Bala (House Strength) Calculation
/// Uses the jyotish library's StrengthAnalysisService for accurate calculations
class BhavaBala {
  static StrengthAnalysisService? _strengthService;

  /// Calculate strength of all 12 houses using library's native implementation
  static Future<Map<int, BhavaStrength>> calculateBhavaBala(
    CompleteChartData chart,
  ) async {
    _strengthService ??= StrengthAnalysisService();

    // Get Shadbala results (required by library's Bhava Bala calculation)
    final shadbalaResults = await ShadbalaCalculator.calculateDetailedShadbala(
      chart.baseChart,
    );

    // Convert ShadbalaResult to double values for library API
    final shadbalaMap = <Planet, double>{};
    shadbalaResults.forEach((planet, result) {
      shadbalaMap[planet] = result.totalBala;
    });

    // Use library's native Bhava Bala calculation
    // Returns Map<int, double> where key is house number (1-12), value is strength (0-100)
    final libraryResults = _strengthService!.getBhavaBala(
      chart: chart.baseChart,
      shadbalaResults: shadbalaMap,
    );

    // Map library results to local BhavaStrength model
    final Map<int, BhavaStrength> bhavaStrengths = {};
    for (int house = 1; house <= 12; house++) {
      final strength = libraryResults[house] ?? 50.0;
      bhavaStrengths[house] = BhavaStrength(
        house: house,
        totalStrength: strength,
        components: {'Total': strength},
        interpretation: _interpretStrength(house, strength),
      );
    }

    return bhavaStrengths;
  }

  /// Calculate Ishtaphala (auspicious fruit) for a planet
  /// Uses library's StrengthAnalysisService
  static Future<double> calculateIshtaphala(
    CompleteChartData chart,
    Planet planet,
  ) async {
    _strengthService ??= StrengthAnalysisService();

    final shadbalaResults = await ShadbalaCalculator.calculateDetailedShadbala(
      chart.baseChart,
    );

    final shadbalaStrength = shadbalaResults[planet]?.totalBala ?? 60.0;

    return _strengthService!.getIshtaphala(
      planet: planet,
      chart: chart.baseChart,
      shadbalaStrength: shadbalaStrength,
    );
  }

  /// Calculate Kashtaphala (inauspicious fruit) for a planet
  /// Uses library's StrengthAnalysisService
  static Future<double> calculateKashtaphala(
    CompleteChartData chart,
    Planet planet,
  ) async {
    _strengthService ??= StrengthAnalysisService();

    final shadbalaResults = await ShadbalaCalculator.calculateDetailedShadbala(
      chart.baseChart,
    );

    final shadbalaStrength = shadbalaResults[planet]?.totalBala ?? 60.0;

    return _strengthService!.getKashtaphala(
      planet: planet,
      chart: chart.baseChart,
      shadbalaStrength: shadbalaStrength,
    );
  }

  /// Calculate Vimshopak Bala (20-fold strength) for a planet
  /// Uses library's StrengthAnalysisService
  static VimshopakBala calculateVimshopakBala(
    CompleteChartData chart,
    Planet planet,
  ) {
    _strengthService ??= StrengthAnalysisService();

    return _strengthService!.getVimshopakBala(
      chart: chart.baseChart,
      planet: planet,
    );
  }

  /// Calculate Vimshopak Bala for all planets
  static Map<Planet, VimshopakBala> calculateAllVimshopakBala(
    CompleteChartData chart,
  ) {
    _strengthService ??= StrengthAnalysisService();

    return _strengthService!.getAllPlanetsVimshopakBala(chart.baseChart);
  }

  /// Calculate Ishtaphala and Kashtaphala for all planets
  static Future<Map<Planet, ({double ishtaphala, double kashtaphala})>>
  calculateAllPlanetFruits(CompleteChartData chart) async {
    final results = <Planet, ({double ishtaphala, double kashtaphala})>{};

    for (final planet in Planet.traditionalPlanets) {
      results[planet] = (
        ishtaphala: await calculateIshtaphala(chart, planet),
        kashtaphala: await calculateKashtaphala(chart, planet),
      );
    }

    return results;
  }

  /// Interpret house strength
  static String _interpretStrength(int house, double strength) {
    final houseName = _getHouseName(house);
    String quality;

    if (strength >= 80) {
      quality = 'Very Strong';
    } else if (strength >= 60) {
      quality = 'Strong';
    } else if (strength >= 40) {
      quality = 'Moderate';
    } else if (strength >= 20) {
      quality = 'Weak';
    } else {
      quality = 'Very Weak';
    }

    return '$houseName is $quality (${strength.toStringAsFixed(1)} units)';
  }

  static String _getHouseName(int house) {
    const names = [
      '1st House (Self)',
      '2nd House (Wealth)',
      '3rd House (Siblings)',
      '4th House (Home)',
      '5th House (Children)',
      '6th House (Health)',
      '7th House (Spouse)',
      '8th House (Longevity)',
      '9th House (Fortune)',
      '10th House (Career)',
      '11th House (Gains)',
      '12th House (Losses)',
    ];
    return names[house - 1];
  }
}

/// Bhava Strength data class (preserved for backward compatibility)
class BhavaStrength {
  final int house;
  final double totalStrength;
  final Map<String, double> components;
  final String interpretation;

  BhavaStrength({
    required this.house,
    required this.totalStrength,
    required this.components,
    required this.interpretation,
  });

  String get grade {
    if (totalStrength >= 80) return 'A';
    if (totalStrength >= 60) return 'B';
    if (totalStrength >= 40) return 'C';
    if (totalStrength >= 20) return 'D';
    return 'F';
  }
}
