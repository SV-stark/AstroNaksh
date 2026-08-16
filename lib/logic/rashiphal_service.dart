import 'package:jyotish/jyotish.dart';

import '../core/ephemeris_manager.dart';
import '../core/rashiphal_rules.dart';
import '../data/models.dart';
import 'panchang_service.dart';
import 'transit_analysis.dart';

// ── Rashi metadata ──────────────────────────────────────────────────────────

/// Metadata for a single Rashi (sign) used in standalone Rashifal
class RashiInfo {
  const RashiInfo({
    required this.index,
    required this.name,
    required this.sanskrit,
    required this.symbol,
    required this.lord,
    required this.element,
    required this.luckyColor,
    required this.luckyNumber,
    required this.luckyDirection,
  });

  final int index;
  final String name;
  final String sanskrit;
  final String symbol;
  final String lord;
  final String element;
  final String luckyColor;
  final int luckyNumber;
  final String luckyDirection;

  static const List<RashiInfo> all = [
    RashiInfo(index: 0,  name: 'Aries',       sanskrit: 'मेष',    symbol: '♈', lord: 'Mars',    element: 'Fire',  luckyColor: 'Red',       luckyNumber: 9,  luckyDirection: 'East'),
    RashiInfo(index: 1,  name: 'Taurus',      sanskrit: 'वृषभ',   symbol: '♉', lord: 'Venus',   element: 'Earth', luckyColor: 'White',     luckyNumber: 6,  luckyDirection: 'South'),
    RashiInfo(index: 2,  name: 'Gemini',      sanskrit: 'मिथुन',  symbol: '♊', lord: 'Mercury', element: 'Air',   luckyColor: 'Green',     luckyNumber: 5,  luckyDirection: 'West'),
    RashiInfo(index: 3,  name: 'Cancer',      sanskrit: 'कर्क',   symbol: '♋', lord: 'Moon',    element: 'Water', luckyColor: 'Silver',    luckyNumber: 2,  luckyDirection: 'North'),
    RashiInfo(index: 4,  name: 'Leo',         sanskrit: 'सिंह',   symbol: '♌', lord: 'Sun',     element: 'Fire',  luckyColor: 'Golden',    luckyNumber: 1,  luckyDirection: 'East'),
    RashiInfo(index: 5,  name: 'Virgo',       sanskrit: 'कन्या',  symbol: '♍', lord: 'Mercury', element: 'Earth', luckyColor: 'Navy Blue', luckyNumber: 5,  luckyDirection: 'South'),
    RashiInfo(index: 6,  name: 'Libra',       sanskrit: 'तुला',   symbol: '♎', lord: 'Venus',   element: 'Air',   luckyColor: 'White',     luckyNumber: 6,  luckyDirection: 'West'),
    RashiInfo(index: 7,  name: 'Scorpio',     sanskrit: 'वृश्चिक', symbol: '♏', lord: 'Mars',   element: 'Water', luckyColor: 'Dark Red',  luckyNumber: 9,  luckyDirection: 'North'),
    RashiInfo(index: 8,  name: 'Sagittarius', sanskrit: 'धनु',    symbol: '♐', lord: 'Jupiter', element: 'Fire',  luckyColor: 'Yellow',    luckyNumber: 3,  luckyDirection: 'East'),
    RashiInfo(index: 9,  name: 'Capricorn',   sanskrit: 'मकर',    symbol: '♑', lord: 'Saturn',  element: 'Earth', luckyColor: 'Blue',      luckyNumber: 8,  luckyDirection: 'South'),
    RashiInfo(index: 10, name: 'Aquarius',    sanskrit: 'कुम्भ',  symbol: '♒', lord: 'Saturn',  element: 'Air',   luckyColor: 'Violet',    luckyNumber: 8,  luckyDirection: 'West'),
    RashiInfo(index: 11, name: 'Pisces',      sanskrit: 'मीन',    symbol: '♓', lord: 'Jupiter', element: 'Water', luckyColor: 'Sea Green', luckyNumber: 3,  luckyDirection: 'North'),
  ];
}

