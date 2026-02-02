import 'package:jyotish/jyotish.dart';
import '../data/models.dart';
import '../core/ephemeris_manager.dart';

/// Transit Analysis (Gochara) System
/// Analyzes current planetary positions relative to natal chart
class TransitAnalysis {
  final Jyotish _jyotish = EphemerisManager.jyotish;

  /// Calculate transit chart for a specific date
  Future<TransitChart> calculateTransitChart(
    CompleteChartData natalChart,
    DateTime transitDate,
  ) async {
    await EphemerisManager.ensureEphemerisData();

    // Calculate transit positions
    final transitPositions = await _jyotish.calculateVedicChart(
      dateTime: transitDate,
      location: GeographicLocation(
        latitude: natalChart.birthData.location.latitude,
        longitude: natalChart.birthData.location.longitude,
        altitude: 0,
      ),
    );

    // Calculate aspects and effects
    final aspects = _calculateTransitAspects(natalChart, transitPositions);
    final gochara = _calculateGocharaPositions(natalChart, transitPositions);
    final moonTransit = _analyzeMoonTransit(natalChart, transitPositions);
    final saturnTransit = _analyzeSaturnTransit(natalChart, transitPositions);
    final jupiterTransit = _analyzeJupiterTransit(natalChart, transitPositions);
    final rahuKetuTransit = _analyzeRahuKetuTransit(
      natalChart,
      transitPositions,
    );

    return TransitChart(
      transitDate: transitDate,
      natalChart: natalChart,
      transitPositions: transitPositions,
      aspects: aspects,
      gochara: gochara,
      moonTransit: moonTransit,
      saturnTransit: saturnTransit,
      jupiterTransit: jupiterTransit,
      rahuKetuTransit: rahuKetuTransit,
    );
  }

  /// Calculate transit aspects to natal chart
  List<TransitAspect> _calculateTransitAspects(
    CompleteChartData natalChart,
    VedicChart transitChart,
  ) {
    final aspects = <TransitAspect>[];
    const aspectOrbs = {
      'conjunction': 10.0,
      'sextile': 6.0,
      'square': 8.0,
      'trine': 8.0,
      'opposition': 10.0,
    };

    // Check all transit planets against all natal planets
    transitChart.planets.forEach((transitPlanet, transitInfo) {
      natalChart.baseChart.planets.forEach((natalPlanet, natalInfo) {
        final angle = _normalizeAngle(
          transitInfo.longitude - natalInfo.longitude,
        );

        // Check for major aspects
        if (angle <= aspectOrbs['conjunction']! ||
            angle >= 360 - aspectOrbs['conjunction']!) {
          aspects.add(
            TransitAspect(
              transitPlanet: transitPlanet,
              natalPlanet: natalPlanet,
              aspectType: AspectType.conjunction,
              orb: angle > 180 ? 360 - angle : angle,
              isApplying: _isApplying(transitInfo, natalInfo),
              effect: _calculateAspectEffect(
                transitPlanet,
                natalPlanet,
                AspectType.conjunction,
                natalChart,
              ),
            ),
          );
        } else if (_isWithinOrb(angle, 60, aspectOrbs['sextile']!)) {
          aspects.add(
            TransitAspect(
              transitPlanet: transitPlanet,
              natalPlanet: natalPlanet,
              aspectType: AspectType.sextile,
              orb: _calculateOrb(angle, 60),
              isApplying: _isApplying(transitInfo, natalInfo),
              effect: _calculateAspectEffect(
                transitPlanet,
                natalPlanet,
                AspectType.sextile,
                natalChart,
              ),
            ),
          );
        } else if (_isWithinOrb(angle, 90, aspectOrbs['square']!)) {
          aspects.add(
            TransitAspect(
              transitPlanet: transitPlanet,
              natalPlanet: natalPlanet,
              aspectType: AspectType.square,
              orb: _calculateOrb(angle, 90),
              isApplying: _isApplying(transitInfo, natalInfo),
              effect: _calculateAspectEffect(
                transitPlanet,
                natalPlanet,
                AspectType.square,
                natalChart,
              ),
            ),
          );
        } else if (_isWithinOrb(angle, 120, aspectOrbs['trine']!)) {
          aspects.add(
            TransitAspect(
              transitPlanet: transitPlanet,
              natalPlanet: natalPlanet,
              aspectType: AspectType.trine,
              orb: _calculateOrb(angle, 120),
              isApplying: _isApplying(transitInfo, natalInfo),
              effect: _calculateAspectEffect(
                transitPlanet,
                natalPlanet,
                AspectType.trine,
                natalChart,
              ),
            ),
          );
        } else if (_isWithinOrb(angle, 180, aspectOrbs['opposition']!)) {
          aspects.add(
            TransitAspect(
              transitPlanet: transitPlanet,
              natalPlanet: natalPlanet,
              aspectType: AspectType.opposition,
              orb: _calculateOrb(angle, 180),
              isApplying: _isApplying(transitInfo, natalInfo),
              effect: _calculateAspectEffect(
                transitPlanet,
                natalPlanet,
                AspectType.opposition,
                natalChart,
              ),
            ),
          );
        }
      });
    });

    // Sort by effect strength (orb size)
    aspects.sort((a, b) => a.orb.compareTo(b.orb));
    return aspects;
  }

