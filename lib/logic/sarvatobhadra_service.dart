import 'package:jyotish/core.dart';
import 'package:jyotish/transit.dart';

import '../core/ephemeris_manager.dart';
import '../data/models.dart';

/// Service for analyzing transit Vedhas on the 81-square Sarvatobhadra Chakra.
class SarvatobhadraServiceWrapper {
  final Jyotish _jyotish = EphemerisManager.jyotish;

  /// Analyze Sarvatobhadra Chakra for a birth chart against a transit date
  Future<SarvatobhadraAnalysis> analyzeSarvatobhadra({
    required CompleteChartData chartData,
    required DateTime transitDate,
  }) async {
    await EphemerisManager.ensureEphemerisData();

    final transitChart = await _jyotish.calculateVedicChart(
      dateTime: transitDate,
      location: GeographicLocation(
        latitude: chartData.birthData.location.latitude,
        longitude: chartData.birthData.location.longitude,
      ),
    );

    return _jyotish.analyzeSarvatobhadra(
      natalChart: chartData.baseChart,
      transitPositions: {
        for (final p in Planet.traditionalPlanets)
          p: transitChart.getPlanet(p)?.longitude ?? 0.0,
      },
    );
  }
}
