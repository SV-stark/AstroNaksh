import '../data/models.dart';

/// Shadbala (Six-Fold Strength) Calculator
/// Calculates the total strength of planets to determine their potency.
class ShadbalaCalculator {
  /// Calculate complete Shadbala for all planets
  static Map<String, double> calculateShadbala(CompleteChartData chartData) {
    Map<String, double> shadbala = {};

    // 1. Sthana Bala (Positional Strength)
    Map<String, double> sthanaBala = _calculateSthanaBala(chartData);

    // 2. Dig Bala (Directional Strength)
    Map<String, double> digBala = _calculateDigBala(chartData);

    // 3. Kaala Bala (Temporal Strength)
    Map<String, double> kaalaBala = _calculateKaalaBala(chartData);

    // 4. Chesta Bala (Motional Strength)
    Map<String, double> chestaBala = _calculateChestaBala(chartData);

    // 5. Naisargika Bala (Natural Strength)
    Map<String, double> naisargikaBala = _getNaisargikaBala();

    // 6. Drik Bala (Aspectual Strength)
    Map<String, double> drikBala = _calculateDrikBala(chartData);

    // Summation
    sthanaBala.forEach((planet, strength) {
      shadbala[planet] =
          strength +
          (digBala[planet] ?? 0) +
          (kaalaBala[planet] ?? 0) +
          (chestaBala[planet] ?? 0) +
          (naisargikaBala[planet] ?? 0) +
          (drikBala[planet] ?? 0);
    });

    return shadbala;
  }

  // --- 1. Sthana Bala (Positional Strength) ---
  // Components: Uchcha (Exaltation), Kendra (Angle), Saptavargaja, Ojayugmarasyamsa, Drekkan
  static Map<String, double> _calculateSthanaBala(CompleteChartData chart) {
    Map<String, double> bala = {};

    // Deep debilitation points (180 opposite to exaltation)
    // Sun: 10 Ari -> 10 Lib (190)
    // Moon: 3 Tau -> 3 Sco (213)
    // Mars: 28 Cap -> 28 Can (118)
    // Merc: 15 Vir -> 15 Pis (345)
    // Jup: 5 Can -> 5 Cap (275)
    // Ven: 27 Pis -> 27 Vir (177)
    // Sat: 20 Lib -> 20 Ari (20)
    final Map<String, double> debilitationPoints = {
      'Sun': 190.0,
      'Moon': 213.0,
      'Mars': 118.0,
      'Mercury': 345.0,
      'Jupiter': 275.0,
      'Venus': 177.0,
      'Saturn': 20.0,
    };

    for (var planet in [
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
    ]) {
      double total = 0.0;
      double planetLong = _getPlanetLongitude(chart, planet);

      // A. Uchcha Bala (Exaltation Strength)
      // Distance from debilitation point
      double dist = (planetLong - debilitationPoints[planet]!).abs();
      if (dist > 180) dist = 360 - dist;
      total += dist / 3.0; // Max 60 units

      // B. Kendra Bala (House Position Strength)
      int house = _getHousePlacement(chart, planetLong);
      if ([1, 4, 7, 10].contains(house)) {
        total += 60.0;
      } else if ([2, 5, 8, 11].contains(house)) {
        total += 30.0;
      } else {
        total += 15.0;
      }

      // C. Saptavargaja Bala (Seven Divisional Charts Strength)
      total += _calculateSaptavargajaBala(chart, planet);

      // D. Ojayugmarasyamsa Bala (Odd/Even Sign Strength)
      total += _calculateOjayugmarasyamsaBala(planet, planetLong);

      // E. Drekkan Bala (Drekkana Strength)
      total += _calculateDrekkanaStrength(chart, planet, planetLong);

      bala[planet] = total;
    }
    return bala;
  }

