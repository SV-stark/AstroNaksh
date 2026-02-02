import 'package:flutter/material.dart';
import 'package:jyotish/jyotish.dart';
import '../data/models.dart';

/// Chart Comparison & Synastry Analysis
/// Compares two charts for compatibility analysis
class ChartComparison {
  /// Analyze compatibility between two charts
  static SynastryAnalysis analyzeCompatibility(
    CompleteChartData chart1,
    CompleteChartData chart2,
  ) {
    // Basic planet-to-planet aspects
    final aspects = _analyzeSynastryAspects(chart1, chart2);

    // House overlays (where one person's planets fall in other's houses)
    final houseOverlays = _analyzeHouseOverlays(chart1, chart2);

    // Nakshatra compatibility
    final nakshatraAnalysis = _analyzeNakshatraCompatibility(chart1, chart2);

    // D-9 compatibility (Navamsa)
    final navamsaCompatibility = _analyzeNavamsaCompatibility(chart1, chart2);

    // Generate overall score
    final overallScore = _calculateOverallScore(
      aspects,
      houseOverlays,
      nakshatraAnalysis,
      navamsaCompatibility,
    );

    return SynastryAnalysis(
      chart1Name: 'Chart 1',
      chart2Name: 'Chart 2',
      aspects: aspects,
      houseOverlays: houseOverlays,
      nakshatraAnalysis: nakshatraAnalysis,
      navamsaCompatibility: navamsaCompatibility,
      overallScore: overallScore,
      summary: _generateSummary(aspects, houseOverlays, overallScore),
    );
  }

  /// Analyze synastry aspects between two charts
  static List<SynastryAspect> _analyzeSynastryAspects(
    CompleteChartData chart1,
    CompleteChartData chart2,
  ) {
    final aspects = <SynastryAspect>[];
    const orb = 8.0; // Synastry orb is wider

    chart1.baseChart.planets.forEach((planet1, info1) {
      chart2.baseChart.planets.forEach((planet2, info2) {
        final angle = _normalizeAngle(info1.longitude - info2.longitude);

        // Check for conjunction (0°)
        if (angle <= orb || angle >= 360 - orb) {
          aspects.add(
            SynastryAspect(
              planet1: planet1,
              planet2: planet2,
              aspectType: AspectType.conjunction,
              orb: angle > 180 ? 360 - angle : angle,
              effect: _getSynastryAspectEffect(
                planet1,
                planet2,
                AspectType.conjunction,
              ),
            ),
          );
        }
        // Opposition (180°)
        else if (_isWithinOrb(angle, 180, orb)) {
          aspects.add(
            SynastryAspect(
              planet1: planet1,
              planet2: planet2,
              aspectType: AspectType.opposition,
              orb: _calculateOrb(angle, 180),
              effect: _getSynastryAspectEffect(
                planet1,
                planet2,
                AspectType.opposition,
              ),
            ),
          );
        }
        // Trine (120°)
        else if (_isWithinOrb(angle, 120, orb)) {
          aspects.add(
            SynastryAspect(
              planet1: planet1,
              planet2: planet2,
              aspectType: AspectType.trine,
              orb: _calculateOrb(angle, 120),
              effect: _getSynastryAspectEffect(
                planet1,
                planet2,
                AspectType.trine,
              ),
            ),
          );
        }
        // Sextile (60°)
        else if (_isWithinOrb(angle, 60, orb)) {
          aspects.add(
            SynastryAspect(
              planet1: planet1,
              planet2: planet2,
              aspectType: AspectType.sextile,
              orb: _calculateOrb(angle, 60),
              effect: _getSynastryAspectEffect(
                planet1,
                planet2,
                AspectType.sextile,
              ),
            ),
          );
        }
        // Square (90°)
        else if (_isWithinOrb(angle, 90, orb)) {
          aspects.add(
            SynastryAspect(
              planet1: planet1,
              planet2: planet2,
              aspectType: AspectType.square,
              orb: _calculateOrb(angle, 90),
              effect: _getSynastryAspectEffect(
                planet1,
                planet2,
                AspectType.square,
              ),
            ),
          );
        }
      });
    });

    // Sort by orb (closest aspects first)
    aspects.sort((a, b) => a.orb.compareTo(b.orb));
    return aspects;
  }

