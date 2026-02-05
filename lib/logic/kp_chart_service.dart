import 'package:jyotish/jyotish.dart';
import '../core/ephemeris_manager.dart';
import '../data/models.dart';
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

    // Use library's native KP calculation
    final nativeKPData = EphemerisManager.jyotish.calculateKPData(chart);

    // Calculate all systems
    final kpData = _mapNativeKPData(nativeKPData, chart);
    final dashaData = _calculateDashaSystems(chart);
    final divisionalCharts = DivisionalCharts.calculateAllCharts(chart);
    final significatorTable = _generateSignificatorTable(nativeKPData, chart);

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

  KPData _mapNativeKPData(dynamic nativeKPData, VedicChart chart) {
    // Map planetary data to our KPSubLord model
    final List<KPSubLord> subLords = [];

    chart.planets.forEach((planet, info) {
      final planetKP = nativeKPData.planetaryData[planet];
      if (planetKP != null) {
        subLords.add(
          KPSubLord(
            starLord: planetKP.starLord.displayName,
            subLord: planetKP.subLord.displayName,
            subSubLord: planetKP.subSubLord?.displayName ?? '--',
            nakshatraIndex: info.position.nakshatraIndex,
            nakshatraName: info.nakshatra,
          ),
        );
      }
    });

    // significators and ruling planets from native data
    // Map significations to string list
    final List<String> significators = [];
    nativeKPData.houseSignificators.forEach((house, list) {
      significators.addAll(list.cast<String>());
    });

    final List<String> rulingPlanets = nativeKPData.rulingPlanets
        .map<String>((p) => p.displayName as String)
        .toList();

    return KPData(
      subLords: subLords,
      significators: significators.toSet().toList(),
      rulingPlanets: rulingPlanets,
    );
  }

  Map<String, Map<String, dynamic>> _generateSignificatorTable(
    dynamic nativeKPData,
    VedicChart chart,
  ) {
    final Map<String, Map<String, dynamic>> table = {};

    chart.planets.forEach((planet, info) {
      final planetName = planet.toString().split('.').last;
      final planetKP = nativeKPData.planetaryData[planet];

      if (planetKP != null) {
        table[planetName] = {
          'position': info.longitude,
          'house': chart.houses.getHouseForLongitude(info.longitude) + 1,
          'starLord': planetKP.starLord.displayName,
          'subLord': planetKP.subLord.displayName,
          'subSubLord': planetKP.subSubLord?.displayName ?? '--',
          'nakshatra': info.nakshatra,
          'significations': planetKP.significations.toList(),
        };
      }
    });

    return table;
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
