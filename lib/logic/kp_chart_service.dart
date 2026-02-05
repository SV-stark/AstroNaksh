import 'package:jyotish/jyotish.dart';
import '../core/ephemeris_manager.dart';
import '../data/models.dart';
import 'kp_extensions.dart';
import 'dasha_system.dart';
import 'divisional_charts.dart';
import 'custom_chart_service.dart'; // New service

import '../core/settings_manager.dart';
import '../core/ayanamsa_calculator.dart'; // For converting string to mode

class KPChartService {
  final CustomChartService _chartService = CustomChartService();

  Future<CompleteChartData> generateCompleteChart(BirthData birthData) async {
    // Ensure ephemeris is ready
    try {
      await EphemerisManager.ensureEphemerisData();
    } catch (e) {
      // Log error but continue - chart generation may still work
      // Silently continue - jyotish library might already have data
    }

    // Get current Ayanamsa setting
    final ayanamsaName = SettingsManager().chartSettings.ayanamsaSystem;

    SiderealMode mode;
    double? overrideAyanamsa;

    if (ayanamsaName == 'newKP') {
      mode =
          SiderealMode.lahiri; // Placeholder, ignored when override is present
      overrideAyanamsa = AyanamsaCalculator.calculateNewKPAyanamsa(
        birthData.dateTime,
      );
    } else {
      final ayanamsaSystem = AyanamsaCalculator.getSystem(ayanamsaName);
      // Default to Lahiri if not found or if mode is null (shouldn't happen for standard systems)
      mode = ayanamsaSystem?.mode ?? SiderealMode.lahiri;
    }

    // Use custom service for base calculations with selected Ayanamsa
    final chart = await _chartService.calculateChart(
      dateTime: birthData.dateTime,
      location: GeographicLocation(
        latitude: birthData.location.latitude,
        longitude: birthData.location.longitude,
        altitude: 0,
      ),
      ayanamsaMode: mode,
      overrideAyanamsa: overrideAyanamsa,
      timezone: birthData.timezone,
    );

    // Calculate all systems
    final kpData = await _calculateKPExtensions(chart);
    final dashaData = _calculateDashaSystems(chart);
    final divisionalCharts = DivisionalCharts.calculateAllCharts(chart);
    final significatorTable = KPExtensions.getFullSignificatorTable(chart);

    return CompleteChartData(
      baseChart: chart,
      kpData: kpData,
      dashaData: dashaData,
      divisionalCharts: divisionalCharts,
      significatorTable: significatorTable,
      birthData: birthData,
    );
  }

  Future<ChartData> generateKPChart(BirthData birthData) async {
    final completeData = await generateCompleteChart(birthData);
    return ChartData(
      baseChart: completeData.baseChart,
      kpData: completeData.kpData,
    );
  }

  Future<KPData> _calculateKPExtensions(VedicChart chart) async {
    return KPData(
      subLords: _calculateSubLords(chart),
      significators: _calculateSignificators(chart),
      rulingPlanets: _calculateRulingPlanets(chart),
    );
  }

  List<KPSubLord> _calculateSubLords(VedicChart chart) {
    return chart.planets.entries.map((entry) {
      return KPExtensions.calculateSubLord(entry.value.longitude);
    }).toList();
  }

  List<String> _calculateSignificators(VedicChart chart) {
    final Set<String> allSignificators = {};
    for (int i = 1; i <= 12; i++) {
      // Flatten ABCD structure to get all acting significators
      final abcdMap = KPExtensions.calculateSignificators(chart, i);
      for (final list in abcdMap.values) {
        allSignificators.addAll(list);
      }
    }
    return allSignificators.toList();
  }

  List<String> _calculateRulingPlanets(VedicChart chart) {
    return KPExtensions.calculateRulingPlanets(chart, DateTime.now());
  }

  DashaData _calculateDashaSystems(VedicChart chart) {
    return DashaData(
      vimshottari: DashaSystem.calculateVimshottariDasha(chart),
      yogini: DashaSystem.calculateYoginiDasha(chart),
      chara: DashaSystem.calculateCharaDasha(chart),
    );
  }

  /// Get current dasha for a specific date
  Map<String, dynamic> getCurrentDasha(
    CompleteChartData chartData,
    DateTime date,
  ) {
    return DashaSystem.getCurrentDasha(chartData.dashaData.vimshottari, date);
  }

  /// Get divisional chart by code (e.g., 'D-9')
  DivisionalChartData? getDivisionalChart(
    CompleteChartData chartData,
    String code,
  ) {
    return chartData.divisionalCharts[code];
  }
}