  /// Calculate Gochara (house transit) positions
  GocharaPositions _calculateGocharaPositions(
    CompleteChartData natalChart,
    VedicChart transitChart,
  ) {
    final positions = <Planet, int>{};

    // Get natal Moon position for Gochara calculation
    Planet? moonPlanet;
    double moonLongitude = 0;
    for (final entry in natalChart.baseChart.planets.entries) {
      if (entry.key.toString().toLowerCase().contains('moon')) {
        moonPlanet = entry.key;
        moonLongitude = entry.value.longitude;
        break;
      }
    }

    if (moonPlanet != null) {
      final moonSign = (moonLongitude / 30).floor();

      transitChart.planets.forEach((planet, info) {
        final transitSign = (info.longitude / 30).floor();
        // Calculate house from Moon
        final houseFromMoon = ((transitSign - moonSign + 12) % 12) + 1;
        positions[planet] = houseFromMoon;
      });
    }

    return GocharaPositions(
      positions: positions,
      moonSign: moonPlanet != null ? (moonLongitude / 30).floor() : 0,
    );
  }

  /// Analyze Moon transit - most important for daily predictions
  MoonTransitAnalysis _analyzeMoonTransit(
    CompleteChartData natalChart,
    VedicChart transitChart,
  ) {
    Planet? transitMoon;
    double transitMoonLongitude = 0;
    Planet? natalMoon;
    double natalMoonLongitude = 0;

    // Find Moon in both charts
    for (final entry in transitChart.planets.entries) {
      if (entry.key.toString().toLowerCase().contains('moon')) {
        transitMoon = entry.key;
        transitMoonLongitude = entry.value.longitude;
        break;
      }
    }

    for (final entry in natalChart.baseChart.planets.entries) {
      if (entry.key.toString().toLowerCase().contains('moon')) {
        natalMoon = entry.key;
        natalMoonLongitude = entry.value.longitude;
        break;
      }
    }

    if (transitMoon == null || natalMoon == null) {
      return MoonTransitAnalysis(
        transitSign: 0,
        houseFromNatalMoon: 0,
        tithi: 0,
        nakshatra: '',
        isFavorable: false,
        recommendations: ['Moon position not available'],
      );
    }

    // Calculate tithi (lunar day) - normalize moon-sun difference to 0-360
    final sunLongitude = transitChart.planets.entries
        .firstWhere((e) => e.key.toString().toLowerCase().contains('sun'))
        .value
        .longitude;
    // Normalize difference to 0-360 range
    final moonSunDiff = (transitMoonLongitude - sunLongitude + 360) % 360;
    // Each tithi is 12 degrees of moon-sun separation (360/30 = 12)
    final tithi = (moonSunDiff / 12).floor() + 1; // Tithi 1-30

    // Calculate nakshatra
    final nakshatraIndex = (transitMoonLongitude / (360.0 / 27.0)).floor();
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

    // Calculate house from natal Moon
    final transitSign = (transitMoonLongitude / 30).floor();
    final natalMoonSign = (natalMoonLongitude / 30).floor();
    final houseFromNatalMoon = ((transitSign - natalMoonSign + 12) % 12) + 1;

    // Determine if favorable
    final favorableHouses = [1, 3, 6, 10, 11];
    final isFavorable = favorableHouses.contains(houseFromNatalMoon);

    // Generate recommendations
    final recommendations = <String>[];
    if (isFavorable) {
      recommendations.add('Good time for new beginnings');
      recommendations.add('Favorable for emotional matters');
    } else {
      recommendations.add('Be cautious with decisions');
      recommendations.add('Good time for introspection');
    }

    if (tithi >= 1 && tithi <= 5) {
      recommendations.add('Waxing Moon - Growth phase');
    } else if (tithi >= 15) {
      recommendations.add('Full Moon period - Peak energy');
    } else if (tithi >= 6 && tithi <= 10) {
      recommendations.add('Waning Moon - Consolidation phase');
    } else {
      recommendations.add('New Moon approaching - Rest and rejuvenate');
    }

    return MoonTransitAnalysis(
      transitSign: transitSign,
      houseFromNatalMoon: houseFromNatalMoon,
      tithi: tithi,
      nakshatra: nakshatras[nakshatraIndex % 27],
      isFavorable: isFavorable,
      recommendations: recommendations,
    );
  }