  // Helper to find house placement (1-12)
  static int _getHousePlacement(CompleteChartData chart, double longitude) {
    // If we have house cusps
    if (chart.baseChart.houses.cusps.isNotEmpty) {
      // Logic for Placidus/KP or Equal houses using cusps
      // Simple fallback: Sign based relative to Ascendant Sign
      // But typically Sthana Bala uses Rashi chart position

      // Let's use simple Sign based for now (Rashi Chart logic for Sthana Bala generally)
      // House = (PlanetSign - AscendantSign) + 1
      double asc = chart.baseChart.houses.cusps[0];
      int ascSign = (asc / 30).floor();
      int planetSign = (longitude / 30).floor();

      int house = (planetSign - ascSign) + 1;
      if (house <= 0) house += 12;
      return house;
    }
    return 1; // Default
  }

  // --- 2. Dig Bala (Directional Strength) ---
  static Map<String, double> _calculateDigBala(CompleteChartData chart) {
    Map<String, double> bala = {};

    // Attempt to get ascendant from house cusps
    double ascendant = 0.0;
    try {
      if (chart.baseChart.houses.cusps.isNotEmpty) {
        ascendant = chart.baseChart.houses.cusps[0];
      }
    } catch (e) {
      // Fallback if needed
    }

    // Zero strength points (relative to House numbers, mapped to angles)
    // Jupiter/Mercury: Zero in 7th (Descendant) = Asc + 180
    // Sun/Mars: Zero in 4th (IC) = Asc + 90
    // Saturn: Zero in 1st (Lagna) = Asc
    // Moon/Venus: Zero in 10th (MC) = Asc + 270

    for (var planet in [
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
    ]) {
      double planetLong = _getPlanetLongitude(chart, planet);
      double zeroPoint = 0.0;

      switch (planet) {
        case 'Jupiter':
        case 'Mercury':
          zeroPoint = _normalizeAngle(ascendant + 180); // Zero in 7th
          break;
        case 'Sun':
        case 'Mars':
          zeroPoint = _normalizeAngle(ascendant + 90); // Zero in 4th
          break;
        case 'Saturn':
          zeroPoint = ascendant; // Zero in 1st
          break;
        case 'Moon':
        case 'Venus':
          zeroPoint = _normalizeAngle(ascendant + 270); // Zero in 10th
          break;
      }

      // Calculate arc distance from zero point
      double dist = (planetLong - zeroPoint).abs();
      if (dist > 180) dist = 360 - dist;

      // Strength = Arc * 60 / 180 = Arc / 3
      bala[planet] = dist / 3.0;
    }

    return bala;
  }

  static double _getPlanetLongitude(
    CompleteChartData chart,
    String planetName,
  ) {
    for (final entry in chart.baseChart.planets.entries) {
      // Compare enum names or string representations
      if (entry.key.toString().split('.').last == planetName) {
        return entry.value.longitude;
      }
    }
    return 0.0;
  }

  static double _normalizeAngle(double angle) {
    var a = angle % 360;
    if (a < 0) a += 360;
    return a;
  }

  // --- 3. Kaala Bala (Temporal Strength) ---
  static Map<String, double> _calculateKaalaBala(CompleteChartData chart) {
    Map<String, double> bala = {};

    double sunLong = _getPlanetLongitude(chart, 'Sun');
    double moonLong = _getPlanetLongitude(chart, 'Moon');

    for (var planet in [
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
    ]) {
      double total = 0.0;

      // A. Natonnata Bala (Day/Night Strength)
      total += _calculateNatonnata(planet, sunLong);

      // B. Paksha Bala (Lunar Fortnight Strength)
      total += _calculatePaksha(planet, sunLong, moonLong);

      // C. Tribhaga Bala (Day/Night Division)
      total += _calculateTribhaga(planet, chart);

      // D. Ayana Bala (Solstice Strength)
      total += _calculateAyana(planet, sunLong);

      // E. Hora Bala (Hour Lord)
      total += _calculateHora(planet, chart);

      bala[planet] = total;
    }
    return bala;
  }