  /// Analyze house overlays
  static List<HouseOverlay> _analyzeHouseOverlays(
    CompleteChartData chart1,
    CompleteChartData chart2,
  ) {
    final overlays = <HouseOverlay>[];

    // Get ascendant positions
    final asc1 = _getHouseCuspLongitude(chart1.baseChart, 0);
    final asc2 = _getHouseCuspLongitude(chart2.baseChart, 0);

    // Chart 1 planets in Chart 2's houses
    chart1.baseChart.planets.forEach((planet, info) {
      final house = _calculateHouse(info.longitude, asc2);
      final houseSignificance = _getHouseSignificance(house, planet);

      overlays.add(
        HouseOverlay(
          planet: planet,
          house: house,
          houseLord: _getHouseLord(house, asc2),
          significance: houseSignificance,
          chart: 1,
        ),
      );
    });

    // Chart 2 planets in Chart 1's houses
    chart2.baseChart.planets.forEach((planet, info) {
      final house = _calculateHouse(info.longitude, asc1);
      final houseSignificance = _getHouseSignificance(house, planet);

      overlays.add(
        HouseOverlay(
          planet: planet,
          house: house,
          houseLord: _getHouseLord(house, asc1),
          significance: houseSignificance,
          chart: 2,
        ),
      );
    });

    return overlays;
  }

  /// Analyze nakshatra compatibility
  static NakshatraAnalysis _analyzeNakshatraCompatibility(
    CompleteChartData chart1,
    CompleteChartData chart2,
  ) {
    final nakshatras = [
      'Ashwini',
      'Bharani',
      'Krittika',
      'Rohini',
      'Mrigashira',
      'Ardra',
      'Punarvasu',
      'Pushya',
      'Ashlesha',
      'Magha',
      'Purva Phalguni',
      'Uttara Phalguni',
      'Hasta',
      'Chitra',
      'Swati',
      'Vishakha',
      'Anuradha',
      'Jyeshtha',
      'Mula',
      'Purva Ashadha',
      'Uttara Ashadha',
      'Shravana',
      'Dhanishta',
      'Shatabhisha',
      'Purva Bhadrapada',
      'Uttara Bhadrapada',
      'Revati',
    ];

    // Get Moon nakshatras for both charts
    int? moon1Nakshatra, moon2Nakshatra;

    for (final entry in chart1.baseChart.planets.entries) {
      if (entry.key.toString().toLowerCase().contains('moon')) {
        moon1Nakshatra = (entry.value.longitude / (360.0 / 27.0)).floor();
        break;
      }
    }

    for (final entry in chart2.baseChart.planets.entries) {
      if (entry.key.toString().toLowerCase().contains('moon')) {
        moon2Nakshatra = (entry.value.longitude / (360.0 / 27.0)).floor();
        break;
      }
    }

    if (moon1Nakshatra == null || moon2Nakshatra == null) {
      return NakshatraAnalysis(
        moon1Nakshatra: 'Unknown',
        moon2Nakshatra: 'Unknown',
        yoni: 'Unknown',
        gana: 'Unknown',
        nadi: 'Unknown',
        score: 0,
      );
    }

    final nak1 = nakshatras[moon1Nakshatra % 27];
    final nak2 = nakshatras[moon2Nakshatra % 27];

    // Calculate yoni (animal compatibility)
    final yoni = _calculateYoni(moon1Nakshatra, moon2Nakshatra);

    // Calculate gana (temperament)
    final gana = _calculateGana(moon1Nakshatra, moon2Nakshatra);

    // Calculate nadi (health compatibility)
    final nadi = _calculateNadi(moon1Nakshatra, moon2Nakshatra);

    // Calculate score
    final score = _calculateNakshatraScore(yoni, gana, nadi);

    return NakshatraAnalysis(
      moon1Nakshatra: nak1,
      moon2Nakshatra: nak2,
      yoni: yoni,
      gana: gana,
      nadi: nadi,
      score: score,
    );
  }

