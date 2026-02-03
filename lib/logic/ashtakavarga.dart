import '../data/models.dart'; // Reuse helper methods

/// Ashtakavarga System Calculator
/// Calculates Bhinnashtakavarga (Individual) and Sarvashtakavarga (Total) points.
class AshtakavargaSystem {
  /// Calculate Sarvashtakavarga (Total Points per Sign)
  static Map<int, int> calculateSarvashtakavarga(CompleteChartData chart) {
    Map<int, int> sarva = {};
    for (int i = 0; i < 12; i++) {
      sarva[i] = 0;
    }

    // Calculate Bhinnashtakavarga for each planet and sum up
    for (var planet in [
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
    ]) {
      Map<int, int> bhinna = calculateBhinnashtakavarga(chart, planet);
      bhinna.forEach((sign, points) {
        sarva[sign] = (sarva[sign] ?? 0) + points;
      });
    }
    return sarva;
  }

  /// Calculate Sarvashtakavarga with Sodhana (Reduction) applied
  static Map<int, int> calculateSarvashtakavargaWithSodhana(
    CompleteChartData chart,
  ) {
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
    CompleteChartData chart,
    String planet,
  ) {
    Map<int, int> points = {};
    for (int i = 0; i < 12; i++) {
      points[i] = 0;
    }

    // Get positions (Sign indices 0-11) of all 7 planets + Ascendant
    Map<String, int> positions = _getPlanetSignPositions(chart);

    // Apply rules based on the target planet (the one whose AV we are calculating)
    // Rules specify benefic places from: Sun, Moon, Mars, Mercury, Jupiter, Venus, Saturn, Ascendant

    switch (planet) {
      case 'Sun':
        _applySunRules(points, positions);
        break;
      case 'Moon':
        _applyMoonRules(points, positions);
        break;
      case 'Mars':
        _applyMarsRules(points, positions);
        break;
      case 'Mercury':
        _applyMercuryRules(points, positions);
        break;
      case 'Jupiter':
        _applyJupiterRules(points, positions);
        break;
      case 'Venus':
        _applyVenusRules(points, positions);
        break;
      case 'Saturn':
        _applySaturnRules(points, positions);
        break;
    }

    return points;
  }

  // Helper to get sign positions of all planets
  static Map<String, int> _getPlanetSignPositions(CompleteChartData chart) {
    Map<String, int> pos = {};
    for (var p in [
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
    ]) {
      double long = 0.0;
      // find longitude
      for (final entry in chart.baseChart.planets.entries) {
        if (entry.key.toString().split('.').last == p) {
          long = entry.value.longitude;
          break;
        }
      }
      pos[p] = (long / 30).floor();
    }

    // Ascendant
    double asc = 0.0;
    if (chart.baseChart.houses.cusps.isNotEmpty) {
      asc = chart.baseChart.houses.cusps[0];
    }
    pos['Ascendant'] = (asc / 30).floor();

    return pos;
  }

  // Helper to add points from a reference planet
  static void _addPoints(
    Map<int, int> points,
    int referenceSign,
    List<int> houses,
  ) {
    for (int house in houses) {
      // house is 1-based index from reference sign
      int targetSign = (referenceSign + (house - 1)) % 12;
      points[targetSign] = (points[targetSign] ?? 0) + 1;
    }
  }

  // --- Rules Implementation ---
  // Source: standard texts (e.g., BPHS)

  static void _applySunRules(Map<int, int> points, Map<String, int> pos) {
    // Sun's Bhinnashtakavarga
    _addPoints(points, pos['Sun']!, [1, 2, 4, 7, 8, 9, 10, 11]);
    _addPoints(points, pos['Moon']!, [3, 6, 10, 11]);
    _addPoints(points, pos['Mars']!, [1, 2, 4, 7, 8, 9, 10, 11]);
    _addPoints(points, pos['Mercury']!, [3, 5, 6, 9, 10, 11, 12]);
    _addPoints(points, pos['Jupiter']!, [5, 6, 9, 11]);
    _addPoints(points, pos['Venus']!, [6, 7, 12]);
    _addPoints(points, pos['Saturn']!, [1, 2, 4, 7, 8, 9, 10, 11]);
    _addPoints(points, pos['Ascendant']!, [3, 4, 6, 10, 11, 12]);
  }

  static void _applyMoonRules(Map<int, int> points, Map<String, int> pos) {
    _addPoints(points, pos['Sun']!, [3, 6, 7, 8, 10, 11]);
    _addPoints(points, pos['Moon']!, [1, 3, 6, 7, 10, 11]);
    _addPoints(points, pos['Mars']!, [2, 3, 5, 6, 9, 10, 11]);
    _addPoints(points, pos['Mercury']!, [1, 3, 4, 5, 7, 8, 10, 11]);
    _addPoints(points, pos['Jupiter']!, [1, 4, 7, 8, 10, 11, 12]);
    _addPoints(points, pos['Venus']!, [3, 4, 5, 7, 9, 10, 11]);
    _addPoints(points, pos['Saturn']!, [3, 5, 6, 11]);
    _addPoints(points, pos['Ascendant']!, [3, 6, 10, 11]);
  }

