import 'package:jyotish/jyotish.dart';
import '../data/models.dart';
import '../logic/kp_chart_service.dart';
import '../logic/divisional_charts.dart';

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

    // Generate simplified chart data (D-1, D-9, D-60 basics)
    // We don't need full KP/Dasha for rectification usually, just sensitive points

    // We can use generateCompleteChart but it might be heavy.
    // Optimization: Just calculate Varga Lagnas?
    // For now, use robust service to ensure consistency.
    final chartData = await _chartService.generateCompleteChart(newData);

    return RectificationData(
      adjustedTime: newTime,
      adjustment: adjustment,
      d1Ascendant: _getFormattedAscendant(chartData.baseChart),
      d9Ascendant: _getDivisionalAscendant(chartData, 'D-9'),
      d60Ascendant: _getDivisionalAscendant(chartData, 'D-60'),
      moonSign: _getPlanetSign(chartData, 'Moon'),
      d9MoonSign: _getDivisionalPlanetSign(chartData, 'D-9', 'Moon'),
    );
  }

  String _getFormattedAscendant(VedicChart chart) {
    if (chart.houses.cusps.isEmpty) return "Unknown";
    double asc = chart.houses.cusps[0];
    return _formatPosition(asc);
  }

  String _getDivisionalAscendant(CompleteChartData data, String div) {
    var chart = data.divisionalCharts[div];
    if (chart == null || chart.ascendantSign == null) return "-";
    // We need exact degree if possible? DivisionalCharts model stores int sign usually?
    // Let's check DivisionalChartData model. It stores positions as Map<String, double>.
    // Ascendant sign is stored as int? ascendantSign.
    // Ideally we want degree too for precise rectification.
    // If DivisionalCharts calculator only gives Sign, we report Sign.
    return DivisionalCharts.getSignName(chart.ascendantSign!);
  }

  String _formatPosition(double longitude) {
    int sign = (longitude / 30).floor();
    double degree = longitude % 30;
    return "${degree.toStringAsFixed(2)}° ${DivisionalCharts.getSignName(sign)}";
  }

  String _getPlanetSign(CompleteChartData data, String planet) {
    for (var entry in data.baseChart.planets.entries) {
      if (entry.key.toString().toLowerCase().contains(planet.toLowerCase())) {
        return _formatPosition(entry.value.longitude);
      }
    }
    return "-";
  }

  String _getDivisionalPlanetSign(
    CompleteChartData data,
    String div,
    String planet,
  ) {
    var chart = data.divisionalCharts[div];
    if (chart == null) return "-";
    // positions is Map<String, double>
    // We need to find key that matches planet
    for (var key in chart.positions.keys) {
      if (key.toLowerCase().contains(planet.toLowerCase())) {
        return _formatPosition(chart.positions[key]!);
      }
    }
    return "-";
  }
}

class RectificationData {
  final DateTime adjustedTime;
  final Duration adjustment;
  final String d1Ascendant;
  final String d9Ascendant;
  final String d60Ascendant;
  final String moonSign;
  final String d9MoonSign;

  RectificationData({
    required this.adjustedTime,
    required this.adjustment,
    required this.d1Ascendant,
    required this.d9Ascendant,
    required this.d60Ascendant,
    required this.moonSign,
    required this.d9MoonSign,
  });
}
