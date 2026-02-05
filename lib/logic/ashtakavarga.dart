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

  /// Calculate Sarvashtakavarga with Sodhana (Reduction) applied
  static Map<int, int> calculateSarvashtakavargaWithSodhana(VedicChart chart) {
    Map<int, int> sarva = calculateSarvashtakavarga(chart);

    // Apply Trikona Sodhana
    sarva = applyTrikonaSodhana(sarva);

    // Apply Ekadhipatya Sodhana
    sarva = applyEkadhipatyaSodhana(sarva);

    return sarva;
  }

  /// Trikona Sodhana - Reduce trinal signs by minimum value
  static Map<int, int> applyTrikonaSodhana(Map<int, int> sarva) {
    Map<int, int> result = Map.from(sarva);

    // For each fire trine (Aries, Leo, Sag: 0, 4, 8)
    _reduceTrine(result, [0, 4, 8]);

    // Earth trine (Taurus, Virgo, Cap: 1, 5, 9)
    _reduceTrine(result, [1, 5, 9]);

    // Air trine (Gemini, Libra, Aquarius: 2, 6, 10)
    _reduceTrine(result, [2, 6, 10]);

    // Water trine (Cancer, Scorpio, Pisces: 3, 7, 11)
    _reduceTrine(result, [3, 7, 11]);

    return result;
  }

  static void _reduceTrine(Map<int, int> sarva, List<int> signs) {
    // Find minimum points in the trine
    int minPoints = signs
        .map((s) => sarva[s] ?? 0)
        .reduce((a, b) => a < b ? a : b);

    // Subtract minimum from each sign in the trine
    for (var sign in signs) {
      sarva[sign] = (sarva[sign] ?? 0) - minPoints;
    }
  }

  /// Ekadhipatya Sodhana - Reduce signs with same lord
  static Map<int, int> applyEkadhipatyaSodhana(Map<int, int> sarva) {
    Map<int, int> result = Map.from(sarva);

    // Pairs of signs with same lord
    final pairs = [
      [0, 7], // Mars: Aries, Scorpio
      [1, 6], // Venus: Taurus, Libra
      [2, 5], // Mercury: Gemini, Virgo
      [8, 11], // Jupiter: Sagittarius, Pisces
      [9, 10], // Saturn: Capricorn, Aquarius
      // Sun (Leo) and Moon (Cancer) have only one sign each
    ];

    for (var pair in pairs) {
      int minPoints = [
        result[pair[0]]!,
        result[pair[1]]!,
      ].reduce((a, b) => a < b ? a : b);

      result[pair[0]] = result[pair[0]]! - minPoints;
      result[pair[1]] = result[pair[1]]! - minPoints;
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
