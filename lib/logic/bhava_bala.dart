import '../data/models.dart';

/// Bhava Bala (House Strength) Calculation
/// Completes the strength analysis trilogy (Shadbala, Ashtakavarga, Bhava Bala)
class BhavaBala {
  /// Calculate strength of all 12 houses
  static Map<int, BhavaStrength> calculateBhavaBala(CompleteChartData chart) {
    final Map<int, BhavaStrength> bhavaStrengths = {};

    for (int house = 1; house <= 12; house++) {
      bhavaStrengths[house] = _calculateHouseStrength(chart, house);
    }

    return bhavaStrengths;
  }

  /// Calculate strength of a specific house
  static BhavaStrength _calculateHouseStrength(
    CompleteChartData chart,
    int house,
  ) {
    double total = 0.0;
    final components = <String, double>{};

    // 1. Bhava Adhipati Bala (Lord's Strength)
    final lordBala = _calculateLordBala(chart, house);
    components['Lord Strength'] = lordBala;
    total += lordBala;

    // 2. Bhava Dig Bala (Directional Strength)
    final digBala = _calculateBhavaDigBala(house);
    components['Directional'] = digBala;
    total += digBala;

    // 3. Bhava Drishti Bala (Aspectual Strength)
    final drishti = _calculateBhavaDrishti(chart, house);
    components['Aspects'] = drishti;
    total += drishti;

    // 4. Occupant Strength
    final occupants = _calculateOccupantStrength(chart, house);
    components['Occupants'] = occupants;
    total += occupants;

    return BhavaStrength(
      house: house,
      totalStrength: total,
      components: components,
      interpretation: _interpretStrength(house, total),
    );
  }

  /// Calculate house lord's strength
  static double _calculateLordBala(CompleteChartData chart, int house) {
    final houseSign = _getHouseSign(chart, house);
    final lord = _getSignLord(houseSign);

    // Get lord's Shadbala if available, otherwise use position
    // Simplified: Check if lord is in good dignity
    final lordSign = _getPlanetSign(chart, lord);

    double strength = 30.0; // Base

    // Own sign
    if (_isOwnSign(lord, lordSign)) strength += 20.0;

    // Exaltation
    if (_isExalted(lord, lordSign)) strength += 20.0;

    // Debilitation
    if (_isDebilitated(lord, lordSign)) strength -= 15.0;

    return strength;
  }

  /// Calculate directional strength for house
  static double _calculateBhavaDigBala(int house) {
    // Houses gain strength based on their natural significations
    // Kendra houses (1,4,7,10) = strong, Trikona (1,5,9) = strong
    if ([1, 4, 7, 10].contains(house)) return 60.0; // Kendras
    if ([5, 9].contains(house)) return 45.0; // Trikonas (excluding 1st)
    if ([2, 11].contains(house)) return 30.0; // Wealth houses
    if ([3, 6].contains(house)) return 15.0; // Upachayas (growth)
    return 10.0; // Dusthanas
  }

  /// Calculate aspectual strength on house
  static double _calculateBhavaDrishti(CompleteChartData chart, int house) {
    double strength = 0.0;
    final houseSign = _getHouseSign(chart, house);

    // Check beneficial aspects from Jupiter and Venus
    final jupiterSign = _getPlanetSign(chart, 'Jupiter');
    final venusSign = _getPlanetSign(chart, 'Venus');

    if (_isAspecting(jupiterSign, houseSign)) strength += 20.0;
    if (_isAspecting(venusSign, houseSign)) strength += 15.0;

    // Check malefic aspects from Mars and Saturn
    final marsSign = _getPlanetSign(chart, 'Mars');
    final saturnSign = _getPlanetSign(chart, 'Saturn');

    if (_isAspecting(marsSign, houseSign)) strength -= 10.0;
    if (_isAspecting(saturnSign, houseSign)) strength -= 10.0;

    return strength;
  }

  /// Calculate strength from planets occupying the house
  static double _calculateOccupantStrength(CompleteChartData chart, int house) {
    double strength = 0.0;
    final houseSign = _getHouseSign(chart, house);

    for (var planet in [
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
    ]) {
      final planetSign = _getPlanetSign(chart, planet);
      if (planetSign == houseSign) {
        // Planet in house
        if (['Jupiter', 'Venus', 'Mercury'].contains(planet)) {
          strength += 15.0; // Benefics
        } else if (['Sun', 'Moon'].contains(planet)) {
          strength += 10.0; // Luminaries
        } else {
          strength += 5.0; // Malefics (still add some strength)
        }
      }
    }

    return strength;
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

  // Helper methods
  static int _getHouseSign(CompleteChartData chart, int house) {
    try {
      final cuspLong = chart.baseChart.houses.cusps[house - 1];
      return (cuspLong / 30).floor();
    } catch (e) {
      return (house - 1) % 12;
    }
  }

  static int _getPlanetSign(CompleteChartData chart, String planetName) {
    for (final entry in chart.baseChart.planets.entries) {
      if (entry.key.toString().split('.').last == planetName) {
        return (entry.value.longitude / 30).floor();
      }
    }
    return 0;
  }

  static String _getSignLord(int sign) {
    const lords = [
      'Mars',
      'Venus',
      'Mercury',
      'Moon',
      'Sun',
      'Mercury',
      'Venus',
      'Mars',
      'Jupiter',
      'Saturn',
      'Saturn',
      'Jupiter',
    ];
    return lords[sign % 12];
  }

  static bool _isOwnSign(String planet, int sign) {
    final lord = _getSignLord(sign);
    return lord == planet;
  }

  static bool _isExalted(String planet, int sign) {
    const exaltations = {
      'Sun': 0, // Aries
      'Moon': 1, // Taurus
      'Mars': 9, // Capricorn
      'Mercury': 5, // Virgo
      'Jupiter': 3, // Cancer
      'Venus': 11, // Pisces
      'Saturn': 6, // Libra
    };
    return exaltations[planet] == sign;
  }

  static bool _isDebilitated(String planet, int sign) {
    const debilitations = {
      'Sun': 6, // Libra
      'Moon': 7, // Scorpio
      'Mars': 3, // Cancer
      'Mercury': 11, // Pisces
      'Jupiter': 9, // Capricorn
      'Venus': 5, // Virgo
      'Saturn': 0, // Aries
    };
    return debilitations[planet] == sign;
  }

  static bool _isAspecting(int fromSign, int toSign) {
    final diff = ((toSign - fromSign + 12) % 12);
    return diff == 6; // 7th house aspect (opposition)
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

/// Bhava Strength data class
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