class RashiphalService {
  final TransitAnalysis _transitAnalysis = TransitAnalysis();
  final PanchangService _panchangService = PanchangService();
  final Jyotish _jyotish = EphemerisManager.jyotish;

  // ── Standalone (sign-only) public API ────────────────────────────────────

  /// Default location (New Delhi) used when user hasn't set one
  static const _defaultLocation = Location(latitude: 28.6139, longitude: 77.2090);

  /// Generate a Today / Tomorrow / 7-day dashboard for a selected Rashi (sign),
  /// without requiring any birth chart or CompleteChartData.
  Future<RashiphalDashboard> getDashboardForSign(
    int signIndex, {
    Location? location,
  }) async {
    final loc = location ?? _defaultLocation;
    final now = DateTime.now();
    final today = await generateDailyPredictionForSign(signIndex, loc, now);
    final tomorrow = await generateDailyPredictionForSign(
      signIndex, loc, now.add(const Duration(days: 1)),
    );
    final weekly = <DailyRashiphal>[];
    for (var i = 0; i < 7; i++) {
      weekly.add(await generateDailyPredictionForSign(
        signIndex, loc, now.add(Duration(days: i)),
      ));
    }
    return RashiphalDashboard(today: today, tomorrow: tomorrow, weeklyOverview: weekly);
  }