  static void _applyMarsRules(Map<int, int> points, Map<String, int> pos) {
    _addPoints(points, pos['Sun']!, [3, 5, 6, 10, 11]);
    _addPoints(points, pos['Moon']!, [3, 6, 11]);
    _addPoints(points, pos['Mars']!, [1, 2, 4, 7, 8, 10, 11]);
    _addPoints(points, pos['Mercury']!, [3, 5, 6, 11]);
    _addPoints(points, pos['Jupiter']!, [6, 10, 11, 12]);
    _addPoints(points, pos['Venus']!, [6, 8, 11, 12]);
    _addPoints(points, pos['Saturn']!, [1, 4, 7, 8, 9, 10, 11]);
    _addPoints(points, pos['Ascendant']!, [1, 3, 6, 10, 11]);
  }

  static void _applyMercuryRules(Map<int, int> points, Map<String, int> pos) {
    _addPoints(points, pos['Sun']!, [5, 6, 9, 11, 12]);
    _addPoints(points, pos['Moon']!, [2, 4, 6, 8, 10, 11]);
    _addPoints(points, pos['Mars']!, [1, 2, 4, 7, 8, 9, 10, 11]);
    _addPoints(points, pos['Mercury']!, [1, 3, 5, 6, 9, 10, 11, 12]);
    _addPoints(points, pos['Jupiter']!, [6, 8, 11, 12]);
    _addPoints(points, pos['Venus']!, [1, 2, 3, 4, 5, 8, 9, 11]);
    _addPoints(points, pos['Saturn']!, [1, 2, 4, 7, 8, 9, 10, 11]);
    _addPoints(points, pos['Ascendant']!, [1, 2, 4, 6, 8, 10, 11]);
  }

  static void _applyJupiterRules(Map<int, int> points, Map<String, int> pos) {
    _addPoints(points, pos['Sun']!, [1, 2, 3, 4, 7, 8, 9, 10, 11]);
    _addPoints(points, pos['Moon']!, [2, 5, 7, 9, 11]);
    _addPoints(points, pos['Mars']!, [1, 2, 4, 7, 8, 10, 11]);
    _addPoints(points, pos['Mercury']!, [1, 2, 4, 5, 6, 9, 10, 11]);
    _addPoints(points, pos['Jupiter']!, [1, 2, 3, 4, 7, 8, 10, 11]);
    _addPoints(points, pos['Venus']!, [2, 5, 6, 9, 10, 11]);
    _addPoints(points, pos['Saturn']!, [3, 5, 6, 12]);
    _addPoints(points, pos['Ascendant']!, [1, 2, 4, 5, 6, 7, 9, 10, 11]);
  }

  static void _applyVenusRules(Map<int, int> points, Map<String, int> pos) {
    _addPoints(points, pos['Sun']!, [8, 11, 12]);
    _addPoints(points, pos['Moon']!, [1, 2, 3, 4, 5, 8, 9, 11, 12]);
    _addPoints(points, pos['Mars']!, [3, 4, 5, 8, 9, 11, 12]);
    _addPoints(points, pos['Mercury']!, [3, 5, 6, 9, 11]);
    _addPoints(points, pos['Jupiter']!, [5, 8, 9, 10, 11]);
    _addPoints(points, pos['Venus']!, [1, 2, 3, 4, 5, 8, 9, 10, 11]);
    _addPoints(points, pos['Saturn']!, [3, 4, 5, 8, 9, 10, 11]);
    _addPoints(points, pos['Ascendant']!, [1, 2, 3, 4, 5, 8, 9, 11]);
  }

  static void _applySaturnRules(Map<int, int> points, Map<String, int> pos) {
    _addPoints(points, pos['Sun']!, [1, 2, 4, 7, 8, 10, 11]);
    _addPoints(points, pos['Moon']!, [3, 6, 11]);
    _addPoints(points, pos['Mars']!, [3, 5, 6, 10, 11, 12]);
    _addPoints(points, pos['Mercury']!, [6, 8, 9, 10, 11, 12]);
    _addPoints(points, pos['Jupiter']!, [5, 6, 11, 12]);
    _addPoints(points, pos['Venus']!, [6, 11, 12]);
    _addPoints(points, pos['Saturn']!, [3, 5, 6, 11]);
    _addPoints(points, pos['Ascendant']!, [1, 3, 4, 6, 10, 11]);
  }
}
