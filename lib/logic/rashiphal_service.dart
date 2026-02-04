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

    // 5. Synthesize Highlights and Cautions
    final keyHighlights = <String>[];
    final cautions = <String>[];

    // Add transit recommendations
    if (moonTransit.isFavorable) {
      keyHighlights.add('Moon transit is favorable.');
      keyHighlights.addAll(moonTransit.recommendations);
    } else {
      cautions.add('Moon transit advises caution.');
      cautions.addAll(moonTransit.recommendations);
    }

    // Add KP Significance if needed
    // Simple check: Is sub-lord of 1st/10th house favorable?
    // For now, we'll keep it simple and focus on the generated text.

    // 6. Construct Final Object
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
      favorableScore: moonTransit.isFavorable ? 0.8 : 0.4,
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