  /// Generate a single-day prediction from just a Moon-sign index (0-11)
  /// and a geographic location for Panchang.
  Future<DailyRashiphal> generateDailyPredictionForSign(
    int signIndex,
    Location location,
    DateTime date,
  ) async {
    await EphemerisManager.ensureEphemerisData();

    final geoLoc = GeographicLocation(
      latitude: location.latitude,
      longitude: location.longitude,
      altitude: 0,
    );

    // 1. Current planetary positions via ephemeris
    final transitVedicChart = await _jyotish.calculateVedicChart(
      dateTime: date,
      location: geoLoc,
    );

    // 2. Panchang
    final panchang = await _panchangService.getPanchang(date, location);

    // 3. Core sign metrics
    final transitMoonLong =
        transitVedicChart.planets[Planet.moon]?.position.longitude ?? 0.0;
    final moonSign = (transitMoonLong / 30).floor(); // 0-11 transit Moon sign
    final houseFromNatal = ((moonSign - signIndex + 12) % 12) + 1; // 1-12

    // Chandrashtama is the 8th house; warn explicitly
    final isChandrashtama = houseFromNatal == 8;

    final nakshatraStr = panchang.nakshatra;
    final tithiStr = panchang.tithi;
    final tithiNum = panchang.tithiNumber;
    final moonSignName = _getSignName(moonSign);

    // 4. Rules engine
    final signPrediction = RashiphalRules.getMoonSignPrediction(
      moonSign, houseFromNatal, signName: moonSignName,
    );
    final nakshatraPrediction = RashiphalRules.getNakshatraPrediction(
      panchang.nakshatraNumber - 1, nakshatraName: nakshatraStr,
    );
    final tithiRec = RashiphalRules.getTithiRecommendation(tithiNum);
    final muhurta = RashiphalRules.getMuhurtaTimings(date);

    // 5. Scoring
    double score = 0;

    // A. Moon transit house — same house-quality table as full chart
    final favorableHouses = [3, 6, 7, 10, 11];
    final mediumHouses   = [1, 2, 4, 5, 9];
    bool moonFavorable;
    List<String> moonRecs;
    if (favorableHouses.contains(houseFromNatal)) {
      moonFavorable = true;
      moonRecs      = ['Good time for emotional stability and social activities.'];
      score        += 35.0;
    } else if (mediumHouses.contains(houseFromNatal)) {
      moonFavorable = true;
      moonRecs      = ['Mixed influences. Proceed with balance and awareness.'];
      score        += 20.0;
    } else {
      moonFavorable = false;
      moonRecs      = ['Keep emotions in check and avoid impulsive decisions.'];
      score        += 5.0;
    }

    // B. Tarabala — approx birth nakshatra as midpoint of natal sign
    final approxBirthNakshatra = (signIndex * 27 ~/ 12) + 1; // 1-27
    final tarabalaCategory = RashiphalRules.getTarabalaCategory(
      approxBirthNakshatra, panchang.nakshatraNumber,
    );
    final tarabalaPoints = RashiphalRules.getTarabalaScore(tarabalaCategory);
    score += (tarabalaPoints / 30.0) * 35.0;

    // C. Murti
    final murti      = RashiphalRules.getMurti(signIndex, moonSign);
    final murtiPoints = RashiphalRules.getMurtiScore(murti);
    score += (murtiPoints / 20.0) * 30.0;

    // D. Vedha
    final gocharaPositions = <Planet, int>{};
    transitVedicChart.planets.forEach((planet, info) {
      final tSign = info.position.zodiacSignIndex;
      gocharaPositions[planet] = ((tSign - signIndex + 12) % 12) + 1;
    });
    final vedha = _transitAnalysis.analyzeVedha(
      moonNakshatra: approxBirthNakshatra,
      gocharaPositions: gocharaPositions,
    );
    final isMoonObstructed = vedha.affectedTransits.contains(Planet.moon);
    if (isMoonObstructed) score -= 20.0;
    if (RashiphalRules.isMaleficYoga(panchang.yogaNumber)) score -= 10.0;

    final finalScore = (score / 100).clamp(0.35, 0.95);

    // 6. Highlights & cautions
    final keyHighlights = <String>[];
    final cautions      = <String>[];

    if (isChandrashtama) {
      cautions.add(
        'Chandrashtama active: Moon transiting the 8th from your natal Rashi (${ RashiInfo.all[signIndex].name}). '
        'Avoid major decisions, surgeries, or travel for 2–3 days.',
      );
    }

    if (moonFavorable) {
      keyHighlights.add(
        'Moon in $moonSignName ($murti Murti) occupies the ${_getOrdinal(houseFromNatal)} from ${RashiInfo.all[signIndex].name} Rashi — favorable.',
      );
      keyHighlights.addAll(moonRecs);
    } else {
      cautions.add(
        'Moon in $moonSignName ($murti Murti) in the ${_getOrdinal(houseFromNatal)} from ${RashiInfo.all[signIndex].name} — advises caution.',
      );
      cautions.addAll(moonRecs);
    }

    final tarabalaCategoryName = _getTarabalaCategoryName(tarabalaCategory);
    if (tarabalaPoints >= 30) {
      keyHighlights.add(
        'Tarabala: $tarabalaCategoryName — strong star energy from $nakshatraStr.',
      );
    } else if (tarabalaPoints == 0) {
      cautions.add(
        'Tarabala: $tarabalaCategoryName — star energy from $nakshatraStr may need extra effort.',
      );
    }

    if (isMoonObstructed) {
      cautions.add('Moon transit through $moonSignName is Vedha-obstructed — energy partially blocked.');
    }

    // 7. Transit context
    final transitContext = <String>[];
    transitContext.add('Moon: $moonSignName (${_getOrdinal(houseFromNatal)} from ${RashiInfo.all[signIndex].name}) — $nakshatraStr');

    final jupiterInfo = transitVedicChart.planets[Planet.jupiter];
    if (jupiterInfo != null) {
      final jSign = _getSignName(jupiterInfo.position.zodiacSignIndex);
      final jHouse = ((jupiterInfo.position.zodiacSignIndex - signIndex + 12) % 12) + 1;
      final jBenefic = [2, 5, 7, 9, 11].contains(jHouse);
      transitContext.add('Jupiter: $jSign (${_getOrdinal(jHouse)} house)${jBenefic ? " — Favorable" : ""}');
    }

    final saturnInfo = transitVedicChart.planets[Planet.saturn];
    if (saturnInfo != null) {
      final sSign = _getSignName(saturnInfo.position.zodiacSignIndex);
      final sHouse = ((saturnInfo.position.zodiacSignIndex - signIndex + 12) % 12) + 1;
      var saturnNote = 'Saturn: $sSign (${_getOrdinal(sHouse)} house)';
      if ([12, 1, 2].contains(sHouse)) saturnNote += ' — Sade Sati watch';
      if ([4, 8].contains(sHouse)) saturnNote += ' — Dhaiya watch';
      if (saturnInfo.isRetrograde) saturnNote += ' [Retrograde]';
      transitContext.add(saturnNote);
    }

    final rahuInfo = transitVedicChart.planets[Planet.meanNode];
    if (rahuInfo != null) {
      final rahuSign = _getSignName(rahuInfo.position.zodiacSignIndex);
      final ketuLong = (rahuInfo.position.longitude + 180) % 360;
      final ketuSign = _getSignName((ketuLong / 30).floor());
      transitContext.add('Rahu: $rahuSign | Ketu: $ketuSign');
    }

    // rashiMeta available via RashiInfo.all[signIndex] if needed by callers

    return DailyRashiphal(
      date: date,
      moonSign: moonSignName,
      nakshatra: nakshatraStr,
      tithi: tithiStr,
      overallPrediction: '$signPrediction\n\n$nakshatraPrediction',
      keyHighlights: keyHighlights,
      auspiciousPeriods: muhurta,
      cautions: cautions,
      recommendation: tithiRec,
      favorableScore: finalScore,
      transitContext: transitContext,
      dashaContext: '',            // No natal chart → no Dasha context
      // Lucky elements embedded in transitContext for UI display
    );
  }

