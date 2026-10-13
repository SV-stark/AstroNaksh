import 'dart:typed_data';

import 'package:jyotish/analysis.dart';
import 'package:jyotish/astronomy.dart';
import 'package:jyotish/core.dart';
import 'package:jyotish/strength.dart';
import 'package:jyotish/systems.dart';
import 'package:jyotish/transit.dart';

import '../core/ephemeris_manager.dart';

/// Enhanced Astrology Service providing advanced Vedic astrology features:
/// - Graha Avastha (planetary states: Baladi, Jagratadi, Deeptadi)
/// - Bhava Chalit (cuspal chart with mid-cusp boundaries)
/// - Sade Sati Timeline (past/future Saturn transit periods)
/// - Career Analysis (D10 Dashamsha)
/// - Ashtakavarga Prastara (individual planet bindu grids)
/// - Prashna (horary) Sphutas and Arudha
/// - Planetary visibility and Jovian year number
/// - Comprehensive Chart Strength Report (Shadbala + Vimshopak + Bhava Bala)
class EnhancedAstrologyService {
  final Jyotish _jyotish = EphemerisManager.jyotish;

  // ===========================================================================
  // 1. Graha Avastha (Planetary States)
  // ===========================================================================

  /// Calculate Graha Avastha for all planets in the chart.
  ///
  /// Returns a map of each planet to its combined Avastha state, including:
  /// - Baladi Avastha (age-based: bala, kumara, yuva, vriddha, mrita)
  /// - Jagratadi Avastha (consciousness: jagrata, svapna, sushupti)
  /// - Deeptadi Avastha (mood/condition: deepta through kopa)
  Map<Planet, GrahaAvastha> calculateGrahaAvasthas(VedicChart chart) {
    final service = _jyotish.grahaAvastha;
    try {
      return service.calculateAllAvasthas(chart);
    } catch (_) {
      return {};
    }
  }

  /// Calculate Graha Avastha for a specific planet.
  ///
  /// If the planet is not found in the chart, returns a default
  /// Mrita/Sushupti avastha with reduced strength (0.25).
  GrahaAvastha calculateGrahaAvastha(VedicChart chart, Planet planet) {
    final service = _jyotish.grahaAvastha;
    try {
      final planetInfo = chart.getPlanet(planet);
      if (planetInfo == null) {
        return const GrahaAvastha(
          baladi: BaladiAvastha.mrita,
          jagratadi: JagratadiAvastha.sushupti,
          deeptadi: DeeptadiAvastha.vikala,
          effectStrength: 0.25,
          description: 'Mrita, Sushupti, Vikala (default for missing planet)',
        );
      }
      return service.calculateAvastha(planetInfo);
    } catch (_) {
      return const GrahaAvastha(
        baladi: BaladiAvastha.mrita,
        jagratadi: JagratadiAvastha.sushupti,
        deeptadi: DeeptadiAvastha.vikala,
        effectStrength: 0.25,
        description: 'Mrita, Sushupti, Vikala (fallback)',
      );
    }
  }

  // ===========================================================================
  // 2. Bhava Chalit (Cuspal Chart)
  // ===========================================================================

  /// Calculate Bhava Chalit (cuspal chart) for the given chart.
  ///
  /// Bhava Chalit redistributes planets to houses based on mid-cusp
  /// boundaries rather than fixed 30-degree sign boundaries. This is
  /// especially significant in non-Whole-Sign house systems.
  BhavaChalit calculateBhavaChalit(VedicChart chart) {
    final service = _jyotish.bhavaChalit;
    try {
      return service.calculateBhavaChalit(chart);
    } catch (_) {
      return BhavaChalit(bhavas: const [], chart: chart);
    }
  }

  /// Get planets whose Bhava Chalit house differs from their Rashi house.
  ///
  /// These are the "shifted" planets -- the key deliverable of Bhava Chalit.
  List<({Planet planet, int rashiHouse, int bhavaHouse})> getShiftedPlanets(
    VedicChart chart,
  ) {
    try {
      final chalit = calculateBhavaChalit(chart);
      return chalit.shiftedPlanets;
    } catch (_) {
      return [];
    }
  }

  // ===========================================================================
  // 3. Sade Sati Timeline (Special Transits)
  // ===========================================================================

