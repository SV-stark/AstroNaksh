import 'package:jyotish/core.dart';

import '../data/models.dart';
import '../logic/divisional_charts.dart';
import '../logic/kp_chart_service.dart';

/// Birth Time Rectification Utility
/// Allows simulating chart changes with time adjustments.
class BirthTimeRectifier {
  final KPChartService _chartService = KPChartService();

  /// Calculate rectifier data for a specific time adjustment
  Future<RectificationData> calculateForTime({
    required BirthData originalData,
    required Duration adjustment,
  }) async {
    final newTime = originalData.dateTime.add(adjustment);

    // Create new BirthData
    final newData = BirthData(
      dateTime: newTime,
      location: originalData.location,
      name: originalData.name,
      place: originalData.place,
    );

    // We use generateCompleteChart to ensure consistency.
    CompleteChartData? chartData;
    try {
      chartData = await _chartService.generateCompleteChart(newData);
    } catch (e) {
      // Fallback to null - UI will handle gracefully
      chartData = null;
    }

    if (chartData == null) {
      return RectificationData(
        adjustedTime: newTime,
        adjustment: adjustment,
        d1Ascendant: '-',
        d9Ascendant: '-',
        d10Ascendant: '-',
        d60Ascendant: '-',
        moonSign: '-',
        d9MoonSign: '-',
        chartData: null,
        d1Boundary: '-',
        d9Boundary: '-',
        d10Boundary: '-',
        d60Boundary: '-',
      );
    }

    final ascLong = chartData.baseChart.houses.cusps.isNotEmpty
        ? chartData.baseChart.houses.cusps[0]
        : 0.0;

    return RectificationData(
      adjustedTime: newTime,
      adjustment: adjustment,
      d1Ascendant: _getFormattedAscendant(chartData.baseChart),
      d9Ascendant: _getDivisionalAscendant(chartData, 'D-9'),
      d10Ascendant: _getDivisionalAscendant(chartData, 'D-10'),
      d60Ascendant: _getDivisionalAscendant(chartData, 'D-60'),
      moonSign: _getPlanetSign(chartData, 'Moon'),
      d9MoonSign: _getDivisionalPlanetSign(chartData, 'D-9', 'Moon'),
      chartData: chartData,
      d1Boundary: _getBoundaryInfo(ascLong, 30.0),
      d9Boundary: _getBoundaryInfo(ascLong, 30.0 / 9.0),
      d10Boundary: _getBoundaryInfo(ascLong, 3.0),
      d60Boundary: _getBoundaryInfo(ascLong, 0.5),
    );
  }

  String _getBoundaryInfo(double longitude, double divisionSize) {
    if (longitude == 0.0) return '-';
    final posInDiv = longitude % divisionSize;
    final distToNext = divisionSize - posInDiv;
    final distToPrev = posInDiv;

    // Format to degrees and minutes
    final nextDeg = distToNext.floor();
    final nextMin = ((distToNext - nextDeg) * 60).round();

    final prevDeg = distToPrev.floor();
    final prevMin = ((distToPrev - prevDeg) * 60).round();

    return 'Next: $nextDeg°$nextMin\' | Prev: $prevDeg°$prevMin\'';
  }

  String _getFormattedAscendant(VedicChart chart) {
    if (chart.houses.cusps.isEmpty) return 'Unknown';
    final asc = chart.houses.cusps[0];
    return _formatPosition(asc);
  }

  String _getDivisionalAscendant(CompleteChartData data, String div) {
    final chart = data.divisionalCharts[div];
    if (chart == null || chart.ascendantSign == null) return '-';
    return DivisionalCharts.getSignName(chart.ascendantSign!);
  }

  String _formatPosition(double longitude) {
    final sign = (longitude / 30).floor();
    final degree = longitude % 30;
    return '${degree.toStringAsFixed(2)}° ${DivisionalCharts.getSignName(sign)}';
  }

  String _getPlanetSign(CompleteChartData data, String planet) {
    for (final entry in data.baseChart.planets.entries) {
      if (entry.key.toString().toLowerCase().contains(planet.toLowerCase())) {
        return _formatPosition(entry.value.longitude);
      }
    }
    return '-';
  }

  String _getDivisionalPlanetSign(
    CompleteChartData data,
    String div,
    String planet,
  ) {
    final chart = data.divisionalCharts[div];
    if (chart == null) return '-';
    // positions is Map<String, double>
    // We need to find key that matches planet
    for (final key in chart.positions.keys) {
      if (key.toLowerCase().contains(planet.toLowerCase())) {
        return _formatPosition(chart.positions[key]!);
      }
    }
    return '-';
  }
}

class RectificationData {
  RectificationData({
    required this.adjustedTime,
    required this.adjustment,
    required this.d1Ascendant,
    required this.d9Ascendant,
    required this.d10Ascendant,
    required this.d60Ascendant,
    required this.moonSign,
    required this.d9MoonSign,
    required this.chartData,
    required this.d1Boundary,
    required this.d9Boundary,
    required this.d10Boundary,
    required this.d60Boundary,
  });
  final DateTime adjustedTime;
  final Duration adjustment;
  final String d1Ascendant;
  final String d9Ascendant;
  final String d10Ascendant;
  final String d60Ascendant;
  final String moonSign;
  final String d9MoonSign;
  final CompleteChartData? chartData;
  final String d1Boundary;
  final String d9Boundary;
  final String d10Boundary;
  final String d60Boundary;
}