  static double _calculateNatonnata(String planet, double sunLong) {
    // Benefics strong at night, malefics during day
    // Based on Sun's position below horizon (4th-10th house arc)
    // Simplified: Use Sun's distance from IC (90 deg from Asc)
    // Night planets: Moon, Venus, Jupiter, Mercury
    // Day planets: Sun, Mars, Saturn

    // Sun at 180 from Asc = fully night, at 0/360 = fully day
    // Simplified formula: benefics get strength when Sun is in 4th-10th houses
    double icAngle = 90.0; // Simplified IC position
    double distFromIC = (sunLong - icAngle).abs();
    if (distFromIC > 180) distFromIC = 360 - distFromIC;

    bool isBenefic = ['Moon', 'Venus', 'Jupiter'].contains(planet);
    bool isNight = distFromIC < 90; // Sun below horizon

    if (planet == 'Mercury') return 60.0; // Always strong
    if (isBenefic && isNight) return 60.0;
    if (!isBenefic && !isNight) return 60.0;
    return 0.0;
  }

  static double _calculatePaksha(
    String planet,
    double sunLong,
    double moonLong,
  ) {
    // Waxing Moon: Benefics strong, Waning: Malefics strong
    double elongation = (moonLong - sunLong) % 360;
    if (elongation < 0) elongation += 360;

    bool isWaxing = elongation < 180;
    bool isBenefic = ['Moon', 'Venus', 'Jupiter', 'Mercury'].contains(planet);

    // Strength based on Moon's phase
    double phaseFactor = isWaxing
        ? (elongation / 180)
        : ((360 - elongation) / 180);

    if (isBenefic && isWaxing) return 60.0 * phaseFactor;
    if (!isBenefic && !isWaxing) return 60.0 * phaseFactor;
    return 60.0 * (1 - phaseFactor);
  }

  static double _calculateTribhaga(String planet, CompleteChartData chart) {
    // Day divided into 3 parts: Jupiter, Mercury, Saturn
    // Night divided into 3 parts: Moon, Venus, Mars
    // Simplified: award 60 if planet rules current third
    // Without precise birth time, use approximation
    return 20.0; // Simplified average
  }

  static double _calculateAyana(String planet, double sunLong) {
    // Uttarayana (Sun in Capricorn-Gemini, 270-90): Sun, Mars, Jupiter strong
    // Dakshinayana (Sun in Cancer-Sagittarius, 90-270): Moon, Venus, Saturn strong

    bool isUttarayana = (sunLong >= 270 || sunLong < 90);

    if (['Sun', 'Mars', 'Jupiter'].contains(planet) && isUttarayana) {
      return 60.0;
    }
    if (['Moon', 'Venus', 'Saturn'].contains(planet) && !isUttarayana) {
      return 60.0;
    }
    return 0.0;
  }

  static double _calculateHora(String planet, CompleteChartData chart) {
    // Hora lord calculation requires precise birth time and timezone
    // Simplified: Use weekday lord approximation
    // Each day ruled by a planet
    try {
      // Get datetime from chart if available
      // For now, return average value
      return 15.0; // Simplified
    } catch (e) {
      return 15.0;
    }
  }

  // --- 4. Chesta Bala (Motional Strength) ---
  static Map<String, double> _calculateChestaBala(CompleteChartData chart) {
    Map<String, double> bala = {};

    // Sun and Moon don't have Chesta Bala (use Ayana Bala instead)
    // For other planets, based on speed and retrogression

    for (var planet in ['Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn']) {
      double speed = _getPlanetSpeed(chart, planet);
      double chesta = _calculateMotionalStrength(planet, speed);
      bala[planet] = chesta;
    }

    // Sun and Moon get 0 (their temporal strength is in Kaala Bala)
    bala['Sun'] = 0.0;
    bala['Moon'] = 0.0;

    return bala;
  }

