import 'package:jyotish/jyotish.dart' as j;
import 'package:jyotish/src/services/gochara_vedha_service.dart';
import '../data/models.dart';
import '../core/ephemeris_manager.dart';

/// Transit Analysis (Gochara) System
/// Analyzes current planetary positions relative to natal chart
class TransitAnalysis {
  final j.Jyotish _jyotish = EphemerisManager.jyotish;
  final GocharaVedhaService _vedhaService = GocharaVedhaService();

  /// Calculate transit chart for a specific date
  Future<TransitChart> calculateTransitChart(
    CompleteChartData natalChart,
    DateTime transitDate,
  ) async {
    await EphemerisManager.ensureEphemerisData();

    final location = j.GeographicLocation(
      latitude: natalChart.birthData.location.latitude,
      longitude: natalChart.birthData.location.longitude,
      altitude: 0,
    );

    // Calculate transit positions (VedicChart)
    final transitPositions = await _jyotish.calculateVedicChart(
      dateTime: transitDate,
      location: location,
    );

    // Calculate aspects and transit info map using library
    final transitInfoMap = await _jyotish.getTransitPositions(
      natalChart: natalChart.baseChart,
      transitDateTime: transitDate,
      location: location,
    );

    // Map library aspects to local TransitAspect
    final aspects = _mapLibraryAspects(natalChart, transitInfoMap);

    // Gochara positions from natal Moon
    final gochara = _calculateGocharaPositions(natalChart, transitPositions);

    // Moon transit details using Panchanga
    final moonTransit = _analyzeMoonTransit(natalChart, transitPositions);

    // Calculate special transits (Sade Sati, Dhaiya) using library
    final specialTransits = await _jyotish.calculateSpecialTransits(
      natalChart: natalChart.baseChart,
      checkDate: transitDate,
      location: location,
    );

    final saturnTransit = _mapSaturnTransit(
      natalChart,
      transitPositions,
      specialTransits,
    );
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

  /// Analyze Gochara Vedha (transit obstructions) for all transits
  /// Returns analysis of which transits are being obstructed by other planets
  VedhaAnalysis analyzeVedha({
    required int moonNakshatra,
    required Map<j.Planet, int> gocharaPositions,
  }) {
    // Use library's batch calculation
    final libraryResults = _vedhaService.calculateMultipleVedha(
      transits: gocharaPositions,
      moonNakshatra: moonNakshatra,
    );

    final affectedTransits = <j.Planet>[];

    for (final result in libraryResults) {
      if (result.isObstructed) {
        affectedTransits.add(result.transitPlanet);
      }
    }

    return VedhaAnalysis(
      results: libraryResults,
      affectedTransits: affectedTransits,
      summary: _generateVedhaSummary(libraryResults, affectedTransits),
    );
  }

  /// Find favorable transit periods when specific planets are not obstructed
  Future<List<LocalFavorablePeriod>> findFavorableTransitPeriods({
    required CompleteChartData natalChart,
    required j.Planet targetPlanet,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final periods = <LocalFavorablePeriod>[];
    var currentDate = startDate;
    LocalFavorablePeriod? currentPeriod;

    while (currentDate.isBefore(endDate)) {
      final transitChart = await calculateTransitChart(natalChart, currentDate);
      final moonNakshatra =
          natalChart
              .baseChart
              .planets[j.Planet.moon]
              ?.position
              .nakshatraIndex ??
          0;

      final vedha = analyzeVedha(
        moonNakshatra: moonNakshatra + 1, // Library uses 1-indexed
        gocharaPositions: transitChart.gochara.positions,
      );

      final isUnobstructed = !vedha.affectedTransits.contains(targetPlanet);
      final isFavorableHouse = transitChart.gochara.isFavorable(targetPlanet);

      if (isUnobstructed && isFavorableHouse) {
        if (currentPeriod == null) {
          currentPeriod = LocalFavorablePeriod(
            planet: targetPlanet,
            startDate: currentDate,
            endDate: currentDate,
            reason: 'Unobstructed favorable transit',
          );
        } else {
          currentPeriod = LocalFavorablePeriod(
            planet: targetPlanet,
            startDate: currentPeriod.startDate,
            endDate: currentDate,
            reason: currentPeriod.reason,
          );
        }
      } else if (currentPeriod != null) {
        periods.add(currentPeriod);
        currentPeriod = null;
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    if (currentPeriod != null) {
      periods.add(currentPeriod);
    }

    return periods;
  }

  String _generateVedhaSummary(
    List<VedhaResult> results,
    List<j.Planet> affected,
  ) {
    if (affected.isEmpty) {
      return 'No transits are currently obstructed. All Gochara effects active.';
    }

    final buffer = StringBuffer();
    buffer.write('${affected.length} transit(s) obstructed: ');
    buffer.write(affected.map((p) => p.displayName).join(', '));
    return buffer.toString();
  }

  List<TransitAspect> _mapLibraryAspects(
    CompleteChartData natalChart,
    Map<j.Planet, j.TransitInfo> transitInfoMap,
  ) {
    final aspects = <TransitAspect>[];

    transitInfoMap.forEach((transitPlanet, info) {
      for (final aspectInfo in info.aspectsToNatal) {
        aspects.add(
          TransitAspect(
            transitPlanet: transitPlanet,
            natalPlanet: aspectInfo.aspectedPlanet,
            aspectType: _mapAspectType(aspectInfo.type),
            orb: aspectInfo.exactOrb.abs(),
            isApplying: aspectInfo.isApplying,
            effect: _calculateAspectEffect(
              transitPlanet,
              aspectInfo.aspectedPlanet,
              _mapAspectType(aspectInfo.type),
              natalChart,
            ),
          ),
        );
      }
    });

    // Sort by orb
    aspects.sort((a, b) => a.orb.compareTo(b.orb));
    return aspects;
  }

  AspectType _mapAspectType(j.AspectType type) {
    switch (type) {
      case j.AspectType.conjunction:
        return AspectType.conjunction;
      case j.AspectType.opposition:
        return AspectType.opposition;
      case j.AspectType.trine5th:
      case j.AspectType.trine9th:
      case j.AspectType.jupiterSpecial5th:
      case j.AspectType.jupiterSpecial9th:
        return AspectType.trine;
      case j.AspectType.square4th:
      case j.AspectType.square10th:
      case j.AspectType.marsSpecial4th:
      case j.AspectType.saturnSpecial10th:
        return AspectType.square;
      case j.AspectType.sextile3rd:
      case j.AspectType.sextile11th:
      case j.AspectType.saturnSpecial3rd:
        return AspectType.sextile;
      case j.AspectType.marsSpecial8th:
        return AspectType.square;
    }
  }

  /// Map library Saturn transit result to local model
  SaturnTransitAnalysis _mapSaturnTransit(
    CompleteChartData natalChart,
    j.VedicChart transitChart,
    j.SpecialTransits specialTransits,
  ) {
    final status = specialTransits.sadeSati;
    final dhaiya = specialTransits.dhaiya;
    final saturnInfo = transitChart.planets[j.Planet.saturn];

    return SaturnTransitAnalysis(
      transitSign: ((saturnInfo?.position.longitude ?? 0) / 30).floor(),
      houseFromMoon: status.transitedHouse ?? 0,
      sadeSatiPhase: _mapSadeSatiPhase(status.phase),
      kantakaShani: dhaiya.isActive,
      isRetrograde: saturnInfo?.isRetrograde ?? false,
      effects: [
        if (status.isActive) status.description,
        if (dhaiya.isActive) dhaiya.description,
        if (saturnInfo?.isRetrograde ?? false)
          'Saturn retrograde - Periodic review and delays',
      ],
      recommendations: [
        if (status.isActive) 'Practice patience and discipline',
        if (dhaiya.isActive) 'Avoid major financial risks',
        if (status.isActive || dhaiya.isActive)
          'Follow regular spiritual or health routines',
      ],
    );
  }

  SadeSatiPhase _mapSadeSatiPhase(j.SadeSatiPhase? phase) {
    if (phase == null) return SadeSatiPhase.none;
    switch (phase) {
      case j.SadeSatiPhase.rising:
        return SadeSatiPhase.rising;
      case j.SadeSatiPhase.peak:
        return SadeSatiPhase.peak;
      case j.SadeSatiPhase.setting:
        return SadeSatiPhase.setting;
    }
  }

  /// Calculate Gochara (house transit) positions from Moon
  GocharaPositions _calculateGocharaPositions(
    CompleteChartData natalChart,
    j.VedicChart transitChart,
  ) {
    final positions = <j.Planet, int>{};
    final moonInfo = natalChart.baseChart.planets[j.Planet.moon];

    if (moonInfo != null) {
      final moonSign = (moonInfo.position.longitude / 30).floor();

      transitChart.planets.forEach((planet, info) {
        final transitSign = (info.position.longitude / 30).floor();
        final house = ((transitSign - moonSign + 12) % 12) + 1;
        positions[planet] = house;
      });

      return GocharaPositions(positions: positions, moonSign: moonSign);
    }

    return GocharaPositions(positions: {}, moonSign: 0);
  }

  /// Analyze Moon transit (Tithi, Nakshatra, house placement)
  MoonTransitAnalysis _analyzeMoonTransit(
    CompleteChartData natalChart,
    j.VedicChart transitChart,
  ) {
    final moonInfo = transitChart.planets[j.Planet.moon];
    final natalMoonInfo = natalChart.baseChart.planets[j.Planet.moon];

    if (moonInfo == null || natalMoonInfo == null) {
      return MoonTransitAnalysis(
        transitSign: 0,
        houseFromNatalMoon: 0,
        tithi: 1,
        nakshatra: 'Unknown',
        isFavorable: false,
        recommendations: [],
      );
    }

    final transitSign = (moonInfo.position.longitude / 30).floor();
    final natalMoonSign = (natalMoonInfo.position.longitude / 30).floor();
    final houseFromMoon = ((transitSign - natalMoonSign + 12) % 12) + 1;

    // Favorable houses from Moon: 1, 3, 6, 7, 10, 11
    final isFavorable = [1, 3, 6, 7, 10, 11].contains(houseFromMoon);

    return MoonTransitAnalysis(
      transitSign: transitSign,
      houseFromNatalMoon: houseFromMoon,
      tithi: 1,
      nakshatra: moonInfo.position.nakshatra,
      isFavorable: isFavorable,
      recommendations: isFavorable
          ? ['Good time for emotional stability and social activities']
          : ['Keep emotions in check and avoid impulsive decisions'],
    );
  }

  /// Analyze Jupiter transit (Guru Gochara)
  JupiterTransitAnalysis _analyzeJupiterTransit(
    CompleteChartData natalChart,
    j.VedicChart transitChart,
  ) {
    final jupiterInfo = transitChart.planets[j.Planet.jupiter];
    final moonInfo = natalChart.baseChart.planets[j.Planet.moon];

    if (jupiterInfo == null || moonInfo == null) {
      return JupiterTransitAnalysis(
        transitSign: 0,
        houseFromMoon: 0,
        isBenefic: false,
        effects: ['Position not available'],
        recommendations: [],
      );
    }

    final transitSign = (jupiterInfo.position.longitude / 30).floor();
    final moonSign = (moonInfo.position.longitude / 30).floor();
    final houseFromMoon = ((transitSign - moonSign + 12) % 12) + 1;

    // Jupiter is favorable in 2, 5, 7, 9, 11 from Moon
    final isBenefic = [2, 5, 7, 9, 11].contains(houseFromMoon);

    return JupiterTransitAnalysis(
      transitSign: transitSign,
      houseFromMoon: houseFromMoon,
      isBenefic: isBenefic,
      effects: [
        isBenefic
            ? 'Benefic Jupiter transit (Guru Gochara)'
            : 'Neutral/Challenging Jupiter transit',
        'Impacts expansion and wisdom in house $houseFromMoon',
      ],
      recommendations: [
        if (isBenefic) 'Favorable for learning and spiritual growth',
        if (!isBenefic) 'Focus on discipline and avoid over-expansion',
      ],
    );
  }

  /// Analyze Rahu-Ketu transit
  RahuKetuTransitAnalysis _analyzeRahuKetuTransit(
    CompleteChartData natalChart,
    j.VedicChart transitChart,
  ) {
    final rahuInfo = transitChart.planets[j.Planet.meanNode];
    final ketuPos = transitChart.ketu;

    if (rahuInfo == null) {
      return RahuKetuTransitAnalysis(
        rahuSign: 0,
        ketuSign: 0,
        isRahuTransitingNatalPlanet: false,
        isKetuTransitingNatalPlanet: false,
        affectedNatalPlanets: [],
        effects: ['Nodes not available'],
        recommendations: [],
      );
    }

    final rahuSign = (rahuInfo.position.longitude / 30).floor();
    final ketuSign = (ketuPos.longitude / 30).floor();

    final affected = <String>[];
    var overNatalRahu = false;
    var overNatalKetu = false;

    natalChart.baseChart.planets.forEach((p, info) {
      final sign = (info.position.longitude / 30).floor();
      if (sign == rahuSign || sign == ketuSign) {
        affected.add(p.displayName);
        if (p == j.Planet.meanNode) overNatalRahu = true;
      }
    });

    // Check natal Ketu separately if it was available, but standard chart has Rahu
    // We'll assume Ketu is always opposite natal Rahu anyway.

    return RahuKetuTransitAnalysis(
      rahuSign: rahuSign,
      ketuSign: ketuSign,
      isRahuTransitingNatalPlanet: overNatalRahu,
      isKetuTransitingNatalPlanet: overNatalKetu,
      affectedNatalPlanets: affected,
      effects: [
        if (affected.isNotEmpty)
          'Nodes transiting over natal ${affected.join(", ")}',
        'Rahu in Sign ${rahuSign + 1}, Ketu in Sign ${ketuSign + 1}',
      ],
      recommendations: [
        'Pay attention to psychological shifts',
        if (overNatalRahu || overNatalKetu)
          'Expect significant karmic transformations',
      ],
    );
  }

  TransitEffect _calculateAspectEffect(
    j.Planet transitPlanet,
    j.Planet natalPlanet,
    AspectType aspectType,
    CompleteChartData natalChart,
  ) {
    final isBenefic = [
      j.Planet.jupiter,
      j.Planet.venus,
      j.Planet.mercury,
    ].contains(transitPlanet);

    return TransitEffect(
      strength: TransitStrength.moderate,
      nature: [
        isBenefic ? 'Supportive energy' : 'Challenging energy',
        'Focus on house matters',
      ],
    );
  }

  /// Get simplified daily prediction text based on Moon transit
  String getDailyPrediction(MoonTransitAnalysis moonTransit) {
    final buffer = StringBuffer();
    buffer.write('Today, the Moon is in ${moonTransit.nakshatra} nakshatra, ');
    buffer.write(
      'occupying the ${moonTransit.houseFromNatalMoon} house from your natal Moon. ',
    );

    if (moonTransit.isFavorable) {
      buffer.write(
        'This is a favorable placement, indicating a day of emotional clarity and progress. ',
      );
    } else {
      buffer.write(
        'This placement suggests a need for introspection and caution in emotional matters. ',
      );
    }

    buffer.write(moonTransit.recommendations.join(' '));
    return buffer.toString();
  }
}

/// Transit Chart data class
class TransitChart {
  final DateTime transitDate;
  final CompleteChartData natalChart;
  final j.VedicChart transitPositions;
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

  String getSummary() {
    final buffer = StringBuffer();
    buffer.writeln(
      'Transit Analysis for ${transitDate.day}/${transitDate.month}/${transitDate.year}',
    );
    buffer.writeln('=' * 40);
    buffer.writeln();
    buffer.writeln(
      'Moon: ${moonTransit.nakshatra}, House ${moonTransit.houseFromNatalMoon} from natal Moon',
    );
    buffer.writeln(
      'Saturn: House ${saturnTransit.houseFromMoon} from natal Moon',
    );
    if (saturnTransit.isSadeSati) {
      buffer.writeln('Sade Sati: ${saturnTransit.sadeSatiPhase.name} phase');
    }
    buffer.writeln(
      'Jupiter: House ${jupiterTransit.houseFromMoon} from natal Moon',
    );
    buffer.writeln();
    buffer.writeln('Major Aspects: ${aspects.length}');

    return buffer.toString();
  }
}

/// Transit Aspect model
class TransitAspect {
  final j.Planet transitPlanet;
  final j.Planet natalPlanet;
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
    return '${transitPlanet.displayName} ${aspectType.name} ${natalPlanet.displayName} (${orb.toStringAsFixed(1)}° orb)';
  }
}

enum AspectType { conjunction, sextile, square, trine, opposition }

class TransitEffect {
  final TransitStrength strength;
  final List<String> nature;
  TransitEffect({required this.strength, required this.nature});
}

enum TransitStrength { strong, moderate, supportive, neutral, challenging }

class GocharaPositions {
  final Map<j.Planet, int> positions;
  final int moonSign;
  GocharaPositions({required this.positions, required this.moonSign});

  /// Check if a planet transit is favorable from natal Moon
  bool isFavorable(j.Planet planet) {
    final house = positions[planet] ?? 0;
    if (house == 0) return false;

    switch (planet) {
      case j.Planet.sun:
        return [3, 6, 10, 11].contains(house);
      case j.Planet.moon:
        return [1, 3, 6, 7, 10, 11].contains(house);
      case j.Planet.mars:
        return [3, 6, 11].contains(house);
      case j.Planet.mercury:
        return [2, 4, 6, 8, 10, 11].contains(house);
      case j.Planet.jupiter:
        return [2, 5, 7, 9, 11].contains(house);
      case j.Planet.venus:
        return [1, 2, 3, 4, 5, 8, 9, 11, 12].contains(house);
      case j.Planet.saturn:
        return [3, 6, 11].contains(house);
      default:
        return house == 11; // 11th house is generally favorable for all
    }
  }
}

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

enum SadeSatiPhase { none, rising, peak, setting }

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

/// Analysis result for Gochara Vedha calculations
class VedhaAnalysis {
  final List<VedhaResult> results;
  final List<j.Planet> affectedTransits;
  final String summary;

  VedhaAnalysis({
    required this.results,
    required this.affectedTransits,
    required this.summary,
  });

  /// Get vedha result for a specific planet
  VedhaResult? getResult(j.Planet planet) {
    for (final result in results) {
      if (result.transitPlanet == planet) {
        return result;
      }
    }
    return null;
  }

  /// Count of unobstructed favorable transits
  int get unobstructedCount =>
      results.where((r) => r.isFavorablePosition && !r.isObstructed).length;
}

/// Local favorable period model for date range tracking
class LocalFavorablePeriod {
  final j.Planet planet;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;

  LocalFavorablePeriod({
    required this.planet,
    required this.startDate,
    required this.endDate,
    required this.reason,
  });

  /// Duration of the favorable period
  Duration get duration => endDate.difference(startDate);

  /// Number of days in the favorable period
  int get days => duration.inDays + 1;

  @override
  String toString() {
    return '${planet.displayName}: ${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month} ($days days)';
  }
}
