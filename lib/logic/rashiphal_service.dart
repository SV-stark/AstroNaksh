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
    // We use the location from the birth chart for the user's current location context
    // Ideally, the app should ask for *current* location, but usually birth location or
    // a stored "current location" setting is used.
    // For MVP, we'll use the chart's location assuming the user is there or it's a proxy.
    // TODO: Pass actual current user location if available in future updates.
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

    // 4. Generate Predictions using Rules Engine
    final signPrediction = RashiphalRules.getMoonSignPrediction(
      moonSign,
      houseFromNatal,
    );
    final nakshatraPrediction = RashiphalRules.getNakshatraPrediction(
      panchang.nakshatraNumber - 1,
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

    // Add transit recommendations
    if (moonTransit.isFavorable) {
      keyHighlights.add('Moon transit is favorable ($murti Murti)');
      keyHighlights.addAll(moonTransit.recommendations);
    } else {
      cautions.add('Moon transit advises caution ($murti Murti)');
      cautions.addAll(moonTransit.recommendations);
    }

    if (tarabalaPoints >= 30) {
      keyHighlights.add('Excellent Tarabala: Highly supportive star energy.');
    } else if (tarabalaPoints == 0) {
      cautions.add('Weak Tarabala: Success may require extra effort.');
    }

    if (isMoonObstructed) {
      cautions.add('Moon is obstructed (Vedha) - positive energy is blocked.');
    }

    // 7. Construct Final Object
    return DailyRashiphal(
      date: date,
      moonSign: _getSignName(moonSign),
      nakshatra: nakshatraStr,
      tithi: tithiStr,
      overallPrediction: '$signPrediction $nakshatraPrediction',
      keyHighlights: keyHighlights,
      auspiciousPeriods: muhurta,
      cautions: cautions,
      recommendation: tithiRec,
      favorableScore: finalScore,
    );
  }

  String _getSignName(int index) {
    const signs = [
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
    return signs[index % 12];
  }
}
