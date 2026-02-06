import 'package:jyotish/jyotish.dart';

/// Ashtakavarga System Calculator
/// Calculates Bhinnashtakavarga (Individual) and Sarvashtakavarga (Total) points.
class AshtakavargaSystem {
  static AshtakavargaService? _service;

  /// Calculate Sarvashtakavarga (Total Points per Sign)
  static Map<int, int> calculateSarvashtakavarga(VedicChart chart) {
    _service ??= AshtakavargaService();
    final av = _service!.calculateAshtakavarga(chart);

    final result = <int, int>{};
    for (int i = 0; i < 12; i++) {
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
    for (int i = 0; i < 12; i++) {
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
    for (int i = 0; i < 12; i++) {
      result[i] = bav.bindus[i];
    }
    return result;
  }
}