  /// Analyze Saturn transit (Sade Sati, Kantaka Shani, etc.)
  SaturnTransitAnalysis _analyzeSaturnTransit(
    CompleteChartData natalChart,
    VedicChart transitChart,
  ) {
    Planet? transitSaturn;
    double transitSaturnLongitude = 0;
    Planet? natalMoon;
    double natalMoonLongitude = 0;

    // Find Saturn and Moon
    for (final entry in transitChart.planets.entries) {
      if (entry.key.toString().toLowerCase().contains('saturn')) {
        transitSaturn = entry.key;
        transitSaturnLongitude = entry.value.longitude;
        break;
      }
    }

    for (final entry in natalChart.baseChart.planets.entries) {
      if (entry.key.toString().toLowerCase().contains('moon')) {
        natalMoon = entry.key;
        natalMoonLongitude = entry.value.longitude;
        break;
      }
    }

    if (transitSaturn == null || natalMoon == null) {
      return SaturnTransitAnalysis(
        transitSign: 0,
        houseFromMoon: 0,
        sadeSatiPhase: SadeSatiPhase.none,
        kantakaShani: false,
        isRetrograde: false,
        effects: ['Saturn or Moon position not available'],
        recommendations: [],
      );
    }

    final transitSign = (transitSaturnLongitude / 30).floor();
    final natalMoonSign = (natalMoonLongitude / 30).floor();
    final houseFromMoon = ((transitSign - natalMoonSign + 12) % 12) + 1;

    // Determine Sade Sati phase
    SadeSatiPhase sadeSatiPhase;
    if (houseFromMoon == 12) {
      sadeSatiPhase = SadeSatiPhase.rising;
    } else if (houseFromMoon == 1) {
      sadeSatiPhase = SadeSatiPhase.peak;
    } else if (houseFromMoon == 2) {
      sadeSatiPhase = SadeSatiPhase.setting;
    } else {
      sadeSatiPhase = SadeSatiPhase.none;
    }

    // Kantaka Shani (Saturn in 1st, 8th, or transit over Moon sign)
    final kantakaShani = houseFromMoon == 1 || houseFromMoon == 8;

    // Check retrograde status
    final saturnInfo = transitChart.planets[transitSaturn];
    final isRetrograde = saturnInfo?.isRetrograde ?? false;

    // Generate effects and recommendations
    final effects = <String>[];
    final recommendations = <String>[];

    if (sadeSatiPhase != SadeSatiPhase.none) {
      effects.add(
        'Sade Sati ${sadeSatiPhase.toString().split('.').last} phase',
      );
      effects.add('Period of karmic lessons and maturity');
      recommendations.add('Practice patience and discipline');
      recommendations.add('Focus on long-term goals');
      recommendations.add('Maintain good health routines');
    }

    if (kantakaShani) {
      effects.add('Kantaka Shani - Thorny Saturn period');
      recommendations.add('Avoid risky ventures');
      recommendations.add('Delay major decisions if possible');
    }

    if (isRetrograde) {
      effects.add('Saturn retrograde - Review and reassess');
      recommendations.add('Review past decisions');
      recommendations.add('Complete pending tasks');
    }

    return SaturnTransitAnalysis(
      transitSign: transitSign,
      houseFromMoon: houseFromMoon,
      sadeSatiPhase: sadeSatiPhase,
      kantakaShani: kantakaShani,
      isRetrograde: isRetrograde,
      effects: effects,
      recommendations: recommendations,
    );
  }