  static double _getPlanetSpeed(CompleteChartData chart, String planetName) {
    // VedicPlanetInfo may not have speed property
    // Simplified: Use retrograde status if available, otherwise estimate from context
    // For full accuracy, we'd need to calculate positions at different times
    // For now, return 0 to indicate average/neutral speed
    // Retrograde detection can be done via separate analysis
    return 0.0; // Simplified - neutral speed
  }

  static double _calculateMotionalStrength(String planet, double speed) {
    // Retrograde planets get maximum Chesta Bala (60)
    if (speed < 0) return 60.0;

    // For direct motion, strength based on speed
    // Maximum speeds (approximate degrees per day):
    final Map<String, double> maxSpeeds = {
      'Mars': 0.8,
      'Mercury': 2.0,
      'Jupiter': 0.25,
      'Venus': 1.25,
      'Saturn': 0.13,
    };

    double maxSpeed = maxSpeeds[planet] ?? 1.0;
    double ratio = (speed / maxSpeed).abs();
    if (ratio > 1.0) ratio = 1.0;

    return 60.0 * ratio;
  }

  // --- 5. Naisargika Bala (Natural Strength) ---
  // Fixed values
  static Map<String, double> _getNaisargikaBala() {
    return {
      'Sun': 60.0,
      'Moon': 51.43,
      'Venus': 42.85,
      'Jupiter': 34.28,
      'Mercury': 25.70,
      'Mars': 17.14,
      'Saturn': 8.57,
    };
  }

  // --- 6. Drik Bala (Aspectual Strength) ---
  static Map<String, double> _calculateDrikBala(CompleteChartData chart) {
    Map<String, double> bala = {};

    for (var planet in [
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
    ]) {
      double strength = 0.0;
      double planetLong = _getPlanetLongitude(chart, planet);

      // Check aspects from all other planets
      for (var other in [
        'Sun',
        'Moon',
        'Mars',
        'Mercury',
        'Jupiter',
        'Venus',
        'Saturn',
      ]) {
        if (other == planet) continue;

        double otherLong = _getPlanetLongitude(chart, other);
        double aspectStrength = _getAspectStrength(
          other,
          otherLong,
          planetLong,
        );

        // Benefic aspects add, malefic subtract
        bool isBenefic = ['Jupiter', 'Venus', 'Mercury'].contains(other);
        if (isBenefic) {
          strength += aspectStrength;
        } else {
          strength -= aspectStrength;
        }
      }

      bala[planet] = strength;
    }

    return bala;
  }

  static double _getAspectStrength(
    String planet,
    double fromLong,
    double toLong,
  ) {
    // Calculate aspect strength based on Vedic aspects
    // All planets aspect 7th house (opposition)
    // Mars: 4th and 8th
    // Jupiter: 5th and 9th
    // Saturn: 3rd and 10th

    double diff = (toLong - fromLong).abs();
    if (diff > 180) diff = 360 - diff;

    // Check 7th aspect (opposition = 180 deg)
    if ((diff - 180).abs() < 15) return 60.0; // Full strength

    // Check special aspects
    if (planet == 'Mars') {
      // 4th aspect (90 deg) and 8th aspect (210 deg)
      if ((diff - 90).abs() < 15) return 45.0; // 3/4 strength
      if ((diff - 210).abs() < 15) return 45.0;
    }

    if (planet == 'Jupiter') {
      // 5th aspect (120 deg) and 9th aspect (240 deg)
      if ((diff - 120).abs() < 15) return 45.0;
      if ((diff - 240).abs() < 15) return 45.0;
    }

    if (planet == 'Saturn') {
      // 3rd aspect (60 deg) and 10th aspect (270 deg)
      if ((diff - 60).abs() < 15) return 45.0;
      if ((diff - 270).abs() < 15) return 45.0;
    }

    return 0.0; // No aspect
  }

  // --- Sthana Bala Sub-components ---