  /// Analyze Navamsa compatibility
  static NavamsaCompatibility _analyzeNavamsaCompatibility(
    CompleteChartData chart1,
    CompleteChartData chart2,
  ) {
    final navamsa1 = chart1.divisionalCharts['D-9'];
    final navamsa2 = chart2.divisionalCharts['D-9'];

    if (navamsa1 == null || navamsa2 == null) {
      return NavamsaCompatibility(
        ascendantCompatibility: 'Unknown',
        moonSignCompatibility: 'Unknown',
        venusSignCompatibility: 'Unknown',
        score: 0,
      );
    }

    // Check ascendant signs
    final asc1 = navamsa1.ascendantSign ?? 0;
    final asc2 = navamsa2.ascendantSign ?? 0;
    final ascCompatibility = _checkSignCompatibility(asc1, asc2);

    // Check Moon signs
    final moon1Sign = navamsa1.getPlanetSign('Moon');
    final moon2Sign = navamsa2.getPlanetSign('Moon');
    final moonCompatibility = _checkSignCompatibility(moon1Sign, moon2Sign);

    // Check Venus signs
    final venus1Sign = navamsa1.getPlanetSign('Venus');
    final venus2Sign = navamsa2.getPlanetSign('Venus');
    final venusCompatibility = _checkSignCompatibility(venus1Sign, venus2Sign);

    // Calculate score
    final score = _calculateNavamsaScore(
      ascCompatibility,
      moonCompatibility,
      venusCompatibility,
    );

    return NavamsaCompatibility(
      ascendantCompatibility: ascCompatibility,
      moonSignCompatibility: moonCompatibility,
      venusSignCompatibility: venusCompatibility,
      score: score,
    );
  }

  /// Calculate overall compatibility score
  static double _calculateOverallScore(
    List<SynastryAspect> aspects,
    List<HouseOverlay> overlays,
    NakshatraAnalysis nakshatra,
    NavamsaCompatibility navamsa,
  ) {
    var score = 50.0; // Base score

    // Add points for positive aspects
    for (final aspect in aspects) {
      if (aspect.effect == AspectEffect.veryPositive) {
        score += 3;
      } else if (aspect.effect == AspectEffect.positive) {
        score += 2;
      } else if (aspect.effect == AspectEffect.challenging) {
        score -= 1;
      } else if (aspect.effect == AspectEffect.veryChallenging) {
        score -= 2;
      }
    }

    // Add points for house overlays
    for (final overlay in overlays) {
      if (overlay.significance.contains('benefic')) {
        score += 1;
      }
    }

    // Add nakshatra score
    score += nakshatra.score * 0.3;

    // Add navamsa score
    score += navamsa.score * 0.2;

    // Normalize to 0-100
    return score.clamp(0.0, 100.0);
  }

  /// Generate compatibility summary
  static String _generateSummary(
    List<SynastryAspect> aspects,
    List<HouseOverlay> overlays,
    double score,
  ) {
    final buffer = StringBuffer();

    if (score >= 80) {
      buffer.writeln('Excellent Compatibility');
      buffer.writeln(
        'This is a highly favorable match with strong potential for harmony.',
      );
    } else if (score >= 60) {
      buffer.writeln('Good Compatibility');
      buffer.writeln(
        'This match has many positive elements with some areas for growth.',
      );
    } else if (score >= 40) {
      buffer.writeln('Moderate Compatibility');
      buffer.writeln(
        'This relationship requires understanding and effort from both sides.',
      );
    } else {
      buffer.writeln('Challenging Compatibility');
      buffer.writeln(
        'This match has significant challenges that require conscious work.',
      );
    }

    buffer.writeln();
    buffer.writeln('Key Findings:');

    // Top 3 aspects
    final topAspects = aspects.take(3).toList();
    for (final aspect in topAspects) {
      buffer.writeln(
        '• ${aspect.description}: ${aspect.effect.toString().split('.').last}',
      );
    }

    return buffer.toString();
  }

  /// Helper methods
  static double _normalizeAngle(double angle) {
    var normalized = angle % 360;
    if (normalized < 0) normalized += 360;
    return normalized;
  }

  static bool _isWithinOrb(double angle, double target, double orb) {
    final diff = (angle - target).abs();
    return diff <= orb || (360 - diff) <= orb;
  }

  static double _calculateOrb(double angle, double target) {
    final diff = (angle - target).abs();
    return diff > 180 ? 360 - diff : diff;
  }

