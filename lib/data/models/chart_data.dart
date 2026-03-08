import 'package:jyotish/jyotish.dart';
import 'kp.dart';
import 'dasha.dart';
import 'divisional_chart.dart';
import 'location.dart';

class ChartData {
  final VedicChart baseChart;
  final KPData kpData;

  ChartData({required this.baseChart, required this.kpData});
}

/// Complete chart data with all systems
class CompleteChartData {
  final VedicChart baseChart;
  final KPData kpData;
  final DashaData dashaData;
  final Map<String, DivisionalChartData> divisionalCharts;
  final Map<String, Map<String, dynamic>> significatorTable;
  final BirthData birthData;

  CompleteChartData({
    required this.baseChart,
    required this.kpData,
    required this.dashaData,
    required this.divisionalCharts,
    required this.significatorTable,
    required this.birthData,
  });

  /// Get planet info with KP data
  Map<String, dynamic>? getPlanetInfo(String planetName) {
    return significatorTable[planetName];
  }

  /// Get current running dashas
  Map<String, dynamic> getCurrentDashas(DateTime date) {
    Mahadasha? currentMaha;
    for (final m in dashaData.vimshottari.mahadashas) {
      if (date.isAfter(m.startDate) && date.isBefore(m.endDate)) {
        currentMaha = m;
        break;
      }
    }
    if (currentMaha == null) return {};

    Antardasha? currentAntar;
    for (final a in currentMaha.antardashas) {
      if (date.isAfter(a.startDate) && date.isBefore(a.endDate)) {
        currentAntar = a;
        break;
      }
    }
    if (currentAntar == null) return {};

    Pratyantardasha? currentPratyan;
    for (final p in currentAntar.pratyantardashas) {
      if (date.isAfter(p.startDate) && date.isBefore(p.endDate)) {
        currentPratyan = p;
        break;
      }
    }
    if (currentPratyan == null) return {};

    return {
      'mahadasha': currentMaha.lord,
      'antardasha': currentAntar.lord,
      'pratyantardasha': currentPratyan.lord,
      'mahaStart': currentMaha.startDate,
      'mahaEnd': currentMaha.endDate,
      'antarStart': currentAntar.startDate,
      'antarEnd': currentAntar.endDate,
      'pratyanStart': currentPratyan.startDate,
      'pratyanEnd': currentPratyan.endDate,
    };
  }

  /// Get formatted D-9 chart positions
  String getNavamsaPositions() {
    final navamsa = divisionalCharts['D-9'];
    if (navamsa == null) return 'Navamsa not available';
    return navamsa.getFormattedPositions();
  }
}