  /// Analyze Jupiter transit (Guru transit)
  JupiterTransitAnalysis _analyzeJupiterTransit(
    CompleteChartData natalChart,
    VedicChart transitChart,
  ) {
    Planet? transitJupiter;
    double transitJupiterLongitude = 0;
    Planet? natalMoon;
    double natalMoonLongitude = 0;

    // Find Jupiter and Moon
    for (final entry in transitChart.planets.entries) {
      if (entry.key.toString().toLowerCase().contains('jupiter')) {
        transitJupiter = entry.key;
        transitJupiterLongitude = entry.value.longitude;
        break;
      }
    }

    for (final entry in natalChart.baseChart.planets.entries) {
      if (entry.key.toString().toLowerCase().contains('moon')) {
        natalMoon = entry.key;
        natalMoonLongitude = entry.value.longitude;
        break;
      }
    }

    if (transitJupiter == null || natalMoon == null) {
      return JupiterTransitAnalysis(
        transitSign: 0,
        houseFromMoon: 0,
        isBenefic: false,
        effects: ['Jupiter or Moon position not available'],
        recommendations: [],
      );
    }

    final transitSign = (transitJupiterLongitude / 30).floor();
    final natalMoonSign = (natalMoonLongitude / 30).floor();
    final houseFromMoon = ((transitSign - natalMoonSign + 12) % 12) + 1;

    // Jupiter is benefic in most houses except 6th, 8th, 12th
    final isBenefic = ![6, 8, 12].contains(houseFromMoon);

    // Generate effects
    final effects = <String>[];
    final recommendations = <String>[];

    if (isBenefic) {
      effects.add(
        'Jupiter transit in favorable house $houseFromMoon from Moon',
      );
      effects.add('Period of growth, wisdom, and expansion');
      recommendations.add('Good time for education and learning');
      recommendations.add('Favorable for spiritual practices');
      recommendations.add('Opportunities for prosperity');
    } else {
      effects.add(
        'Jupiter transit in challenging house $houseFromMoon from Moon',
      );
      effects.add('Need for moderation and wisdom');
      recommendations.add('Avoid overindulgence');
      recommendations.add('Focus on spiritual growth');
    }

    return JupiterTransitAnalysis(
      transitSign: transitSign,
      houseFromMoon: houseFromMoon,
      isBenefic: isBenefic,
      effects: effects,
      recommendations: recommendations,
    );
  }

  /// Analyze Rahu-Ketu transit
  RahuKetuTransitAnalysis _analyzeRahuKetuTransit(
    CompleteChartData natalChart,
    VedicChart transitChart,
  ) {
    Planet? transitRahu;
    double transitRahuLongitude = 0;
    Planet? transitKetu;
    double transitKetuLongitude = 0;

    // Find Rahu and Ketu
    for (final entry in transitChart.planets.entries) {
      final planetName = entry.key.toString().toLowerCase();
      if (planetName.contains('rahu')) {
        transitRahu = entry.key;
        transitRahuLongitude = entry.value.longitude;
      } else if (planetName.contains('ketu')) {
        transitKetu = entry.key;
        transitKetuLongitude = entry.value.longitude;
      }
    }

    if (transitRahu == null || transitKetu == null) {
      return RahuKetuTransitAnalysis(
        rahuSign: 0,
        ketuSign: 0,
        isRahuTransitingNatalPlanet: false,
        isKetuTransitingNatalPlanet: false,
        affectedNatalPlanets: [],
        effects: ['Rahu/Ketu positions not available'],
        recommendations: [],
      );
    }

    final rahuSign = (transitRahuLongitude / 30).floor();
    final ketuSign = (transitKetuLongitude / 30).floor();

    // Check if transiting over any natal planets
    final affectedPlanets = <String>[];
    var isRahuTransitingNatalPlanet = false;
    var isKetuTransitingNatalPlanet = false;

    natalChart.baseChart.planets.forEach((natalPlanet, natalInfo) {
      final natalSign = (natalInfo.longitude / 30).floor();
      if (rahuSign == natalSign) {
        affectedPlanets.add(natalPlanet.toString().split('.').last);
        isRahuTransitingNatalPlanet = true;
      }
      if (ketuSign == natalSign) {
        affectedPlanets.add(natalPlanet.toString().split('.').last);
        isKetuTransitingNatalPlanet = true;
      }
    });

    // Generate effects
    final effects = <String>[];
    final recommendations = <String>[];

    if (isRahuTransitingNatalPlanet) {
      effects.add('Rahu transiting over natal ${affectedPlanets.join(", ")}');
      effects.add('Period of unexpected changes and desires');
      recommendations.add('Be cautious with new ventures');
      recommendations.add('Avoid shortcuts and quick gains');
    }

    if (isKetuTransitingNatalPlanet) {
      effects.add('Ketu transiting over natal ${affectedPlanets.join(", ")}');
      effects.add('Period of spiritual growth and detachment');
      recommendations.add('Focus on spiritual practices');
      recommendations.add('Let go of attachments');
    }

    return RahuKetuTransitAnalysis(
      rahuSign: rahuSign,
      ketuSign: ketuSign,
      isRahuTransitingNatalPlanet: isRahuTransitingNatalPlanet,
      isKetuTransitingNatalPlanet: isKetuTransitingNatalPlanet,
      affectedNatalPlanets: affectedPlanets,
      effects: effects,
      recommendations: recommendations,
    );
  }