  /// Predict Sade Sati periods (past and future) for a natal chart.
  ///
  /// Sade Sati is Saturn's 7.5-year transit through the 12th, 1st, and 2nd
  /// houses from the natal Moon. Returns a list of period maps containing:
  /// - 'start' (DateTime): period start date
  /// - 'end' (DateTime): period end date
  /// - 'phase' (String): 'Rising', 'Peak', or 'Setting'
  /// - 'houseFromMoon' (int): 12, 1, or 2
  List<Map<String, dynamic>> predictSadeSatiPeriods({
    required VedicChart natalChart,
    required DateTime onDate,
    int yearsBefore = 5,
    int yearsAfter = 5,
  }) {
    try {
      final service = SpecialTransitService(EphemerisManager.service);
      return service.predictSadeSatiPeriods(
        natalChart,
        yearsBefore: yearsBefore,
        yearsAfter: yearsAfter,
      );
    } catch (_) {
      return [];
    }
  }

  /// Calculate current Sade Sati status (active phase and progress).
  ///
  /// Returns the [SadeSatiStatus] with phase, progress, and date range.
  Future<SadeSatiStatus?> calculateSadeSatiStatus({
    required VedicChart natalChart,
    required DateTime onDate,
    required GeographicLocation location,
  }) async {
    try {
      final service = SpecialTransitService(EphemerisManager.service);
      final natalMoon = natalChart.planets[Planet.moon];
      if (natalMoon == null) return null;

      final saturnPos = await _jyotish.ephemeris.calculatePlanetPosition(
        planet: Planet.saturn,
        dateTime: onDate,
        location: location,
        flags: CalculationFlags.modernPrecision(),
      );
      return await service.calculateSadeSati(
        natalMoonLongitude: natalMoon.position.longitude,
        transitSaturnLongitude: saturnPos.longitude,
        checkDate: onDate,
      );
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // 4. Career Analysis (D10 Dashamsha)
  // ===========================================================================

  /// Calculate career analysis from D10 (Dashamsha) chart.
  ///
  /// Uses the D10 chart as the primary input, cross-referenced with the D1
  /// Rashi chart for additional context. Returns a [CareerAnalysisResult]
  /// with primary/secondary career domains, work style, strengths, and
  /// challenges.
  CareerAnalysisResult getD10CareerAnalysis({
    required VedicChart d10Chart,
    required VedicChart d1Chart,
  }) {
    try {
      final service = _jyotish.careerAnalysis;
      final analysis = service.analyzeCareer(d10Chart);

      // Derive secondary career domains from strong planets (beyond primary)
      final secondaryCareers = <String>[];
      for (final planet in analysis.strongPlanets) {
        if (planet != analysis.tenthLord) {
          secondaryCareers.addAll(_getPlanetCareerDomains(planet));
        }
      }

      // Determine work style from the D10 ascendant sign and 10th lord
      final workStyle = _deriveWorkStyle(
        analysis.tenthLord,
        analysis.tenthSign,
      );

      // Extract strengths from career themes
      final strengths = analysis.careerThemes
          .where((t) => !t.toLowerCase().contains('challenge'))
          .toList();

      // Derive challenges from the overall strength category
      final challenges = _deriveChallenges(analysis.overallStrength);

      return CareerAnalysisResult(
        primaryCareer: analysis.primaryDomains.isNotEmpty
            ? analysis.primaryDomains.first
            : 'General Professional Work',
        secondaryCareers: secondaryCareers.take(4).toList(),
        workStyle: workStyle,
        strengths: strengths.isNotEmpty ? strengths : ['Balanced D-10 chart'],
        challenges: challenges.isNotEmpty
            ? challenges
            : ['No major D-10 challenges detected'],
      );
    } catch (_) {
      return const CareerAnalysisResult(
        primaryCareer: 'Professional Career',
        secondaryCareers: [],
        workStyle: 'Balanced and methodical',
        strengths: ['D-10 chart analysis available'],
        challenges: [],
      );
    }
  }

  /// Derive a work-style description from the 10th lord and sign.
  String _deriveWorkStyle(Planet tenthLord, Rashi tenthSign) {
    final lordStyle = switch (tenthLord) {
      Planet.sun => 'authoritative and leadership-oriented',
      Planet.moon => 'people-focused and adaptive',
      Planet.mars => 'driven and action-oriented',
      Planet.mercury => 'analytical and communication-focused',
      Planet.jupiter => 'advisory and wisdom-guided',
      Planet.venus => 'creative and relationship-oriented',
      Planet.saturn => 'disciplined and structured',
      _ => 'balanced',
    };
    final signElement = _getSignElement(tenthSign);
    return '$lordStyle with a $signElement-element approach';
  }

  /// Derive challenge descriptions from the D10 strength category.
  List<String> _deriveChallenges(D10StrengthCategory category) {
    return switch (category) {
      D10StrengthCategory.excellent => [
        'Avoid overconfidence in professional matters',
      ],
      D10StrengthCategory.good => [
        'Minor obstacles that can be overcome with effort',
      ],
      D10StrengthCategory.average => [
        'Steady effort required for career growth',
      ],
      D10StrengthCategory.challenging => [
        'Significant professional obstacles expected',
        'Perseverance and patience are essential',
      ],
    };
  }

  /// Get the element (fire, earth, air, water) for a Rashi.
  String _getSignElement(Rashi rashi) {
    return switch (rashi) {
      Rashi.aries || Rashi.leo || Rashi.sagittarius => 'fire',
      Rashi.taurus || Rashi.virgo || Rashi.capricorn => 'earth',
      Rashi.gemini || Rashi.libra || Rashi.aquarius => 'air',
      Rashi.cancer || Rashi.scorpio || Rashi.pisces => 'water',
    };
  }

  /// Get career domain keywords for a planet.
  List<String> _getPlanetCareerDomains(Planet planet) {
    return switch (planet) {
      Planet.sun => ['Government', 'Authority', 'Management', 'Politics'],
      Planet.moon => ['Public Relations', 'Caregiving', 'Food/Hospitality'],
      Planet.mars => [
        'Engineering',
        'Military/Police',
        'Surgeon',
        'Real Estate',
      ],
      Planet.mercury => [
        'Business',
        'Writing/Media',
        'IT/Programming',
        'Accounting',
      ],
      Planet.jupiter => [
        'Education/Teaching',
        'Law',
        'Finance/Banking',
        'Advisory',
      ],
      Planet.venus => ['Arts/Entertainment', 'Fashion', 'Luxury', 'Design'],
      Planet.saturn => [
        'Service Sector',
        'Research',
        'Heavy Industry',
        'Agriculture',
      ],
      _ => [],
    };
  }

  // ===========================================================================
  // 5. Ashtakavarga Prastara (Individual Planet Grids)
  // ===========================================================================

  /// Calculate the Prastara Ashtakavarga grid for a specific planet.
  ///
  /// Returns a [PrastaraResult] with the 96-cell binary contribution
  /// matrix (8 contributors x 12 signs). Each cell is 1 (bindu) or 0 (rekha).
  ///
  /// The 8 contributors are: Sun, Moon, Mars, Mercury, Jupiter, Venus,
  /// Saturn, and Lagna (Ascendant).
  PrastaraResult calculatePrastaraAshtakavarga({
    required VedicChart chart,
    required Planet planet,
  }) {
    try {
      final service = _jyotish.ashtakavarga;
      return service.calculatePrastaraAshtakavarga(chart, planet);
    } catch (_) {
      return PrastaraResult(planet: planet, grid: Uint8List(96));
    }
  }

  /// Calculate Prastara Ashtakavarga for all seven grahas.
  ///
  /// Returns a map of planet to its Prastara result.
  Map<Planet, PrastaraResult> calculateAllPrastaraAshtakavarga(
    VedicChart chart,
  ) {
    final service = _jyotish.ashtakavarga;
    final results = <Planet, PrastaraResult>{};
    final planets = [
      Planet.sun,
      Planet.moon,
      Planet.mars,
      Planet.mercury,
      Planet.jupiter,
      Planet.venus,
      Planet.saturn,
    ];
    for (final planet in planets) {
      try {
        results[planet] = service.calculatePrastaraAshtakavarga(chart, planet);
      } catch (_) {
        results[planet] = PrastaraResult(planet: planet, grid: Uint8List(96));
      }
    }
    return results;
  }

  /// Get bindus per sign for a specific planet's Prastara result.
  ///
  /// Returns a list of 12 integers (one per sign) with bindu counts.
  List<int> getBindusPerSign(PrastaraResult result) {
    final bindus = <int>[];
    for (var sign = 0; sign < 12; sign++) {
      var count = 0;
      for (var point = 0; point < 8; point++) {
        count += result.getContribution(point, sign);
      }
      bindus.add(count);
    }
    return bindus;
  }

  /// Get total bindus across all signs for a Prastara result.
  int getTotalBindus(PrastaraResult result) {
    var total = 0;
    for (var sign = 0; sign < 12; sign++) {
      for (var point = 0; point < 8; point++) {
        total += result.getContribution(point, sign);
      }
    }
    return total;
  }

  // ===========================================================================
  // 6. Prashna (Horary) Calculations
  // ===========================================================================

  /// Calculate Prashna Sphutas (special horary points).
  ///
  /// Returns [PrashnaSphutas] with:
  /// - Trisphuta = Lagna + Moon + Gulika
  /// - Chatursphuta = Trisphuta + Sun
  /// - Panchasphuta = Chatursphuta + Rahu
  Future<PrashnaSphutas> calculateSphutas({required VedicChart chart}) async {
    final service = _jyotish.prashna;
    try {
      return await service.calculateSphutas(chart);
    } catch (_) {
      return PrashnaSphutas(
        trisphuta: chart.ascendant,
        chatursphuta: chart.ascendant,
        panchasphuta: chart.ascendant,
      );
    }
  }

  /// Calculate Gulika Sphuta (the ascendant at the start of Saturn's
  /// planetary segment for the given chart time).
  ///
  /// Gulika is used in Prashna to determine the outcome of queries.
  Future<double> calculateGulikaSphuta({required VedicChart chart}) async {
    final service = _jyotish.prashna;
    try {
      return await service.calculateGulikaSphuta(chart);
    } catch (_) {
      return chart.ascendant;
    }
  }

  /// Calculate the Prashna Arudha (rising sign for horary analysis) from
  /// a seed number (1-249).
  ///
  /// Returns the Rashi index (0-11) corresponding to the Arudha Lagna.
  /// Uses the standard formula: (seed - 1) % 12.
  int calculatePrashnaArudha({required VedicChart chart}) {
    final service = _jyotish.prashna;
    try {
      // Use a default seed derived from the chart's Moon longitude
      final moon = chart.getPlanet(Planet.moon);
      final seed = moon != null
          ? (moon.position.longitude.floor() % 249) + 1
          : 1;
      final rashi = service.calculatePrashnaArudha(seed);
      return rashi.number - 1; // Convert to 0-based index
    } catch (_) {
      return 0; // Default to Aries
    }
  }

  /// Calculate the full Prashna Arudha Rashi (not just the index).
  Rashi calculatePrashnaArudhaRashi({required VedicChart chart}) {
    final index = calculatePrashnaArudha(chart: chart);
    return Rashi.values[index];
  }

  // ===========================================================================
  // 7. Jyotish Facade: Planetary Visibility & Varsha Number
  // ===========================================================================

  /// Get planetary visibility information for a specific date, time,
  /// and location.
  ///
  /// Returns [PlanetVisibility] with:
  /// - isVisible (bool): whether the planet is above the horizon
  /// - elongation (double): angular distance from the Sun in degrees
  Future<PlanetVisibility> getPlanetVisibility({
    required DateTime dateTime,
    required GeographicLocation location,
    required Planet planet,
  }) {
    return _jyotish.getPlanetVisibility(
      date: dateTime,
      location: location,
      planet: planet,
    );
  }

  /// Get the current Jovian Samvatsara varsha number (1-60).
  ///
  /// The 60-year Jovian cycle starts with Prabhava (1) and ends with
  /// Akshaya (60). This is used in Varshaphal (annual horoscope).
  int getCurrentVarshaNumber({required DateTime dateTime}) {
    return Jyotish.getCurrentVarshaNumber(dateTime);
  }

  /// Get the Jovian year name for a given date.
  String getVarshaName(DateTime dateTime) {
    final number = getCurrentVarshaNumber(dateTime: dateTime);
    return _jovianYearNames[number - 1];
  }

  static const List<String> _jovianYearNames = [
    'Prabhava',
    'Vibhava',
    'Shukla',
    'Pramoda',
    'Prajapati',
    'Angirasa',
    'Shrimukha',
    'Bhava',
    'Yuva',
    'Dhata',
    'Ishvara',
    'Bahudhanya',
    'Pramadhi',
    'Vikrama',
    'Vishu',
    'Chitrabanu',
    'Subhanu',
    'Tarana',
    'Parthiva',
    'Vyaya',
    'Sarvajith',
    'Virodhi',
    'Vikrita',
    'Kara',
    'Nandana',
    'Vijaya',
    'Jaya',
    'Manmatha',
    'Dhunmukhi',
    'Hevalambi',
    'Vilambi',
    'Vikari',
    'Sharvari',
    'Plava',
    'Shubhakritu',
    'Shobhakruthu',
    'Krodhi',
    'Vishvavasu',
    'Parabhava',
    'Plavanga',
    'Keela',
    'Saumya',
    'Sadharana',
    'Virodhikritu',
    'Paridhavi',
    'Pramaadicha',
    'Ananda',
    'Rakshasa',
    'Nala',
    'Pingala',
    'Kalayukti',
    'Siddharthi',
    'Raudhri',
    'Durmati',
    'Dundhubi',
    'Rudhrodhgari',
    'Raktakshi',
    'Krodhana',
    'Akshaya',
  ];

  // ===========================================================================
  // 8. Comprehensive Chart Strength Report
  // ===========================================================================

  /// Generate a comprehensive chart strength report combining:
  /// - Shadbala (six-fold planetary strength)
  /// - Vimshopak Bala (20-fold divisional strength)
  /// - Bhava Bala (house strength)
  ///
  /// Returns a [ChartStrengthReport] with individual planet strengths,
  /// house strengths, overall chart assessment, and recommendations.
  Future<ChartStrengthReport> getChartStrengthReport(VedicChart chart) async {
    // --- Shadbala ---
    final shadbala = <Planet, double>{};
    final detailedShadbala = <Planet, ShadbalaResult>{};
    try {
      final results = await _jyotish.getShadbala(chart);
      detailedShadbala.addAll(results);
      for (final entry in results.entries) {
        if (!Planet.lunarNodes.contains(entry.key)) {
          shadbala[entry.key] = entry.value.totalBala;
        }
      }
    } catch (_) {}

    // --- Vimshopak Bala ---
    final vimshopak = <Planet, VimshopakBala>{};
    try {
      final strengthService = _jyotish.strengthAnalysis;
      final allVimshopak = strengthService.getAllPlanetsVimshopakBala(chart);
      vimshopak.addAll(allVimshopak);
    } catch (_) {}

    // --- Bhava Bala ---
    final bhavaBala = <int, double>{};
    try {
      final strengthService = _jyotish.strengthAnalysis;
      final shadbalaForBhava = <Planet, double>{};
      detailedShadbala.forEach((planet, result) {
        shadbalaForBhava[planet] = result.totalBala;
      });
      final bhavaResults = strengthService.getBhavaBala(
        chart: chart,
        shadbalaResults: shadbalaForBhava,
      );
      for (var house = 1; house <= 12; house++) {
        bhavaBala[house] = bhavaResults[house] ?? 50.0;
      }
    } catch (_) {
      for (var house = 1; house <= 12; house++) {
        bhavaBala[house] = 50.0;
      }
    }

    // --- Calculate overall chart strength ---
    final planetStrengthAvg = shadbala.isNotEmpty
        ? shadbala.values.reduce((a, b) => a + b) / shadbala.length
        : 0.0;
    final houseStrengthAvg = bhavaBala.isNotEmpty
        ? bhavaBala.values.reduce((a, b) => a + b) / bhavaBala.length
        : 0.0;
    final vimshopakAvg = vimshopak.isNotEmpty
        ? vimshopak.values.map((v) => v.totalScore).reduce((a, b) => a + b) /
              vimshopak.length
        : 0.0;

    // Normalize to 0-100 scale
    final normalizedPlanetStrength = (planetStrengthAvg / 600.0 * 100)
        .clamp(0.0, 100.0)
        .toDouble();
    final normalizedHouseStrength = houseStrengthAvg
        .clamp(0.0, 100.0)
        .toDouble();
    final normalizedVimshopak = vimshopakAvg.clamp(0.0, 100.0).toDouble();

    final overallScore =
        (normalizedPlanetStrength * 0.4 +
                normalizedHouseStrength * 0.35 +
                normalizedVimshopak * 0.25)
            .clamp(0.0, 100.0)
            .toDouble();

    // --- Identify strongest and weakest planets ---
    Planet? strongestPlanet;
    Planet? weakestPlanet;
    if (shadbala.isNotEmpty) {
      var maxStrength = double.negativeInfinity;
      var minStrength = double.infinity;
      for (final entry in shadbala.entries) {
        if (entry.value > maxStrength) {
          maxStrength = entry.value;
          strongestPlanet = entry.key;
        }
        if (entry.value < minStrength) {
          minStrength = entry.value;
          weakestPlanet = entry.key;
        }
      }
    }

    // --- Identify strongest and weakest houses ---
    int? strongestHouse;
    int? weakestHouse;
    if (bhavaBala.isNotEmpty) {
      var maxStrength = double.negativeInfinity;
      var minStrength = double.infinity;
      for (final entry in bhavaBala.entries) {
        if (entry.value > maxStrength) {
          maxStrength = entry.value;
          strongestHouse = entry.key;
        }
        if (entry.value < minStrength) {
          minStrength = entry.value;
          weakestHouse = entry.key;
        }
      }
    }

    // --- Generate recommendations ---
    final recommendations = _generateStrengthRecommendations(
      overallScore: overallScore,
      weakestPlanet: weakestPlanet,
      weakestHouse: weakestHouse,
      shadbala: shadbala,
      bhavaBala: bhavaBala,
    );

    return ChartStrengthReport(
      chart: chart,
      shadbala: shadbala,
      detailedShadbala: detailedShadbala,
      vimshopak: vimshopak,
      bhavaBala: bhavaBala,
      overallScore: overallScore,
      normalizedPlanetStrength: normalizedPlanetStrength,
      normalizedHouseStrength: normalizedHouseStrength,
      normalizedVimshopak: normalizedVimshopak,
      strongestPlanet: strongestPlanet,
      weakestPlanet: weakestPlanet,
      strongestHouse: strongestHouse,
      weakestHouse: weakestHouse,
      recommendations: recommendations,
    );
  }

  /// Generate actionable recommendations based on the strength analysis.
  List<String> _generateStrengthRecommendations({
    required double overallScore,
    Planet? weakestPlanet,
    int? weakestHouse,
    required Map<Planet, double> shadbala,
    required Map<int, double> bhavaBala,
  }) {
    final recommendations = <String>[];

    // Overall chart strength
    if (overallScore >= 70) {
      recommendations.add(
        'Strong overall chart -- favorable for most endeavors.',
      );
    } else if (overallScore >= 40) {
      recommendations.add(
        'Moderate chart strength -- remedial measures recommended.',
      );
    } else {
      recommendations.add(
        'Weak chart strength -- focus on remedial measures and mantra practice.',
      );
    }

    // Weakest planet guidance
    if (weakestPlanet != null) {
      final strength = shadbala[weakestPlanet] ?? 0;
      recommendations.add(
        '${weakestPlanet.displayName} is the weakest planet '
        '(${strength.toStringAsFixed(1)} Shadbala). Consider wearing '
        '${_getGemstoneForPlanet(weakestPlanet)} and reciting '
        '${_getMantraForPlanet(weakestPlanet)}.',
      );
    }

    // Weakest house guidance
    if (weakestHouse != null) {
      final houseName = _getHouseName(weakestHouse);
      recommendations.add(
        'The $houseName is the weakest area. Strengthen it through '
        'relevant remedies and conscious focus.',
      );
    }

    // Strongest planet advantage
    if (shadbala.isNotEmpty) {
      final strongest = shadbala.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      recommendations.add(
        'Leverage the strong ${strongest.key.displayName} '
        '(${strongest.value.toStringAsFixed(1)} Shadbala) for favorable outcomes.',
      );
    }

    return recommendations;
  }

  /// Get gemstone recommendation for a planet.
  String _getGemstoneForPlanet(Planet planet) {
    return switch (planet) {
      Planet.sun => 'Ruby (Manikya)',
      Planet.moon => 'Pearl (Moti)',
      Planet.mars => 'Red Coral (Moonga)',
      Planet.mercury => 'Emerald (Panna)',
      Planet.jupiter => 'Yellow Sapphire (Pukhraj)',
      Planet.venus => 'Diamond (Heera)',
      Planet.saturn => 'Blue Sapphire (Neelam)',
      _ => 'a suitable gemstone',
    };
  }

  /// Get mantra recommendation for a planet.
  String _getMantraForPlanet(Planet planet) {
    return switch (planet) {
      Planet.sun => 'Om Suryaya Namah (108 times)',
      Planet.moon => 'Om Somaya Namah (108 times)',
      Planet.mars => 'Om Angarakaya Namah (108 times)',
      Planet.mercury => 'Om Budhaya Namah (108 times)',
      Planet.jupiter => 'Om Gurave Namah (108 times)',
      Planet.venus => 'Om Shukraya Namah (108 times)',
      Planet.saturn => 'Om Sham Shanicharaya Namah (108 times)',
      _ => 'its respective mantra',
    };
  }

  /// Get a human-readable name for a house number.
  static String _getHouseName(int house) {
    const names = [
      '1st House (Self)',
      '2nd House (Wealth)',
      '3rd House (Siblings/Courage)',
      '4th House (Home/Happiness)',
      '5th House (Children/Intelligence)',
      '6th House (Health/Enemies)',
      '7th House (Spouse/Partnerships)',
      '8th House (Longevity/Transformation)',
      '9th House (Fortune/Dharma)',
      '10th House (Career/Status)',
      '11th House (Gains/Desires)',
      '12th House (Losses/Spirituality)',
    ];
    return names[house - 1];
  }
}

// =============================================================================
// Supporting Data Classes
// =============================================================================

/// Comprehensive career analysis result.
class CareerAnalysisResult {
  const CareerAnalysisResult({
    required this.primaryCareer,
    required this.secondaryCareers,
    required this.workStyle,
    required this.strengths,
    required this.challenges,
  });

  /// Primary career domain indicated by the D-10 chart.
  final String primaryCareer;

  /// Secondary career fields suggested by strong planets.
  final List<String> secondaryCareers;

  /// Description of the native's professional work style.
  final String workStyle;

  /// Key career strengths derived from the D-10 chart.
  final List<String> strengths;

  /// Career challenges to be aware of.
  final List<String> challenges;
}

/// Comprehensive chart strength report combining all strength systems.
class ChartStrengthReport {
  const ChartStrengthReport({
    required this.chart,
    required this.shadbala,
    required this.detailedShadbala,
    required this.vimshopak,
    required this.bhavaBala,
    required this.overallScore,
    required this.normalizedPlanetStrength,
    required this.normalizedHouseStrength,
    required this.normalizedVimshopak,
    required this.strongestPlanet,
    required this.weakestPlanet,
    required this.strongestHouse,
    required this.weakestHouse,
    required this.recommendations,
  });

  /// The source chart.
  final VedicChart chart;

  /// Shadbala values (0-600 scale) for each planet.
  final Map<Planet, double> shadbala;

  /// Detailed Shadbala breakdown for each planet.
  final Map<Planet, ShadbalaResult> detailedShadbala;

  /// Vimshopak Bala for each planet.
  final Map<Planet, VimshopakBala> vimshopak;

  /// Bhava Bala (house strength) for each house (1-12).
  final Map<int, double> bhavaBala;

  /// Overall chart strength score (0-100).
  final double overallScore;

  /// Normalized planetary strength (0-100).
  final double normalizedPlanetStrength;

  /// Normalized house strength (0-100).
  final double normalizedHouseStrength;

  /// Normalized Vimshopak strength (0-100).
  final double normalizedVimshopak;

  /// The strongest planet by Shadbala.
  final Planet? strongestPlanet;

  /// The weakest planet by Shadbala.
  final Planet? weakestPlanet;

  /// The strongest house by Bhava Bala.
  final int? strongestHouse;

  /// The weakest house by Bhava Bala.
  final int? weakestHouse;

  /// Actionable recommendations based on the analysis.
  final List<String> recommendations;

  /// Get a letter grade for the overall chart strength.
  String get overallGrade {
    if (overallScore >= 80) return 'A+';
    if (overallScore >= 70) return 'A';
    if (overallScore >= 60) return 'B';
    if (overallScore >= 50) return 'C';
    if (overallScore >= 40) return 'D';
    return 'F';
  }

  /// Get a human-readable strength label.
  String get strengthLabel {
    if (overallScore >= 80) return 'Very Strong';
    if (overallScore >= 60) return 'Strong';
    if (overallScore >= 40) return 'Moderate';
    if (overallScore >= 20) return 'Weak';
    return 'Very Weak';
  }
}