  /// Calculate Saptavargaja Bala - Strength from 7 divisional charts
  /// Evaluates planet's dignity in D-1, D-2, D-3, D-7, D-9, D-12, D-30
  static double _calculateSaptavargajaBala(
    CompleteChartData chart,
    String planet,
  ) {
    final vargaCodes = ['D-1', 'D-2', 'D-3', 'D-7', 'D-9', 'D-12', 'D-30'];
    double totalStrength = 0.0;

    for (final code in vargaCodes) {
      final vargaChart = chart.divisionalCharts[code];
      if (vargaChart == null) continue;

      final dignity = _getPlanetDignityInChart(chart, planet, vargaChart);
      double strength = 0.0;

      switch (dignity) {
        case 'Vargottama':
          strength = 5.0; // Highest strength
          break;
        case 'Exalted':
          strength = 4.5;
          break;
        case 'Own':
          strength = 4.0;
          break;
        case 'Friend':
          strength = 3.0;
          break;
        case 'Neutral':
          strength = 2.0;
          break;
        case 'Enemy':
          strength = 1.0;
          break;
        case 'Debilitated':
          strength = 0.0;
          break;
      }

      totalStrength += strength;
    }

    // Scale to traditional Shadbala units (max ~30 units for 7 charts)
    return totalStrength;
  }

  /// Calculate Ojayugmarasyamsa Bala - Odd/Even Sign Strength
  /// Male planets strong in odd signs, female planets in even signs
  static double _calculateOjayugmarasyamsaBala(
    String planet,
    double longitude,
  ) {
    final sign = (longitude / 30).floor();
    final isOddSign =
        sign % 2 == 0; // 0-indexed: 0=Aries (odd), 1=Taurus (even)

    // Male planets: Sun, Mars, Jupiter
    // Female planets: Moon, Venus
    // Neutral: Mercury, Saturn
    final malePlanets = ['Sun', 'Mars', 'Jupiter'];
    final femalePlanets = ['Moon', 'Venus'];

    if (malePlanets.contains(planet) && isOddSign) {
      return 15.0;
    } else if (femalePlanets.contains(planet) && !isOddSign) {
      return 15.0;
    } else if (['Mercury', 'Saturn'].contains(planet)) {
      return 7.5; // Neutral planets get half strength
    }

    return 0.0;
  }

  /// Calculate Drekkan Bala - Drekkana (D-3) Strength
  /// Based on planet's position in D-3 and relationship with drekkana lord
  static double _calculateDrekkanaStrength(
    CompleteChartData chart,
    String planet,
    double longitude,
  ) {
    final d3Chart = chart.divisionalCharts['D-3'];
    if (d3Chart == null) return 0.0;

    // Determine which drekkana (0-2) the planet occupies in its sign
    final degreeInSign = longitude % 30;
    final drekkanaIndex = (degreeInSign / 10).floor(); // 0, 1, or 2

    // Get drekkana lord based on position
    // First drekkana (0-10°): Same sign lord
    // Second drekkana (10-20°): 5th sign lord
    // Third drekkana (20-30°): 9th sign lord
    final sign = (longitude / 30).floor();
    int drekkanLordSign;

    switch (drekkanaIndex) {
      case 0:
        drekkanLordSign = sign;
        break;
      case 1:
        drekkanLordSign = (sign + 4) % 12; // 5th sign (0-indexed)
        break;
      case 2:
        drekkanLordSign = (sign + 8) % 12; // 9th sign (0-indexed)
        break;
      default:
        drekkanLordSign = sign;
    }

    final drekkanLord = _getSignLord(drekkanLordSign);

    // Evaluate relationship between planet and drekkana lord
    final relationship = _getFriendlyRelationship(planet, drekkanLord);

    switch (relationship) {
      case 'Friend':
        return 10.0;
      case 'Neutral':
        return 5.0;
      case 'Enemy':
        return 2.0;
      default:
        return 5.0;
    }
  }

  // --- Helper Methods for Dignity Calculations ---