  /// Helper: Normalize angle to 0-360
  double _normalizeAngle(double angle) {
    var normalized = angle % 360;
    if (normalized < 0) normalized += 360;
    return normalized;
  }

  /// Helper: Check if within orb
  bool _isWithinOrb(double angle, double target, double orb) {
    final diff = (angle - target).abs();
    return diff <= orb || (360 - diff) <= orb;
  }

  /// Helper: Calculate orb
  double _calculateOrb(double angle, double target) {
    final diff = (angle - target).abs();
    return diff > 180 ? 360 - diff : diff;
  }

  /// Helper: Check if aspect is applying (transit moving toward exact aspect)
  bool _isApplying(VedicPlanetInfo transit, VedicPlanetInfo natal) {
    // An aspect is applying if the transit planet is moving toward the natal planet's position
    // Calculate the angular distance
    final diff = (natal.longitude - transit.longitude + 360) % 360;

    // Determine direction based on retrograde status
    // Direct planets move forward (increasing longitude)
    // Retrograde planets move backward (decreasing longitude)
    final isMovingForward = !transit.isRetrograde;
    final natalIsAhead = diff < 180;

    // Applying conditions:
    // - Direct motion and natal is ahead (transit will catch up)
    // - Retrograde motion and natal is behind (transit will move back to it)
    return (isMovingForward && natalIsAhead) ||
        (!isMovingForward && !natalIsAhead);
  }

  /// Calculate aspect effect based on planets and aspect type
  TransitEffect _calculateAspectEffect(
    Planet transitPlanet,
    Planet natalPlanet,
    AspectType aspectType,
    CompleteChartData natalChart,
  ) {
    var strength = TransitStrength.neutral;
    final nature = <String>[];

    // Determine strength based on aspect type
    switch (aspectType) {
      case AspectType.conjunction:
        strength = TransitStrength.strong;
        nature.add('Intensified energy');
        break;
      case AspectType.opposition:
        strength = TransitStrength.strong;
        nature.add('Tension or confrontation');
        break;
      case AspectType.square:
        strength = TransitStrength.moderate;
        nature.add('Challenge or obstacle');
        break;
      case AspectType.trine:
        strength = TransitStrength.supportive;
        nature.add('Harmony and flow');
        break;
      case AspectType.sextile:
        strength = TransitStrength.supportive;
        nature.add('Opportunity');
        break;
    }

    // Modify based on planets
    final transitName = transitPlanet.toString().toLowerCase();
    // unused: final natalName = natalPlanet.toString().toLowerCase();

    if (transitName.contains('jupiter')) {
      nature.add('Expansion and growth');
    } else if (transitName.contains('saturn')) {
      nature.add('Restriction and discipline');
    } else if (transitName.contains('rahu')) {
      nature.add('Unexpected changes');
    }

    return TransitEffect(strength: strength, nature: nature);
  }