  // ── Chart-based public API (unchanged) ───────────────────────────────────

  /// Generate full dashboard data (Today, Tomorrow, Weekly)

  Future<RashiphalDashboard> getDashboardData(
    CompleteChartData chartData,
  ) async {
    final now = DateTime.now();
    final today = await generateDailyPrediction(chartData, now);
    final tomorrow = await generateDailyPrediction(
      chartData,
      now.add(const Duration(days: 1)),
    );

    // Generate weekly overview (next 7 days starting from today)
    final weekly = <DailyRashiphal>[];
    for (var i = 0; i < 7; i++) {
      // Optimization: For weekly overview we might want a lighter version,
      // but for now we'll reuse the main generator as it's not too heavy yet.
      final prediction = await generateDailyPrediction(
        chartData,
        now.add(Duration(days: i)),
      );
      weekly.add(prediction);
    }

    return RashiphalDashboard(
      today: today,
      tomorrow: tomorrow,
      weeklyOverview: weekly,
    );
  }

  /// Generate prediction for a specific single day
  Future<DailyRashiphal> generateDailyPrediction(
    CompleteChartData chartData,
    DateTime date,
  ) async {
    // 1. Get Transit Data
    final transitChart = await _transitAnalysis.calculateTransitChart(
      chartData,
      date,
    );

    // 2. Get Panchang Data
    final panchang = await _panchangService.getPanchang(
      date,
      chartData.birthData.location,
    );

    // 3. Extract Key Parameters
    final moonTransit = transitChart.moonTransit;
    final moonSign = moonTransit.transitSign; // 0-11
    final houseFromNatal = moonTransit.houseFromNatalMoon; // 1-12
    final nakshatraStr = panchang.nakshatra;
    final tithiStr = panchang.tithi; // e.g., "Shukla Pratipada"
    final tithiNum = panchang.tithiNumber;
    final moonSignName = _getSignName(moonSign);

    // 4. Generate Predictions using Rules Engine (now with sign name context)
    final signPrediction = RashiphalRules.getMoonSignPrediction(
      moonSign,
      houseFromNatal,
      signName: moonSignName,
    );
    final nakshatraPrediction = RashiphalRules.getNakshatraPrediction(
      panchang.nakshatraNumber - 1,
      nakshatraName: nakshatraStr,
    );
    final tithiRec = RashiphalRules.getTithiRecommendation(tithiNum);
    final muhurta = RashiphalRules.getMuhurtaTimings(date);

    // 5. Hybrid Scoring Calculation
    // Base Scores (Max 100)
    double score = 0;

    // A. Moon Transit (House) - Weight: 35
    final moonHouseScore = switch (moonTransit.quality) {
      TransitQuality.favorable => 35.0,
      TransitQuality.medium => 20.0,
      TransitQuality.challenging => 5.0,
    };
    score += moonHouseScore;

    // B. Tarabala (Star Strength) - Weight: 35
    final birthNakshatraIndex =
        chartData.baseChart.planets[Planet.moon]?.position.nakshatraIndex ?? 0;
    final tarabalaCategory = RashiphalRules.getTarabalaCategory(
      birthNakshatraIndex + 1,
      panchang.nakshatraNumber,
    );
    final tarabalaPoints = RashiphalRules.getTarabalaScore(tarabalaCategory);
    // getTarabalaScore returns 30, 10, or 0. Map to 35 max.
    final tarabalaScore = (tarabalaPoints / 30.0) * 35.0;
    score += tarabalaScore;

    // C. Murti (Moon Form) - Weight: 30
    final natalMoonSign =
        ((chartData.baseChart.planets[Planet.moon]?.position.longitude ?? 0) /
                30)
            .floor();
    final murti = RashiphalRules.getMurti(natalMoonSign, moonSign);
    final murtiPoints = RashiphalRules.getMurtiScore(murti);
    // getMurtiScore returns 20, 10, or 0. Map to 30 max.
    final murtiScore = (murtiPoints / 20.0) * 30.0;
    score += murtiScore;

    // D. Penalties
    // 1. Vedha (Obstruction)
    final vedha = _transitAnalysis.analyzeVedha(
      moonNakshatra: panchang.nakshatraNumber,
      gocharaPositions: transitChart.gochara.positions,
    );
    final isMoonObstructed = vedha.affectedTransits.contains(Planet.moon);
    if (isMoonObstructed) {
      score -= 20.0; // Significant penalty
    }

    // 2. Malefic Yoga
    if (RashiphalRules.isMaleficYoga(panchang.yogaNumber)) {
      score -= 10.0;
    }

    // Normalize and Clamp (35% to 95%)
    // Raw score range is approx -30 to 100
    final normalizedScore = score / 100;
    final finalScore = normalizedScore.clamp(0.35, 0.95);

    // 6. Synthesize Highlights and Cautions
    final keyHighlights = <String>[];
    final cautions = <String>[];

    // Tarabala category name for descriptive output
    final tarabalaCategoryName = _getTarabalaCategoryName(tarabalaCategory);

    // Add transit recommendations with planetary context
    if (moonTransit.isFavorable) {
      keyHighlights.add(
        'Moon transit through $moonSignName ($murti Murti) in ${_getOrdinal(houseFromNatal)} house from natal Moon is favorable.',
      );
      keyHighlights.addAll(moonTransit.recommendations);
    } else {
      cautions.add(
        'Moon transit through $moonSignName ($murti Murti) in ${_getOrdinal(houseFromNatal)} house from natal Moon advises caution.',
      );
      cautions.addAll(moonTransit.recommendations);
    }

    if (tarabalaPoints >= 30) {
      keyHighlights.add(
        'Tarabala is $tarabalaCategoryName (category $tarabalaCategory of 9) — highly supportive star energy from $nakshatraStr Nakshatra.',
      );
    } else if (tarabalaPoints == 0) {
      cautions.add(
        'Tarabala is $tarabalaCategoryName (category $tarabalaCategory of 9) — star energy from $nakshatraStr Nakshatra may require extra effort.',
      );
    }

    if (isMoonObstructed) {
      cautions.add(
        'Moon\'s positive transit through $moonSignName is obstructed by Vedha — beneficial energy is partially blocked.',
      );
    }

    // 7. Build Transit Context — explicit planetary positions for reasoning
    final transitContext = <String>[];

    // Moon position
    transitContext.add(
      'Moon: $moonSignName (${_getOrdinal(houseFromNatal)} house from natal Moon) — $nakshatraStr Nakshatra',
    );

    // Jupiter position
    final jupiterTransit = transitChart.jupiterTransit;
    final jupiterSignName = _getSignName(jupiterTransit.transitSign);
    transitContext.add(
      'Jupiter: $jupiterSignName (${_getOrdinal(jupiterTransit.houseFromMoon)} house from natal Moon)${jupiterTransit.isBenefic ? " — Favorable" : ""}',
    );

    // Saturn position
    final saturnTransit = transitChart.saturnTransit;
    final saturnSignName = _getSignName(saturnTransit.transitSign);
    var saturnNote =
        'Saturn: $saturnSignName (${_getOrdinal(saturnTransit.houseFromMoon)} house from natal Moon)';
    if (saturnTransit.isSadeSati) {
      saturnNote += ' — Sade Sati ${saturnTransit.sadeSatiPhase.name} phase';
    }
    if (saturnTransit.isDhaiya) {
      saturnNote += ' — Dhaiya (${saturnTransit.dhaiyaType.name}) active';
    }
    if (saturnTransit.isRetrograde) {
      saturnNote += ' [Retrograde]';
    }
    transitContext.add(saturnNote);

    // Rahu-Ketu position
    final rahuKetuTransit = transitChart.rahuKetuTransit;
    final rahuSignName = _getSignName(rahuKetuTransit.rahuSign);
    final ketuSignName = _getSignName(rahuKetuTransit.ketuSign);
    transitContext.add('Rahu: $rahuSignName | Ketu: $ketuSignName');

    // 8. Build Dasha Context — current running Dasha period
    var dashaContext = '';
    final currentDashas = chartData.getCurrentDashas(date);
    if (currentDashas.isNotEmpty) {
      final md = currentDashas['mahadasha'] ?? '';
      final ad = currentDashas['antardasha'] ?? '';
      final pd = currentDashas['pratyantardasha'] ?? '';
      if (md.isNotEmpty) {
        dashaContext = '$md Mahadasha';
        if (ad.isNotEmpty) dashaContext += ' → $ad Antardasha';
        if (pd.isNotEmpty) dashaContext += ' → $pd Pratyantardasha';
      }
    }

    // 9. Construct Final Object
    return DailyRashiphal(
      date: date,
      moonSign: moonSignName,
      nakshatra: nakshatraStr,
      tithi: tithiStr,
      overallPrediction: '$signPrediction\n\n$nakshatraPrediction',
      keyHighlights: keyHighlights,
      auspiciousPeriods: muhurta,
      cautions: cautions,
      recommendation: tithiRec,
      favorableScore: finalScore,
      transitContext: transitContext,
      dashaContext: dashaContext,
    );
  }

  /// Get Tarabala category name
  String _getTarabalaCategoryName(int category) {
    const names = {
      1: 'Janma (Birth)',
      2: 'Sampat (Wealth)',
      3: 'Vipat (Danger)',
      4: 'Kshema (Well-being)',
      5: 'Pratyak (Obstacle)',
      6: 'Sadhana (Achievement)',
      7: 'Naidhana (Death-like)',
      8: 'Mitra (Friend)',
      9: 'Param Mitra (Best Friend)',
    };
    return names[category] ?? 'Unknown';
  }

  /// Get ordinal suffix
  String _getOrdinal(int number) {
    if (number >= 11 && number <= 13) return '${number}th';
    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }

  String _getSignName(int index) => AstrologyConstants.getSignName(index);
}
