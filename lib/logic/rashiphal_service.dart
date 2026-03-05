import 'package:jyotish/jyotish.dart';
import '../data/models.dart';
import '../core/rashiphal_rules.dart';
import 'transit_analysis.dart';
import 'panchang_service.dart';

class RashiphalService {
  final TransitAnalysis _transitAnalysis = TransitAnalysis();
  final PanchangService _panchangService = PanchangService();

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
    for (int i = 0; i < 7; i++) {
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
    double normalizedScore = score / 100;
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
    String saturnNote =
        'Saturn: $saturnSignName (${_getOrdinal(saturnTransit.houseFromMoon)} house from natal Moon)';
    if (saturnTransit.isSadeSati) {
      saturnNote += ' — Sade Sati ${saturnTransit.sadeSatiPhase.name} phase';
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
    String dashaContext = '';
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