  /// Get daily prediction based on Moon transit
  String getDailyPrediction(MoonTransitAnalysis moonTransit) {
    if (moonTransit.isFavorable) {
      return 'Today is favorable for new beginnings, emotional connections, '
          'and creative pursuits. Moon in ${moonTransit.nakshatra} nakshatra, '
          '${moonTransit.tithi} tithi.';
    } else {
      return 'Today calls for caution and introspection. Focus on completing '
          'existing tasks rather than starting new ones. Moon in ${moonTransit.nakshatra} '
          'nakshatra, ${moonTransit.tithi} tithi.';
    }
  }

  /// Get monthly forecast based on approximate Moon transit positions
  /// For precise daily predictions, use calculateTransitChart() for each day
  List<DailyPrediction> getMonthlyForecast(
    CompleteChartData natalChart,
    int year,
    int month,
  ) {
    final predictions = <DailyPrediction>[];
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // Get natal Moon sign for favorability calculation
    int natalMoonSign = 0;
    for (final entry in natalChart.baseChart.planets.entries) {
      if (entry.key.toString().toLowerCase().contains('moon')) {
        natalMoonSign = (entry.value.longitude / 30).floor();
        break;
      }
    }

    // Favorable houses from Moon: 1, 3, 6, 10, 11
    const favorableHouses = [1, 3, 6, 10, 11];
    const signNames = [
      'Aries',
      'Taurus',
      'Gemini',
      'Cancer',
      'Leo',
      'Virgo',
      'Libra',
      'Scorpio',
      'Sagittarius',
      'Capricorn',
      'Aquarius',
      'Pisces',
    ];

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);

      // Calculate approximate Moon position
      // Moon moves ~13.2 degrees per day, completing zodiac in ~27.3 days
      final dayOfYear = date.difference(DateTime(year, 1, 1)).inDays;
      final approxMoonLongitude = (dayOfYear * 13.2) % 360;
      final moonSign = (approxMoonLongitude / 30).floor();

      // Calculate approximate tithi (Moon gains ~12 degrees on Sun daily)
      final approxTithi = (dayOfYear % 30) + 1;

      // Calculate house from natal Moon
      final houseFromMoon = ((moonSign - natalMoonSign + 12) % 12) + 1;
      final isFavorable = favorableHouses.contains(houseFromMoon);

      predictions.add(
        DailyPrediction(
          date: date,
          moonSign: moonSign,
          tithi: approxTithi.clamp(1, 30),
          isFavorable: isFavorable,
          summary:
              '${signNames[moonSign]} Moon (H$houseFromMoon) - ${isFavorable ? "Favorable" : "Caution advised"}',
        ),
      );
    }

    return predictions;
  }
}

/// Transit Chart data class
class TransitChart {
  final DateTime transitDate;
  final CompleteChartData natalChart;
  final VedicChart transitPositions;
  final List<TransitAspect> aspects;
  final GocharaPositions gochara;
  final MoonTransitAnalysis moonTransit;
  final SaturnTransitAnalysis saturnTransit;
  final JupiterTransitAnalysis jupiterTransit;
  final RahuKetuTransitAnalysis rahuKetuTransit;

  TransitChart({
    required this.transitDate,
    required this.natalChart,
    required this.transitPositions,
    required this.aspects,
    required this.gochara,
    required this.moonTransit,
    required this.saturnTransit,
    required this.jupiterTransit,
    required this.rahuKetuTransit,
  });

