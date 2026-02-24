import 'package:jyotish/jyotish.dart';
import '../data/models.dart';

/// Retrograde Analysis Module
/// Detects retrograde planets and provides interpretation.
/// Uses the jyotish library's [Planet] enum for type-safe lookups.
class RetrogradeAnalysis {
  /// The planets that can go retrograde.
  static const _retroPlanets = [
    Planet.mercury,
    Planet.venus,
    Planet.mars,
    Planet.jupiter,
    Planet.saturn,
  ];

  /// Analyze all planets for retrograde motion.
  /// Returns a map keyed by display name (e.g. 'Mercury') for UI compatibility.
  static Map<String, RetrogradeInfo> analyzeRetrogrades(
    CompleteChartData chart,
  ) {
    final Map<String, RetrogradeInfo> analysis = {};

    for (final planet in _retroPlanets) {
      // Type-safe lookup — no string matching needed
      final planetInfo = chart.baseChart.planets[planet];
      final isRetro = planetInfo?.isRetrograde ?? false;

      analysis[planet.displayName] = RetrogradeInfo(
        planetName: planet.displayName,
        isRetrograde: isRetro,
        interpretation: _getInterpretation(planet, isRetro),
      );
    }

    return analysis;
  }

  static String _getInterpretation(Planet planet, bool isRetrograde) {
    if (!isRetrograde) return _getDirectInterpretation(planet);

    switch (planet) {
      case Planet.mercury:
        return 'Mercury retrograde: Introspective thinking, review and revision favored. '
            'Communication may require extra care. Good for editing, debugging, and '
            'revisiting past projects.';
      case Planet.venus:
        return 'Venus retrograde: Re-evaluation of relationships and values. '
            'Past connections may resurface. Time to reflect on what truly brings joy '
            'and satisfaction.';
      case Planet.mars:
        return 'Mars retrograde: Energy directed inward. Actions may feel blocked or delayed. '
            'Good time to strategize rather than execute. Avoid starting new ventures; '
            'complete ongoing ones.';
      case Planet.jupiter:
        return 'Jupiter retrograde: Inner growth and spiritual expansion emphasized. '
            'Wisdom comes from reflection rather than experience. Re-examine beliefs '
            'and philosophies.';
      case Planet.saturn:
        return 'Saturn retrograde: Internal restructuring. Karma and past lessons resurface. '
            'Time to handle unfinished responsibilities. Builds inner discipline and maturity.';
      default:
        return 'Retrograde motion indicates internalized energy and karmic review.';
    }
  }

  static String _getDirectInterpretation(Planet planet) {
    switch (planet) {
      case Planet.mercury:
        return 'Mercury direct: Clear communication, smooth transactions, and '
            'effective learning.';
      case Planet.venus:
        return 'Venus direct: Harmonious relationships, artistic expression, and '
            'enjoyment of pleasures.';
      case Planet.mars:
        return 'Mars direct: Assertive action, courage, and forward momentum in pursuits.';
      case Planet.jupiter:
        return 'Jupiter direct: Expansion through external experiences, optimism, '
            'and growth opportunities.';
      case Planet.saturn:
        return 'Saturn direct: External discipline, structured progress, and '
            'tangible achievements.';
      default:
        return 'Direct motion indicates outward expression of planetary energy.';
    }
  }

  /// Get the approximate retrograde frequency note.
  /// Accepts a planet display name string for UI compatibility (e.g. 'Mercury').
  static String getRetrogradeFrequency(String planetName) {
    switch (planetName) {
      case 'Mercury':
        return '3-4 times per year, ~3 weeks each';
      case 'Venus':
        return 'Every 18 months, ~6 weeks';
      case 'Mars':
        return 'Every 2 years, ~2.5 months';
      case 'Jupiter':
        return 'Every 13 months, ~4 months';
      case 'Saturn':
        return 'Every 12.5 months, ~4.5 months';
      default:
        return 'Varies by planet';
    }
  }
}

/// Data class for retrograde information
class RetrogradeInfo {
  final String planetName;
  final bool isRetrograde;
  final String interpretation;

  RetrogradeInfo({
    required this.planetName,
    required this.isRetrograde,
    required this.interpretation,
  });
}
