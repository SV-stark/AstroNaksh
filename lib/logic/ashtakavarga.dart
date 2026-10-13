import 'package:jyotish/core.dart';
import 'package:jyotish/systems.dart';

/// Ashtakavarga System Calculator
/// Calculates Bhinnashtakavarga (Individual) and Sarvashtakavarga (Total) points.
class AshtakavargaSystem {
  static AshtakavargaService? _service;

  /// Calculate Sarvashtakavarga (Total Points per Sign)
  static Map<int, int> calculateSarvashtakavarga(VedicChart chart) {
    _service ??= AshtakavargaService();
    final av = _service!.calculateAshtakavarga(chart);

    final result = <int, int>{};
    for (var i = 0; i < 12; i++) {
      result[i] = av.sarvashtakavarga.bindus[i];
    }
    return result;
  }

  /// Calculate complete Shodhya Pinda analysis
  /// Includes Trikona Shodhana, Ekadhipati Shodhana, and Pinda results.
  static ShodhyaPindaResult calculateShodhyaPinda(VedicChart chart) {
    _service ??= AshtakavargaService();
    final av = _service!.calculateAshtakavarga(chart);
    return _service!.calculateShodhyaPinda(av);
  }

  /// Calculate Pinda strength for all 12 houses.
  /// Sums bindus from all planets in each house with sign-specific multipliers.
  static Map<int, double> calculateAllHousesPinda(VedicChart chart) {
    _service ??= AshtakavargaService();
    final av = _service!.calculateAshtakavarga(chart);
    return _service!.calculateAllHousesPinda(av);
  }

  /// Calculate Sarvashtakavarga with Sodhana (Reduction) applied
  static Map<int, int> calculateSarvashtakavargaWithSodhana(VedicChart chart) {
    final shodhya = calculateShodhyaPinda(chart);
    final av = shodhya.ekadhipatiReducedAshtakavarga;

    final result = <int, int>{};
    for (var i = 0; i < 12; i++) {
      result[i] = av.sarvashtakavarga.bindus[i];
    }
    return result;
  }

  /// Calculate Bhinnashtakavarga for a specific planet
  /// Returns map of Sign Index (0-11) -> Points (0-8)
  static Map<int, int> calculateBhinnashtakavarga(
    VedicChart chart,
    String planetName,
  ) {
    _service ??= AshtakavargaService();

    // Map string name to Planet enum
    Planet? targetPlanet;
    for (final p in Planet.traditionalPlanets) {
      if (p.toString().split('.').last.toLowerCase() ==
          planetName.toLowerCase()) {
        targetPlanet = p;
        break;
      }
    }

    if (targetPlanet == null) return {};

    final av = _service!.calculateAshtakavarga(chart);
    final bav = av.bhinnashtakavarga[targetPlanet];

    if (bav == null) return {};

    final result = <int, int>{};
    for (var i = 0; i < 12; i++) {
      result[i] = bav.bindus[i];
    }
    return result;
  }

  /// Calculate Prastara Ashtakavarga (96-cell binary grid) for a specific planet.
  ///
  /// The Prastara grid shows which of the 8 contributors (Sun, Moon, Mars,
  /// Mercury, Jupiter, Venus, Saturn, Lagna) give bindus to each of the 12 signs.
  /// This is the classical Vedic method for understanding planetary contributions.
  ///
  /// Returns [PrastaraResult] with a flat 96-element Uint8List (8 rows × 12 columns).
  static PrastaraResult calculatePrastara(VedicChart chart, Planet planet) {
    _service ??= AshtakavargaService();
    return _service!.calculatePrastaraAshtakavarga(chart, planet);
  }

  /// Calculate Prastara Ashtakavarga for all 7 grahas.
  ///
  /// Returns a map of each traditional planet to its [PrastaraResult].
  static Map<Planet, PrastaraResult> calculateAllPrastara(VedicChart chart) {
    _service ??= AshtakavargaService();
    final result = <Planet, PrastaraResult>{};
    for (final planet in Planet.traditionalPlanets) {
      result[planet] = _service!.calculatePrastaraAshtakavarga(chart, planet);
    }
    return result;
  }

  /// Get human-readable contributor names for a specific sign in a Prastara grid.
  ///
  /// [prastara] — The PrastaraResult for a planet
  /// [signIndex] — Sign index 0-11 (Aries to Pisces)
  ///
  /// Returns list of contributor names (e.g., ['Sun', 'Jupiter', 'Lagna'])
  /// that contribute bindus to the given sign.
  static List<String> getPrastaraContributors(
    PrastaraResult prastara,
    int signIndex,
  ) {
    const contributorNames = [
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
      'Lagna',
    ];
    final contributors = <String>[];
    for (var point = 0; point < 8; point++) {
      if (prastara.getContribution(point, signIndex) == 1) {
        contributors.add(contributorNames[point]);
      }
    }
    return contributors;
  }

  /// Get total bindu count across all signs for a specific contributor point.
  ///
  /// [prastara] — The PrastaraResult for a planet
  /// [pointIndex] — Contributor index 0-7 (Sun=0, Moon=1, ..., Lagna=7)
  ///
  /// Returns count of signs (0-12) where this contributor gives a bindu.
  static int getContributorBinduCount(PrastaraResult prastara, int pointIndex) {
    var count = 0;
    for (var sign = 0; sign < 12; sign++) {
      if (prastara.getContribution(pointIndex, sign) == 1) {
        count++;
      }
    }
    return count;
  }

  /// Get the dominant contributor for a specific sign in a Prastara grid.
  ///
  /// Returns the name of the contributor with the most bindus in that sign,
  /// or 'None' if no bindus are present.
  static String getDominantContributor(PrastaraResult prastara, int signIndex) {
    const contributorNames = [
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
      'Lagna',
    ];
    final contributors = <String>[];
    for (var point = 0; point < 8; point++) {
      if (prastara.getContribution(point, signIndex) == 1) {
        contributors.add(contributorNames[point]);
      }
    }
    if (contributors.isEmpty) return 'None';
    return contributors.join(', ');
  }
}
