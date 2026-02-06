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
    final nativeKPData = await EphemerisManager.jyotish.calculateKPData(chart);

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

  KPData _mapNativeKPData(KPCalculations nativeKPData, VedicChart chart) {
    // Map planetary data to our KPSubLord model
    final List<KPSubLord> subLords = [];

    chart.planets.forEach((planet, info) {
      final planetKP = nativeKPData.planetDivisions[planet];
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
    nativeKPData.planetSignificators.forEach((planet, sigs) {
      // Add 'Planet: Houses' string as a summary
      final houses = sigs.allSignificators.join(', ');
      if (houses.isNotEmpty) {
        significators.add('${planet.displayName}: $houses');
      }
    });

    // Manually Calculate Ruling Planets (Day Lord, Moon Sign/Star Lord, Lagna Sign/Star Lord)
    final rulingPlanets = <String>[];

    // 1. Day Lord
    // Jyotish doesn't expose calculating Vara directly from a chart, but we can compute it from DateTime
    // Using existing utility if available, or simple calculation
    // Since we don't have a direct Vara calculator in scope, let's look at Panchanga if needed.
    // However, easiest way is using DateTime.weekday for now.
    // Note: Vedic day starts at Sunrise, so this is an approximation if birth is before sunrise.
    // For now, let's use the standard weekday mapping.
    final dayLord = _getDayLord(chart.dateTime.weekday);
    rulingPlanets.add('${dayLord.displayName} (Day Lord)');

    // 2. Moon Sign Lord
    final moonInfo = chart.getPlanet(Planet.moon);
    if (moonInfo != null) {
      rulingPlanets.add(
        '${moonInfo.dignity == PlanetaryDignity.ownSign ? "Moon" : _getSignLord(moonInfo.zodiacSign)} (Moon Sign Lord)',
      );

      // 3. Moon Star Lord
      final moonKP = nativeKPData.planetDivisions[Planet.moon];
      if (moonKP != null) {
        rulingPlanets.add('${moonKP.starLord.displayName} (Moon Star Lord)');
      }
    }

    // 4. Lagna Sign Lord
    final ascSign = chart.ascendantSign;
    rulingPlanets.add('${_getSignLord(ascSign)} (Lagna Sign Lord)');

    // 5. Lagna Star Lord
    // We need to find the star lord for the Ascendant degree.
    // Since KPCalculations doesn't expose Lagna as a planet div, we might check houseDivisions[1]
    // or calculate it. Assuming houseDivisions[1] corresponds to Lagna (1st House Cusp).
    final lagnaKP = nativeKPData.houseDivisions[1];
    if (lagnaKP != null) {
      rulingPlanets.add('${lagnaKP.starLord.displayName} (Lagna Star Lord)');
    }

    return KPData(
      subLords: subLords,
      significators: significators,
      rulingPlanets: rulingPlanets,
    );
  }

  Map<String, Map<String, dynamic>> _generateSignificatorTable(
    KPCalculations nativeKPData,
    VedicChart chart,
  ) {
    final Map<String, Map<String, dynamic>> table = {};

    chart.planets.forEach((planet, info) {
      final planetName = planet.toString().split('.').last;

      // Use planetDivisions instead of planetaryData
      final planetKP = nativeKPData.planetDivisions[planet];
      // Use planetSignificators for significations
      final planetSig = nativeKPData.planetSignificators[planet];

      if (planetKP != null) {
        table[planetName] = {
          'position': info.longitude,
          'house': chart.houses.getHouseForLongitude(info.longitude),
          'starLord': planetKP.starLord.displayName,
          'subLord': planetKP.subLord.displayName,
          'subSubLord': planetKP.subSubLord?.displayName ?? '--',
          'nakshatra': info.nakshatra,
          'significations':
              planetSig?.allSignificators.toList() ??
              [], // Use allSignificators
        };
      }
    });

    return table;
  }

  // Helper to get Sign Lord name
  String _getSignLord(String signName) {
    // Basic mapping, or use a helper class if available
    switch (signName) {
      case 'Aries':
        return 'Mars';
      case 'Taurus':
        return 'Venus';
      case 'Gemini':
        return 'Mercury';
      case 'Cancer':
        return 'Moon';
      case 'Leo':
        return 'Sun';
      case 'Virgo':
        return 'Mercury';
      case 'Libra':
        return 'Venus';
      case 'Scorpio':
        return 'Mars';
      case 'Sagittarius':
        return 'Jupiter';
      case 'Capricorn':
        return 'Saturn';
      case 'Aquarius':
        return 'Saturn';
      case 'Pisces':
        return 'Jupiter';
      default:
        return '';
    }
  }

  // Helper to get Day Lord
  Planet _getDayLord(int weekday) {
    // DateTime.weekday: 1 = Mon, 7 = Sun
    // Vedic: Sun (0/7)=Sun, 1=Mon...
    // Let's map standard DateTime to Planets
    switch (weekday) {
      case 1:
        return Planet.moon; // Mon
      case 2:
        return Planet.mars; // Tue
      case 3:
        return Planet.mercury; // Wed
      case 4:
        return Planet.jupiter; // Thu
      case 5:
        return Planet.venus; // Fri
      case 6:
        return Planet.saturn; // Sat
      case 7:
        return Planet.sun; // Sun
      default:
        return Planet.sun;
    }
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
