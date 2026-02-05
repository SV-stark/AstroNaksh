import 'package:jyotish/jyotish.dart';
import '../data/models.dart';

/// Complete Divisional Charts (Varga) Calculation System
/// Calculates planetary positions for all 16 major divisional charts
class DivisionalCharts {
  /// Calculate all 16 divisional charts for a given rasi chart
  /// Returns a map of chart codes to DivisionalChartData objects
  static Map<String, DivisionalChartData> calculateAllCharts(VedicChart chart) {
    _service ??= DivisionalChartService();

    final result = <String, DivisionalChartData>{};

    for (final type in DivisionalChartType.values) {
      final code = type.code.toUpperCase().replaceFirst('D', 'D-');
      final dChart = _service!.calculateDivisionalChart(chart, type);

      result[code] = _mapToData(dChart, type);
    }

    return result;
  }

  static DivisionalChartService? _service;

  static DivisionalChartData _mapToData(
    VedicChart dChart,
    DivisionalChartType type,
  ) {
    final positions = <String, double>{};

    dChart.planets.forEach((planet, info) {
      final planetName = planet.toString().split('.').last;
      // Capitalize first letter to match expected format if necessary
      final formattedName =
          planetName[0].toUpperCase() + planetName.substring(1);
      positions[formattedName] = info.longitude;
    });

    // Add Rahu/Ketu explicitly if not already in planets map with correct names
    positions['Rahu'] = dChart.rahu.longitude;
    positions['Ketu'] = dChart.ketu.longitude;

    return DivisionalChartData(
      code: type.code.toUpperCase().replaceFirst('D', 'D-'),
      name: type.name,
      description: type.significance,
      positions: positions,
      ascendantSign: (dChart.ascendant / 30).floor(),
    );
  }

  /// Get zodiac sign name from index (0-11)
  static String getSignName(int sign) => AstrologyConstants.getSignName(sign);

  /// Get sign lord
  static String getSignLord(int sign) => AstrologyConstants.getSignLord(sign);
}
