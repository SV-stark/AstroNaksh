import 'package:fluent_ui/fluent_ui.dart';
import 'package:jyotish/core.dart';
import '../core/ephemeris_manager.dart';
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

  /// Analyze full Kuta Matching (Ashtakoota) using the unified Jyotish engine
  static NakshatraAnalysis _analyzeNakshatraCompatibility(
    CompleteChartData chart1,
    CompleteChartData chart2,
  ) {
    try {
      final gunaScores = EphemerisManager.jyotish.calculateGunaMilan(
        chart1.baseChart,
        chart2.baseChart,
      );

      final moon1 = chart1.baseChart.planets[Planet.moon];
      final moon2 = chart2.baseChart.planets[Planet.moon];
      final moon1Nak = moon1?.position.nakshatra ?? 'Unknown';
      final moon2Nak = moon2?.position.nakshatra ?? 'Unknown';

      return NakshatraAnalysis(
        moon1Nakshatra: moon1Nak,
        moon2Nakshatra: moon2Nak,
        varna: gunaScores.varna.toDouble(),
        vashya: gunaScores.vashya.toDouble(),
        tara: gunaScores.tara,
        yoni: gunaScores.yoni.toDouble(),
        maitri: gunaScores.grahaMaitri.toDouble(),
        gana: gunaScores.gana.toDouble(),
        bhakoot: gunaScores.bhakoot.toDouble(),
        nadi: gunaScores.nadi.toDouble(),
        totalScore: gunaScores.total,
      );
    } catch (_) {
      final moon1 = chart1.baseChart.planets[Planet.moon];
      final moon2 = chart2.baseChart.planets[Planet.moon];
      return NakshatraAnalysis(
        moon1Nakshatra: moon1?.position.nakshatra ?? 'Unknown',
        moon2Nakshatra: moon2?.position.nakshatra ?? 'Unknown',
        varna: 0,
        vashya: 0,
        tara: 0,
        yoni: 0,
        maitri: 0,
        gana: 0,
        bhakoot: 0,
        nadi: 0,
        totalScore: 0,
      );
    }
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
  /// Weighted distribution:
  /// - Ashtakoota Nakshatra Matching: 50% max
  /// - Synastry Aspect Balance: 25% max
  /// - Navamsa Compatibility: 15% max
  /// - House Overlays: 10% max
  static double _calculateOverallScore(
    List<SynastryAspect> aspects,
    List<HouseOverlay> overlays,
    NakshatraAnalysis nakshatra,
    NavamsaCompatibility navamsa,
  ) {
    // 1. Ashta Kuta Contribution (50% max)
    final kutaContribution = (nakshatra.totalScore / 36.0) * 50.0;

    // 2. Synastry Aspect Contribution (25% max)
    var aspectScore = 12.5; // neutral midpoint
    if (aspects.isNotEmpty) {
      var netAspects = 0.0;
      for (final aspect in aspects) {
        if (aspect.effect == AspectEffect.veryPositive) {
          netAspects += 1.5;
        } else if (aspect.effect == AspectEffect.positive) {
          netAspects += 1.0;
        } else if (aspect.effect == AspectEffect.challenging) {
          netAspects -= 0.8;
        } else if (aspect.effect == AspectEffect.veryChallenging) {
          netAspects -= 1.5;
        }
      }
      aspectScore = (12.5 + netAspects).clamp(0.0, 25.0);
    }

    // 3. Navamsa Compatibility (15% max)
    final navamsaContribution =
        ((navamsa.score / 100.0) * 15.0).clamp(0.0, 15.0);

    // 4. House Overlays (10% max)
    var overlayPoints = 5.0;
    for (final overlay in overlays) {
      if (overlay.significance.contains('benefic')) {
        overlayPoints += 0.5;
      } else if (overlay.significance.contains('challeng')) {
        overlayPoints -= 0.5;
      }
    }
    final overlayContribution = overlayPoints.clamp(0.0, 10.0);

    final totalScore = kutaContribution +
        aspectScore +
        navamsaContribution +
        overlayContribution;

    return totalScore.clamp(0.0, 100.0);
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

    final p1IsBenefic = benefics.any(p1Name.contains);
    final p2IsBenefic = benefics.any(p2Name.contains);
    final p1IsMalefic = malefics.any(p1Name.contains);
    final p2IsMalefic = malefics.any(p2Name.contains);

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
          (diff == 2 || diff == 9)) {
        return true;
      }
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

  static const List<int> _nakshatraYoniAnimalIndex = [
    0, // 0: Ashwini (Horse)
    1, // 1: Bharani (Elephant)
    2, // 2: Krittika (Goat)
    3, // 3: Rohini (Serpent)
    3, // 4: Mrigashira (Serpent)
    4, // 5: Ardra (Dog)
    5, // 6: Punarvasu (Cat)
    2, // 7: Pushya (Goat)
    5, // 8: Ashlesha (Cat)
    6, // 9: Magha (Rat)
    6, // 10: Purva Phalguni (Rat)
    7, // 11: Uttara Phalguni (Cow)
    8, // 12: Hasta (Buffalo)
    9, // 13: Chitra (Tiger)
    8, // 14: Swati (Buffalo)
    9, // 15: Vishakha (Tiger)
    10, // 16: Anuradha (Deer)
    10, // 17: Jyeshtha (Deer)
    4, // 18: Mula (Dog)
    11, // 19: Purva Ashadha (Monkey)
    12, // 20: Uttara Ashadha (Mongoose)
    11, // 21: Shravana (Monkey)
    13, // 22: Dhanishta (Lion)
    0, // 23: Shatabhisha (Horse)
    13, // 24: Purva Bhadrapada (Lion)
    7, // 25: Uttara Bhadrapada (Cow)
    1, // 26: Revati (Elephant)
  ];

  static const List<String> _yoniAnimalNames = [
    'Horse',
    'Elephant',
    'Goat',
    'Serpent',
    'Dog',
    'Cat',
    'Rat',
    'Cow',
    'Buffalo',
    'Tiger',
    'Deer',
    'Monkey',
    'Mongoose',
    'Lion',
  ];

  static const List<List<int>> _yoniMatrix = [
    [4, 3, 2, 3, 2, 2, 2, 2, 0, 2, 2, 3, 2, 2], // Horse
    [3, 4, 3, 3, 2, 2, 2, 2, 3, 2, 2, 3, 2, 0], // Elephant
    [2, 3, 4, 2, 2, 2, 2, 3, 3, 2, 2, 0, 3, 2], // Goat
    [3, 3, 2, 4, 2, 3, 2, 2, 2, 2, 2, 2, 0, 2], // Serpent
    [2, 2, 2, 2, 4, 3, 3, 2, 2, 2, 0, 2, 2, 2], // Dog
    [2, 2, 2, 3, 3, 4, 0, 2, 2, 2, 3, 3, 2, 2], // Cat
    [2, 2, 2, 2, 3, 0, 4, 2, 2, 2, 2, 2, 2, 2], // Rat
    [2, 2, 3, 2, 2, 2, 2, 4, 3, 0, 3, 2, 2, 2], // Cow
    [0, 3, 3, 2, 2, 2, 2, 3, 4, 2, 2, 2, 2, 2], // Buffalo
    [2, 2, 2, 2, 2, 2, 2, 0, 2, 4, 1, 2, 2, 2], // Tiger
    [2, 2, 2, 2, 0, 3, 2, 3, 2, 1, 4, 2, 2, 2], // Deer
    [3, 3, 0, 2, 2, 3, 2, 2, 2, 2, 2, 4, 2, 2], // Monkey
    [2, 2, 3, 0, 2, 2, 2, 2, 2, 2, 2, 2, 4, 2], // Mongoose
    [2, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4], // Lion
  ];

  static String calculateYoniDescription(int nak1, int nak2) {
    final a1 = _nakshatraYoniAnimalIndex[nak1 % 27];
    final a2 = _nakshatraYoniAnimalIndex[nak2 % 27];
    final score = _yoniMatrix[a1][a2];
    final name1 = _yoniAnimalNames[a1];
    final name2 = _yoniAnimalNames[a2];
    if (score == 4) return '$name1 - $name2: Excellent (Same Yoni)';
    if (score == 3) return '$name1 - $name2: Good (Friendly Yoni)';
    if (score == 2) return '$name1 - $name2: Neutral Yoni';
    if (score == 1) return '$name1 - $name2: Challenging (Enemy Yoni)';
    return '$name1 - $name2: Incompatible (Bitter Enemy)';
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
  final String chart1Name;
  final String chart2Name;
  final List<SynastryAspect> aspects;
  final List<HouseOverlay> houseOverlays;
  final NakshatraAnalysis nakshatraAnalysis;
  final NavamsaCompatibility navamsaCompatibility;
  final double overallScore;
  final String summary;

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
  SynastryAspect({
    required this.planet1,
    required this.planet2,
    required this.aspectType,
    required this.orb,
    required this.effect,
  });
  final Planet planet1;
  final Planet planet2;
  final AspectType aspectType;
  final double orb;
  final AspectEffect effect;

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
  HouseOverlay({
    required this.planet,
    required this.house,
    required this.houseLord,
    required this.significance,
    required this.chart,
  });
  final Planet planet;
  final int house;
  final String houseLord;
  final String significance;
  final int chart;
}

/// Nakshatra Analysis (Kuta Matching)
class NakshatraAnalysis {
  NakshatraAnalysis({
    required this.moon1Nakshatra,
    required this.moon2Nakshatra,
    required this.varna,
    required this.vashya,
    required this.tara,
    required this.yoni,
    required this.maitri,
    required this.gana,
    required this.bhakoot,
    required this.nadi,
    required this.totalScore,
  });
  final String moon1Nakshatra;
  final String moon2Nakshatra;
  final double varna;
  final double vashya;
  final double tara;
  final double yoni;
  final double maitri;
  final double gana;
  final double bhakoot;
  final double nadi;
  final double totalScore;

  /// Deprecated getters for backward compat if needed, simplified
  String get score => totalScore.toStringAsFixed(1);
}

/// Navamsa Compatibility
class NavamsaCompatibility {
  NavamsaCompatibility({
    required this.ascendantCompatibility,
    required this.moonSignCompatibility,
    required this.venusSignCompatibility,
    required this.score,
  });
  final String ascendantCompatibility;
  final String moonSignCompatibility;
  final String venusSignCompatibility;
  final double score;
}
