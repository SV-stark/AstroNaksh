import 'package:fluent_ui/fluent_ui.dart';
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

  /// Analyze full Kuta Matching (Ashtakoota)
  static NakshatraAnalysis _analyzeNakshatraCompatibility(
    CompleteChartData chart1,
    CompleteChartData chart2,
  ) {
    // Get Moon positions (Nakshatra 0-26, Rashi 0-11)
    int? nak1, nak2, rashi1, rashi2;

    for (final entry in chart1.baseChart.planets.entries) {
      if (entry.key.toString().toLowerCase().contains('moon')) {
        nak1 = (entry.value.longitude / (360.0 / 27.0)).floor();
        rashi1 = (entry.value.longitude / 30.0).floor();
        break;
      }
    }

    for (final entry in chart2.baseChart.planets.entries) {
      if (entry.key.toString().toLowerCase().contains('moon')) {
        nak2 = (entry.value.longitude / (360.0 / 27.0)).floor();
        rashi2 = (entry.value.longitude / 30.0).floor();
        break;
      }
    }

    if (nak1 == null || nak2 == null || rashi1 == null || rashi2 == null) {
      return NakshatraAnalysis(
        moon1Nakshatra: 'Unknown',
        moon2Nakshatra: 'Unknown',
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

    // 1. Varna (1 pt)
    double varna = _calculateVarna(rashi1, rashi2);

    // 2. Vashya (2 pts)
    double vashya = _calculateVashya(rashi1, rashi2);

    // 3. Tara (3 pts)
    double tara = _calculateTara(nak1, nak2);

    // 4. Yoni (4 pts)
    double yoni = _calculateYoniScore(nak1, nak2);

    // 5. Graha Maitri (5 pts)
    double maitri = _calculateMaitri(rashi1, rashi2);

    // 6. Gana (6 pts)
    double gana = _calculateGanaScore(nak1, nak2);

    // 7. Bhakoot (7 pts)
    double bhakoot = _calculateBhakoot(rashi1, rashi2);

    // 8. Nadi (8 pts)
    double nadi = _calculateNadiScore(nak1, nak2);

    final total = varna + vashya + tara + yoni + maitri + gana + bhakoot + nadi;

    return NakshatraAnalysis(
      moon1Nakshatra: AstrologyConstants.nakshatraNames[nak1 % 27],
      moon2Nakshatra: AstrologyConstants.nakshatraNames[nak2 % 27],
      varna: varna,
      vashya: vashya,
      tara: tara,
      yoni: yoni,
      maitri: maitri,
      gana: gana,
      bhakoot: bhakoot,
      nadi: nadi,
      totalScore: total,
    );
  }

  // --- Kuta Calculation Helpers ---

  static double _calculateVarna(int r1, int r2) {
    // 0=Brahmin (4,8,12), 1=Kshatriya (1,5,9), 2=Vaishya (2,6,10), 3=Shudra (3,7,11)
    // Actually:
    // Brahmin: Cancer(3), Scorpio(7), Pisces(11) -> Water
    // Kshatriya: Aries(0), Leo(4), Sag(8) -> Fire
    // Vaishya: Taurus(1), Virgo(5), Cap(9) -> Earth
    // Shudra: Gem(2), Lib(6), Aqu(10) -> Air

    // Check standard mapping:
    // Cancer, Scorpio, Pisces -> Brahmin
    // Aries, Leo, Sag -> Kshatriya
    // Taurus, Virgo, Cap -> Vaishya
    // Gemini, Libra, Aquarius -> Shudra

    int getVarna(int r) {
      if ([3, 7, 11].contains(r)) return 0;
      if ([0, 4, 8].contains(r)) return 1;
      if ([1, 5, 9].contains(r)) return 2;
      return 3;
    }

    int v1 = getVarna(r1);
    int v2 = getVarna(r2);

    // Bride should be equal or lower caste than Groom? Or just compatibility.
    // Rule: Groom >= Bride in grade (0 is highest, 3 lowest)
    // Wait, usually Brahmin=Highest. So if Groom <= Bride (index), full points.
    // Let's assume chart1=Groom/Male, chart2=Bride/Female for standard calculation
    // Or just generic: Higher grade (lower index) chart1 is good.
    if (v1 <= v2) return 1.0;
    return 0.0;
  }

  static double _calculateVashya(int r1, int r2) {
    // Full Vashya table: which signs are controlled by which
    final Map<int, List<int>> vashyaControl = {
      0: [0, 4, 7], // Aries controls: Aries, Leo, Scorpio
      1: [1, 3, 6], // Taurus: Taurus, Cancer, Libra
      2: [2, 5], // Gemini: Gemini, Virgo
      3: [3, 7], // Cancer: Cancer, Scorpio
      4: [0, 4, 8], // Leo: Aries, Leo, Sagittarius
      5: [1, 2, 5], // Virgo: Taurus, Gemini, Virgo
      6: [3, 6, 11], // Libra: Cancer, Libra, Pisces
      7: [3, 7], // Scorpio: Cancer, Scorpio
      8: [4, 8, 11], // Sagittarius: Leo, Sagittarius, Pisces
      9: [1, 5, 9, 10], // Capricorn: Taurus, Virgo, Capricorn, Aquarius
      10: [9, 10], // Aquarius: Capricorn, Aquarius
      11: [6, 8, 11], // Pisces: Libra, Sagittarius, Pisces
    };

    // Same sign = 2 points
    if (r1 == r2) return 2.0;

    // r1 controls r2 = 2 points
    if (vashyaControl[r1]?.contains(r2) == true) return 2.0;

    // r2 controls r1 = 1 point (partial)
    if (vashyaControl[r2]?.contains(r1) == true) return 1.0;

    // No Vashya = 0 points
    return 0.0;
  }

  static double _calculateTara(int n1, int n2) {
    // Bidirectional check as per tradition
    int dist1 = (n1 - n2 + 27) % 27;
    int dist2 = (n2 - n1 + 27) % 27;

    int rem1 = dist1 % 9;
    int rem2 = dist2 % 9;

    // Bad remainders: 3-Vipat, 5-Pratyak, 7-Naidhana
    bool bad1 = [3, 5, 7].contains(rem1);
    bool bad2 = [3, 5, 7].contains(rem2);

    // Both bad = 0, one bad = 1.5, both good = 3
    if (bad1 && bad2) return 0.0;
    if (bad1 || bad2) return 1.5;
    return 3.0;
  }

  static double _calculateYoniScore(int n1, int n2) {
    // Using string helper previously
    String res = _calculateYoni(n1, n2);
    if (res.contains('Excellent')) return 4.0;
    if (res.contains('Good')) return 3.0; // Friendly
    if (res.contains('moderate')) return 2.0;
    if (res.contains('Neutral')) return 2.0;
    return 1.0; // Enemy
    // 0 only for bitter enemies
  }

  static double _calculateMaitri(int r1, int r2) {
    // Graha Maitri based on planetary friendship
    String l1 = _getHouseLord(1, (r1 * 30.0));
    String l2 = _getHouseLord(1, (r2 * 30.0));

    if (l1 == l2) return 5.0; // Same lord = maximum points

    // Full planetary friendship table
    final Map<String, Map<String, String>> friendshipTable = {
      'Sun': {
        'Moon': 'friend',
        'Mars': 'friend',
        'Jupiter': 'friend',
        'Mercury': 'neutral',
        'Venus': 'enemy',
        'Saturn': 'enemy',
      },
      'Moon': {
        'Sun': 'friend',
        'Mercury': 'friend',
        'Mars': 'neutral',
        'Jupiter': 'neutral',
        'Venus': 'neutral',
        'Saturn': 'neutral',
      },
      'Mars': {
        'Sun': 'friend',
        'Moon': 'friend',
        'Jupiter': 'friend',
        'Venus': 'neutral',
        'Saturn': 'neutral',
        'Mercury': 'enemy',
      },
      'Mercury': {
        'Sun': 'friend',
        'Venus': 'friend',
        'Moon': 'enemy',
        'Mars': 'neutral',
        'Jupiter': 'neutral',
        'Saturn': 'neutral',
      },
      'Jupiter': {
        'Sun': 'friend',
        'Moon': 'friend',
        'Mars': 'friend',
        'Saturn': 'neutral',
        'Mercury': 'enemy',
        'Venus': 'enemy',
      },
      'Venus': {
        'Mercury': 'friend',
        'Saturn': 'friend',
        'Mars': 'neutral',
        'Jupiter': 'neutral',
        'Sun': 'enemy',
        'Moon': 'enemy',
      },
      'Saturn': {
        'Mercury': 'friend',
        'Venus': 'friend',
        'Jupiter': 'neutral',
        'Sun': 'enemy',
        'Moon': 'enemy',
        'Mars': 'enemy',
      },
    };

    String relationship = friendshipTable[l1]?[l2] ?? 'neutral';

    if (relationship == 'friend') return 5.0;
    if (relationship == 'neutral') return 3.0;
    return 0.0; // enemy
  }

  static double _calculateGanaScore(int n1, int n2) {
    String res = _calculateGana(n1, n2);
    if (res.contains('Excellent')) return 6.0;
    if (res.contains('Good')) return 3.0; // Or 5
    return 0.0; // Rakshasa-Deva/Manushya mismatch often 0 or 1
  }

  static double _calculateBhakoot(int r1, int r2) {
    int dist = (r1 - r2 + 12) % 12; // r2 to r1
    dist = dist + 1; // 1-based count

    // Bad: 2-12, 6-8, 5-9 (sometimes 9-5 is good, but 2-12 etc bad)
    // 6-8 (Shadushtaka): Bad
    // 2-12 (Dwidwadasha): Bad
    // 5-9 (NavamPancham): Good usually, but depends on Lords.
    // 1-1 (Same): Good
    // 3-11: Good
    // 4-10: Good

    if (dist == 1) return 7.0; // Same sign
    if (dist == 7) return 7.0; // Opposition
    if (dist == 3 || dist == 11) return 7.0;
    if (dist == 4 || dist == 10) return 7.0;

    // 2-12, 5-9, 6-8
    if (dist == 2 || dist == 12) return 0.0;
    if (dist == 6 || dist == 8) return 0.0;
    if (dist == 5 || dist == 9) return 0.0; // Often 0 in strict bhakoot

    return 0.0;
  }

  static double _calculateNadiScore(int n1, int n2) {
    String res = _calculateNadi(n1, n2);
    if (res.contains('Compatible')) return 8.0;
    return 0.0;
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

    // Add nakshatra score (Kuta Matching)
    // Map 36 points to a 20 point scale for overall compatibility mix?
    // Or just use points.
    // Previous logic: score += nakshatra.score * 0.3; (where score was approx 15)
    // New score is out of 36.
    // Let's add full Kuta points (max 36) to base score and clamp.
    score += nakshatra.totalScore;

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

/// Nakshatra Analysis (Kuta Matching)
class NakshatraAnalysis {
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

  /// Deprecated getters for backward compat if needed, simplified
  String get score => totalScore.toStringAsFixed(1);
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