  /// Determine planet's dignity in a divisional chart
  /// Returns: Vargottama, Exalted, Own, Friend, Neutral, Enemy, Debilitated
  static String _getPlanetDignityInChart(
    CompleteChartData chart,
    String planet,
    DivisionalChartData vargaChart,
  ) {
    final vargaLong = vargaChart.positions[planet];
    if (vargaLong == null) return 'Neutral';

    final vargaSign = (vargaLong / 30).floor();

    // Check for Vargottama (same sign in Rasi and this varga)
    final rasiLong = _getPlanetLongitude(chart, planet);
    final rasiSign = (rasiLong / 30).floor();
    if (vargaSign == rasiSign && vargaChart.code != 'D-1') {
      return 'Vargottama';
    }

    // Check exaltation
    final exaltationSigns = {
      'Sun': 0, // Aries
      'Moon': 1, // Taurus
      'Mars': 9, // Capricorn
      'Mercury': 5, // Virgo
      'Jupiter': 3, // Cancer
      'Venus': 11, // Pisces
      'Saturn': 6, // Libra
    };

    if (exaltationSigns[planet] == vargaSign) {
      return 'Exalted';
    }

    // Check debilitation (opposite of exaltation)
    final debilitationSign = (exaltationSigns[planet]! + 6) % 12;
    if (debilitationSign == vargaSign) {
      return 'Debilitated';
    }

    // Check own sign
    final ownSigns = _getOwnSigns(planet);
    if (ownSigns.contains(vargaSign)) {
      return 'Own';
    }

    // Check friendly/enemy relationship with sign lord
    final signLord = _getSignLord(vargaSign);
    final relationship = _getFriendlyRelationship(planet, signLord);

    return relationship;
  }

  /// Get planet's own signs
  static List<int> _getOwnSigns(String planet) {
    const ownSigns = {
      'Sun': [4], // Leo
      'Moon': [3], // Cancer
      'Mars': [0, 7], // Aries, Scorpio
      'Mercury': [2, 5], // Gemini, Virgo
      'Jupiter': [8, 11], // Sagittarius, Pisces
      'Venus': [1, 6], // Taurus, Libra
      'Saturn': [9, 10], // Capricorn, Aquarius
    };
    return ownSigns[planet] ?? [];
  }

  /// Get sign lord for a given sign (0-11)
  static String _getSignLord(int sign) {
    const lords = [
      'Mars', // Aries
      'Venus', // Taurus
      'Mercury', // Gemini
      'Moon', // Cancer
      'Sun', // Leo
      'Mercury', // Virgo
      'Venus', // Libra
      'Mars', // Scorpio
      'Jupiter', // Sagittarius
      'Saturn', // Capricorn
      'Saturn', // Aquarius
      'Jupiter', // Pisces
    ];
    return lords[sign % 12];
  }

  /// Get friendly relationship between two planets
  /// Returns: Friend, Neutral, Enemy
  static String _getFriendlyRelationship(String planet1, String planet2) {
    if (planet1 == planet2) return 'Friend'; // Planet in own sign

    // Simplified natural friendships (classical Vedic astrology)
    const friendships = {
      'Sun': {'Moon', 'Mars', 'Jupiter'},
      'Moon': {'Sun', 'Mercury'},
      'Mars': {'Sun', 'Moon', 'Jupiter'},
      'Mercury': {'Sun', 'Venus'},
      'Jupiter': {'Sun', 'Moon', 'Mars'},
      'Venus': {'Mercury', 'Saturn'},
      'Saturn': {'Mercury', 'Venus'},
    };

    const enemities = {
      'Sun': {'Venus', 'Saturn'},
      'Moon': {'None'},
      'Mars': {'Mercury'},
      'Mercury': {'Moon'},
      'Jupiter': {'Mercury', 'Venus'},
      'Venus': {'Sun', 'Moon'},
      'Saturn': {'Sun', 'Moon', 'Mars'},
    };

    if (friendships[planet1]?.contains(planet2) ?? false) {
      return 'Friend';
    } else if (enemities[planet1]?.contains(planet2) ?? false) {
      return 'Enemy';
    }

    return 'Neutral';
  }
}
