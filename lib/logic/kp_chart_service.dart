import 'package:jyotish/jyotish.dart';
import '../core/ephemeris_manager.dart';
import '../data/models.dart';
import 'kp_extensions.dart';

class KPChartService {
  final Jyotish _jyotish = EphemerisManager.jyotish;

  Future<ChartData> generateKPChart(BirthData birthData) async {
    // Ensure ephemeris is ready
    await EphemerisManager.ensureEphemerisData();

    // Use jyotish for base calculations
    final chart = await _jyotish.calculateVedicChart(
      dateTime: birthData.dateTime,
      location: birthData.location,
      // flags removed as undefined
    );

    // Add KP-specific calculations
    final kpExtensions = await _calculateKPExtensions(chart);

    return ChartData(baseChart: chart, kpData: kpExtensions);
  }

  Future<KPData> _calculateKPExtensions(VedicChart chart) async {
    return KPData(
      subLords: _calculateSubLords(chart),
      significators: _calculateSignificators(chart),
      rulingPlanets: _calculateRulingPlanets(chart),
    );
  }

  List<KPSubLord> _calculateSubLords(VedicChart chart) {
    // Calculate for planets
    // Assuming chart.planets is a Map<Planet, VedicPlanetInfo>
    return chart.planets.entries.map((entry) {
      return KPExtensions.calculateSubLord(entry.value.longitude);
    }).toList();
  }

  List<String> _calculateSignificators(VedicChart chart) {
    // Calculate for all houses (1-12)
    final Set<String> allSignificators = {};
    for (int i = 1; i <= 12; i++) {
      allSignificators.addAll(KPExtensions.calculateSignificators(chart, i));
    }
    return allSignificators.toList();
  }

  List<String> _calculateRulingPlanets(VedicChart chart) {
    // TODO: Implement ruling planets logic
    return [];
  }
}