  static double _getHouseCuspLongitude(VedicChart chart, int index) {
    try {
      final houses = chart.houses;
      // Fixed: Use cusps directly
      if (index < houses.cusps.length) {
        return houses.cusps[index];
      }
      return index * 30.0;
    } catch (e) {
      return index * 30.0;
    }
  }

  static int _calculateHouse(double longitude, double ascendant) {
    final relativeDegree = (longitude - ascendant + 360) % 360;
    return (relativeDegree / 30).floor() + 1;
  }

  static String _getHouseLord(int house, double ascendant) {
    final signLords = [
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
    final ascSign = (ascendant / 30).floor();
    final houseSign = (ascSign + house - 1) % 12;
    return signLords[houseSign];
  }

  static String _getHouseSignificance(int house, Planet planet) {
    final significances = {
      1: 'Personality impact',
      2: 'Values and resources',
      3: 'Communication',
      4: 'Home and family',
      5: 'Romance and creativity',
      6: 'Daily work',
      7: 'Partnership',
      8: 'Transformation',
      9: 'Higher learning',
      10: 'Career influence',
      11: 'Friendship',
      12: 'Spiritual connection',
    };
    return significances[house] ?? 'General influence';
  }

  static AspectEffect _getSynastryAspectEffect(
    Planet p1,
    Planet p2,
    AspectType type,
  ) {
    // Simplified logic - in real implementation would be more complex
    final benefics = ['jupiter', 'venus', 'moon'];
    final malefics = ['saturn', 'mars', 'rahu', 'ketu'];

    final p1Name = p1.toString().toLowerCase();
    final p2Name = p2.toString().toLowerCase();

    final p1IsBenefic = benefics.any((b) => p1Name.contains(b));
    final p2IsBenefic = benefics.any((b) => p2Name.contains(b));
    final p1IsMalefic = malefics.any((m) => p1Name.contains(m));
    final p2IsMalefic = malefics.any((m) => p2Name.contains(m));

    if (type == AspectType.trine || type == AspectType.sextile) {
      if (p1IsBenefic || p2IsBenefic) {
        return AspectEffect.veryPositive;
      }
      return AspectEffect.positive;
    } else if (type == AspectType.conjunction) {
      if (p1IsBenefic && p2IsBenefic) {
        return AspectEffect.veryPositive;
      } else if (p1IsMalefic || p2IsMalefic) {
        return AspectEffect.challenging;
      }
      return AspectEffect.neutral;
    } else if (type == AspectType.square || type == AspectType.opposition) {
      if (p1IsMalefic || p2IsMalefic) {
        return AspectEffect.veryChallenging;
      }
      return AspectEffect.challenging;
    }

    return AspectEffect.neutral;
  }

  /// Check for Vedic Rashi Drishti (sign-based aspects)
  /// In Vedic astrology, aspects are determined by sign relationships
  static bool hasVedicAspect(int sign1, int sign2, Planet? planet) {
    final diff = ((sign2 - sign1) % 12 + 12) % 12; // Houses from sign1 to sign2

    // All planets aspect the 7th sign (opposition)
    if (diff == 6) return true;

    // Special planetary aspects (if planet is provided)
    if (planet != null) {
      final planetName = planet.toString().split('.').last.toLowerCase();

      // Mars aspects 4th and 8th houses additionally
      if (planetName == 'mars' && (diff == 3 || diff == 7)) return true;

      // Jupiter aspects 5th and 9th houses additionally
      if (planetName == 'jupiter' && (diff == 4 || diff == 8)) return true;

      // Saturn aspects 3rd and 10th houses additionally
      if (planetName == 'saturn' && (diff == 2 || diff == 9)) return true;

      // Rahu/Ketu aspect like Saturn (some traditions)
      if ((planetName == 'rahu' || planetName == 'ketu') &&
          (diff == 2 || diff == 9))
        return true;
    }

    return false;
  }

  /// Get Vedic aspect strength
  /// Full (100%) for 7th, 3/4 for special aspects
  static double getVedicAspectStrength(int sign1, int sign2, Planet? planet) {
    final diff = ((sign2 - sign1) % 12 + 12) % 12;

    // Full aspect for 7th house
    if (diff == 6) return 1.0;

    if (planet != null) {
      final planetName = planet.toString().split('.').last.toLowerCase();

      // Mars special aspects - full strength
      if (planetName == 'mars' && (diff == 3 || diff == 7)) return 1.0;

      // Jupiter special aspects - full strength
      if (planetName == 'jupiter' && (diff == 4 || diff == 8)) return 1.0;

      // Saturn special aspects - full strength
      if (planetName == 'saturn' && (diff == 2 || diff == 9)) return 1.0;
    }

    return 0.0; // No aspect
  }

  static String _calculateYoni(int nak1, int nak2) {
    // Simplified yoni calculation
    final diff = (nak1 - nak2).abs();
    if (diff == 0) return 'Same Yoni - Excellent';
    if (diff == 9 || diff == 18) return 'Friendly Yoni - Good';
    if (diff == 13 || diff == 14) return 'Neutral Yoni - Moderate';
    return 'Different Yoni - Challenging';
  }

  static String _calculateGana(int nak1, int nak2) {
    // Correct Gana groups - 9 nakshatras each
    // Deva Gana (divine temperament)
    const deva = [0, 4, 6, 7, 12, 14, 20, 21, 26];
    // Ashwini, Mrigashira, Punarvasu, Pushya, Hasta, Swati, Shravana, Dhanishta, Revati

    // Manushya Gana (human temperament)
    const manushya = [1, 3, 5, 10, 11, 13, 15, 17, 24];
    // Bharani, Rohini, Ardra, Purva Phalguni, Uttara Phalguni, Chitra, Vishakha, Jyeshtha, Purva Bhadrapada

    // Rakshasa Gana (demonic/fierce temperament) - remaining 9
    // Krittika, Ashlesha, Magha, Anuradha, Mula, Purva Ashadha, Uttara Ashadha, Shatabhisha, Uttara Bhadrapada
    // Indices: 2, 8, 9, 16, 18, 19, 20, 23, 25

    final g1 = deva.contains(nak1 % 27)
        ? 'Deva'
        : manushya.contains(nak1 % 27)
        ? 'Manushya'
        : 'Rakshasa';
    final g2 = deva.contains(nak2 % 27)
        ? 'Deva'
        : manushya.contains(nak2 % 27)
        ? 'Manushya'
        : 'Rakshasa';

    if (g1 == g2) return '$g1 - $g1: Excellent';
    if ((g1 == 'Deva' && g2 == 'Manushya') ||
        (g1 == 'Manushya' && g2 == 'Deva')) {
      return '$g1 - $g2: Good';
    }
    return '$g1 - $g2: Challenging';
  }

  static String _calculateNadi(int nak1, int nak2) {
    // Correct Nadi groups - 9 nakshatras each in cyclic pattern
    // Adi (Vata): 0, 3, 6, 9, 12, 15, 18, 21, 24
    // Madhya (Pitta): 1, 4, 7, 10, 13, 16, 19, 22, 25
    // Antya (Kapha): 2, 5, 8, 11, 14, 17, 20, 23, 26
    // Each Nadi = nakshatras where (index % 3) equals Nadi number

    String getNadi(int nakshatra) {
      final remainder = (nakshatra % 27) % 3;
      switch (remainder) {
        case 0:
          return 'Adi';
        case 1:
          return 'Madhya';
        case 2:
          return 'Antya';
        default:
          return 'Adi';
      }
    }

    final n1 = getNadi(nak1);
    final n2 = getNadi(nak2);

    if (n1 == n2) return '$n1 - $n2: Not Recommended (Nadi Dosh)';
    return '$n1 - $n2: Compatible';
  }

  static double _calculateNakshatraScore(
    String yoni,
    String gana,
    String nadi,
  ) {
    var score = 10.0;
    if (yoni.contains('Excellent')) score += 4;
    if (yoni.contains('Good')) score += 2;
    if (yoni.contains('Challenging')) score -= 1;
    if (gana.contains('Excellent')) score += 3;
    if (gana.contains('Good')) score += 1;
    if (gana.contains('Challenging')) score -= 1;
    if (nadi.contains('Not Recommended')) score -= 8;
    return score.clamp(0.0, 15.0);
  }

  static String _checkSignCompatibility(int sign1, int sign2) {
    // Same sign
    if (sign1 == sign2) return 'Same Sign - Strong Connection';

    // Check if signs are compatible elements
    final elements = [
      'fire', 'earth', 'air', 'water', // Aries, Taurus, Gemini, Cancer
      'fire', 'earth', 'air', 'water', // Leo, Virgo, Libra, Scorpio
      'fire',
      'earth',
      'air',
      'water', // Sagittarius, Capricorn, Aquarius, Pisces
    ];

    final e1 = elements[sign1 % 12];
    final e2 = elements[sign2 % 12];

    // Fire-Air and Earth-Water are compatible
    if ((e1 == 'fire' && e2 == 'air') || (e1 == 'air' && e2 == 'fire')) {
      return 'Fire-Air: Harmonious';
    }
    if ((e1 == 'earth' && e2 == 'water') || (e1 == 'water' && e2 == 'earth')) {
      return 'Earth-Water: Harmonious';
    }
    if (e1 == e2) {
      return 'Same Element: Good Understanding';
    }

    return 'Different Elements: Growth Opportunity';
  }

  static double _calculateNavamsaScore(String asc, String moon, String venus) {
    var score = 15.0;

    if (asc.contains('Excellent')) score += 5;
    if (asc.contains('Harmonious')) score += 3;
    if (moon.contains('Excellent')) score += 5;
    if (moon.contains('Harmonious')) score += 3;
    if (venus.contains('Excellent')) score += 5;
    if (venus.contains('Harmonious')) score += 3;

    return score.clamp(0.0, 30.0);
  }
}

/// Synastry Analysis Result
class SynastryAnalysis {
  final String chart1Name;
  final String chart2Name;
  final List<SynastryAspect> aspects;
  final List<HouseOverlay> houseOverlays;
  final NakshatraAnalysis nakshatraAnalysis;
  final NavamsaCompatibility navamsaCompatibility;
  final double overallScore;
  final String summary;