  /// Get summary of all transits
  String getSummary() {
    final buffer = StringBuffer();
    buffer.writeln('Transit Analysis for ${_formatDate(transitDate)}');
    buffer.writeln('=' * 40);
    buffer.writeln();
    buffer.writeln(
      'Moon: ${moonTransit.nakshatra}, House ${moonTransit.houseFromNatalMoon} from natal Moon',
    );
    buffer.writeln(
      'Saturn: House ${saturnTransit.houseFromMoon} from natal Moon',
    );
    if (saturnTransit.sadeSatiPhase != SadeSatiPhase.none) {
      buffer.writeln(
        'Sade Sati: ${saturnTransit.sadeSatiPhase.toString().split('.').last} phase',
      );
    }
    buffer.writeln(
      'Jupiter: House ${jupiterTransit.houseFromMoon} from natal Moon',
    );
    buffer.writeln();
    buffer.writeln('Major Aspects: ${aspects.length}');
    buffer.writeln(
      'Gochara Positions: ${gochara.positions.length} planets analyzed',
    );

    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Transit Aspect
class TransitAspect {
  final Planet transitPlanet;
  final Planet natalPlanet;
  final AspectType aspectType;
  final double orb;
  final bool isApplying;
  final TransitEffect effect;

  TransitAspect({
    required this.transitPlanet,
    required this.natalPlanet,
    required this.aspectType,
    required this.orb,
    required this.isApplying,
    required this.effect,
  });

  String get description {
    return '${transitPlanet.toString().split('.').last} ${aspectType.toString().split('.').last} '
        '${natalPlanet.toString().split('.').last} (${orb.toStringAsFixed(1)}° orb)';
  }
}

/// Aspect types
enum AspectType { conjunction, sextile, square, trine, opposition }

/// Transit effect
class TransitEffect {
  final TransitStrength strength;
  final List<String> nature;

  TransitEffect({required this.strength, required this.nature});
}

/// Transit strength
enum TransitStrength { strong, moderate, supportive, neutral, challenging }

/// Gochara Positions
class GocharaPositions {
  final Map<Planet, int> positions; // Planet -> House from Moon
  final int moonSign;

  GocharaPositions({required this.positions, required this.moonSign});

  /// Check if a planet is in favorable position
  bool isFavorable(Planet planet) {
    final house = positions[planet];
    if (house == null) return false;

    // Generally favorable houses from Moon: 1, 3, 6, 10, 11
    final favorableHouses = [1, 3, 6, 10, 11];
    return favorableHouses.contains(house);
  }
}

/// Moon Transit Analysis
class MoonTransitAnalysis {
  final int transitSign;
  final int houseFromNatalMoon;
  final int tithi;
  final String nakshatra;
  final bool isFavorable;
  final List<String> recommendations;

  MoonTransitAnalysis({
    required this.transitSign,
    required this.houseFromNatalMoon,
    required this.tithi,
    required this.nakshatra,
    required this.isFavorable,
    required this.recommendations,
  });
}

/// Saturn Transit Analysis
class SaturnTransitAnalysis {
  final int transitSign;
  final int houseFromMoon;
  final SadeSatiPhase sadeSatiPhase;
  final bool kantakaShani;
  final bool isRetrograde;
  final List<String> effects;
  final List<String> recommendations;

  SaturnTransitAnalysis({
    required this.transitSign,
    required this.houseFromMoon,
    required this.sadeSatiPhase,
    required this.kantakaShani,
    required this.isRetrograde,
    required this.effects,
    required this.recommendations,
  });

  bool get isSadeSati => sadeSatiPhase != SadeSatiPhase.none;
}

/// Sade Sati Phase
enum SadeSatiPhase {
  none,
  rising, // 12th from Moon
  peak, // over Moon
  setting, // 2nd from Moon
}

/// Jupiter Transit Analysis
class JupiterTransitAnalysis {
  final int transitSign;
  final int houseFromMoon;
  final bool isBenefic;
  final List<String> effects;
  final List<String> recommendations;

  JupiterTransitAnalysis({
    required this.transitSign,
    required this.houseFromMoon,
    required this.isBenefic,
    required this.effects,
    required this.recommendations,
  });
}

/// Rahu-Ketu Transit Analysis
class RahuKetuTransitAnalysis {
  final int rahuSign;
  final int ketuSign;
  final bool isRahuTransitingNatalPlanet;
  final bool isKetuTransitingNatalPlanet;
  final List<String> affectedNatalPlanets;
  final List<String> effects;
  final List<String> recommendations;

  RahuKetuTransitAnalysis({
    required this.rahuSign,
    required this.ketuSign,
    required this.isRahuTransitingNatalPlanet,
    required this.isKetuTransitingNatalPlanet,
    required this.affectedNatalPlanets,
    required this.effects,
    required this.recommendations,
  });
}

/// Daily Prediction
class DailyPrediction {
  final DateTime date;
  final int moonSign;
  final int tithi;
  final bool isFavorable;
  final String summary;

  DailyPrediction({
    required this.date,
    required this.moonSign,
    required this.tithi,
    required this.isFavorable,
    required this.summary,
  });
}