  SynastryAnalysis({
    required this.chart1Name,
    required this.chart2Name,
    required this.aspects,
    required this.houseOverlays,
    required this.nakshatraAnalysis,
    required this.navamsaCompatibility,
    required this.overallScore,
    required this.summary,
  });

  String get compatibilityLevel {
    if (overallScore >= 80) return 'Excellent';
    if (overallScore >= 60) return 'Good';
    if (overallScore >= 40) return 'Moderate';
    return 'Challenging';
  }

  Color get compatibilityColor {
    if (overallScore >= 80) return const Color(0xFF4CAF50);
    if (overallScore >= 60) return const Color(0xFF8BC34A);
    if (overallScore >= 40) return const Color(0xFFFFC107);
    return const Color(0xFFFF5722);
  }
}

/// Synastry Aspect
class SynastryAspect {
  final Planet planet1;
  final Planet planet2;
  final AspectType aspectType;
  final double orb;
  final AspectEffect effect;

  SynastryAspect({
    required this.planet1,
    required this.planet2,
    required this.aspectType,
    required this.orb,
    required this.effect,
  });

  String get description {
    final p1 = planet1.toString().split('.').last;
    final p2 = planet2.toString().split('.').last;
    final aspect = aspectType.toString().split('.').last;
    return '$p1 $aspect $p2';
  }
}

/// Aspect Type
enum AspectType { conjunction, sextile, square, trine, opposition }

/// Aspect Effect
enum AspectEffect {
  veryPositive,
  positive,
  neutral,
  challenging,
  veryChallenging,
}

/// House Overlay
class HouseOverlay {
  final Planet planet;
  final int house;
  final String houseLord;
  final String significance;
  final int chart;

  HouseOverlay({
    required this.planet,
    required this.house,
    required this.houseLord,
    required this.significance,
    required this.chart,
  });
}

/// Nakshatra Analysis
class NakshatraAnalysis {
  final String moon1Nakshatra;
  final String moon2Nakshatra;
  final String yoni;
  final String gana;
  final String nadi;
  final double score;

  NakshatraAnalysis({
    required this.moon1Nakshatra,
    required this.moon2Nakshatra,
    required this.yoni,
    required this.gana,
    required this.nadi,
    required this.score,
  });
}

/// Navamsa Compatibility
class NavamsaCompatibility {
  final String ascendantCompatibility;
  final String moonSignCompatibility;
  final String venusSignCompatibility;
  final double score;

  NavamsaCompatibility({
    required this.ascendantCompatibility,
    required this.moonSignCompatibility,
    required this.venusSignCompatibility,
    required this.score,
  });
}
