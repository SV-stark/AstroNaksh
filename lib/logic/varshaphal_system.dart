import 'package:jyotish/jyotish.dart';
import '../data/models.dart';
import 'custom_chart_service.dart';

/// Varshaphal (Annual Chart) System
/// Calculates solar return charts and Tajik/Varshik predictions
class VarshaphalSystem {
  /// Calculate Varshaphal chart for a given year
  /// Solar return: when Sun returns to exact natal position
  static Future<VarshaphalChart> calculateVarshaphal(
    BirthData birthData,
    int year,
  ) async {
    // Calculate when Sun returns to natal position in the given year
    final solarReturnTime = await _calculateSolarReturn(birthData, year);

    // Calculate chart for solar return moment
    final varshaphalChart = await _calculateChart(
      birthData.location,
      solarReturnTime,
    );

    // Calculate Muntha (annual indicator)
    final muntha = _calculateMuntha(birthData, year);

    // Calculate Varshik Dasha
    final varshikDasha = _calculateVarshikDasha(varshaphalChart);

    // Calculate Sahams (Arabic Parts)
    final sahams = _calculateSahams(varshaphalChart);

    // Get year lord
    final yearLord = _getYearLord(year);

    return VarshaphalChart(
      year: year,
      solarReturnTime: solarReturnTime,
      chart: varshaphalChart,
      muntha: muntha,
      varshikDasha: varshikDasha,
      sahams: sahams,
      yearLord: yearLord,
      interpretation: _generateInterpretation(varshaphalChart, muntha, sahams),
    );
  }

  /// Calculate exact solar return time
  static Future<DateTime> _calculateSolarReturn(
    BirthData birthData,
    int year,
  ) async {
    // Get natal Sun position
    final chartService = CustomChartService();
    final natalChart = await chartService.calculateChart(
      dateTime: birthData.dateTime,
      location: GeographicLocation(
        latitude: birthData.location.latitude,
        longitude: birthData.location.longitude,
      ),
      ayanamsaMode: SiderealMode.lahiri, // Use Lahiri as default
    );

    final natalSunLong = _getSunLongitude(natalChart);

    // Start from approximate birthday in target year
    DateTime searchDate = DateTime(
      year,
      birthData.dateTime.month,
      birthData.dateTime.day,
      12, // Start at noon
    );

    // Binary search for exact solar return (within 1 minute accuracy)
    DateTime start = searchDate.subtract(const Duration(days: 2));
    DateTime end = searchDate.add(const Duration(days: 2));

    while (end.difference(start).inMinutes > 1) {
      DateTime mid = start.add(
        Duration(milliseconds: end.difference(start).inMilliseconds ~/ 2),
      );

      final testChart = await chartService.calculateChart(
        dateTime: mid,
        location: GeographicLocation(
          latitude: birthData.location.latitude,
          longitude: birthData.location.longitude,
        ),
        ayanamsaMode: SiderealMode.lahiri,
      );

      final testSunLong = _getSunLongitude(testChart);
      double diff = (testSunLong - natalSunLong).abs();
      if (diff > 180) diff = 360 - diff;

      if (diff < 0.01) {
        // Within 1 arc-minute
        return mid;
      }

      // Determine which half to search
      final beforeChart = await chartService.calculateChart(
        dateTime: start,
        location: GeographicLocation(
          latitude: birthData.location.latitude,
          longitude: birthData.location.longitude,
        ),
        ayanamsaMode: SiderealMode.lahiri,
      );
      final beforeSunLong = _getSunLongitude(beforeChart);

      if ((testSunLong - natalSunLong).abs() <
          (beforeSunLong - natalSunLong).abs()) {
        start = mid;
      } else {
        end = mid;
      }
    }

    return start;
  }

  /// Calculate Muntha position
  /// Muntha moves one sign forward each year from Lagna
  static int _calculateMuntha(BirthData birthData, int year) {
    final age = year - birthData.dateTime.year;
    // For first year, Muntha = Lagna
    // Each subsequent year, Muntha moves one sign forward
    // Since we don't have the natal chart here, return placeholder
    // In real implementation, would need natal Lagna
    return age % 12; // Simplified
  }

  /// Calculate Varshik (Annual) Dasha
  /// Based on weekday of solar return
  static List<VarshikDashaPeriod> _calculateVarshikDasha(VedicChart chart) {
    // Get weekday of solar return
    // Each weekday has a ruling planet that starts the year
    // Sequence starts based on weekday (simplified for now)

    // In actual implementation, would get from chart datetime
    // For now, use placeholder sequence
    final sequence = [
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
    ];

    final periods = <VarshikDashaPeriod>[];
    final monthDuration = 365.25 / 12; // Average month in days

    DateTime startDate = DateTime.now(); // Placeholder
    for (int i = 0; i < 12; i++) {
      final planet = sequence[i % 7];
      final daysInPeriod = monthDuration;

      periods.add(
        VarshikDashaPeriod(
          planet: planet,
          startDate: startDate,
          endDate: startDate.add(Duration(days: daysInPeriod.round())),
          durationDays: daysInPeriod,
        ),
      );

      startDate = startDate.add(Duration(days: daysInPeriod.round()));
    }

    return periods;
  }

  /// Calculate Sahams (Arabic Parts/Lots)
  static Map<String, SahamPoint> _calculateSahams(VedicChart chart) {
    final sahams = <String, SahamPoint>{};

    // Get planet longitudes
    final sunLong = _getPlanetLongitude(chart, Planet.sun);
    final moonLong = _getPlanetLongitude(chart, Planet.moon);
    final ascLong = _getAscendantLongitude(chart);

    // Saham of Fortune (Punya Saham)
    // Day: Asc + Moon - Sun, Night: Asc + Sun - Moon
    final fortuneLong = (ascLong + moonLong - sunLong) % 360;
    sahams['Fortune'] = SahamPoint(
      name: 'Punya Saham (Fortune)',
      longitude: fortuneLong,
      interpretation: 'Wealth, prosperity, and material success',
    );

    // Saham of Life (Aayu Saham)
    // Asc + Saturn - Jupiter
    final saturnLong = _getPlanetLongitude(chart, Planet.saturn);
    final jupiterLong = _getPlanetLongitude(chart, Planet.jupiter);
    final lifeLong = (ascLong + saturnLong - jupiterLong) % 360;
    sahams['Life'] = SahamPoint(
      name: 'Aayu Saham (Life)',
      longitude: lifeLong,
      interpretation: 'Longevity and vitality for the year',
    );

    // Saham of Fortune in Love (Prema Saham)
    // Asc + Venus - Sun
    final venusLong = _getPlanetLongitude(chart, Planet.venus);
    final loveLong = (ascLong + venusLong - sunLong) % 360;
    sahams['Love'] = SahamPoint(
      name: 'Prema Saham (Love)',
      longitude: loveLong,
      interpretation: 'Relationships and romantic prospects',
    );

    return sahams;
  }

  /// Get year lord based on year number
  static String _getYearLord(int year) {
    final lords = [
      'Sun',
      'Venus',
      'Mercury',
      'Moon',
      'Saturn',
      'Jupiter',
      'Mars',
    ];
    return lords[year % 7];
  }

  /// Generate interpretation for Varshaphal
  static String _generateInterpretation(
    VedicChart chart,
    int muntha,
    Map<String, SahamPoint> sahams,
  ) {
    final interpretation = StringBuffer();

    interpretation.writeln('Annual Chart Interpretation:');
    interpretation.writeln();

    // Muntha interpretation
    interpretation.writeln('Muntha Position:');
    interpretation.writeln(
      'Muntha in ${_getSignName(muntha)} - '
      'Focus area for the year based on house themes.',
    );
    interpretation.writeln();

    // Saham interpretations
    interpretation.writeln('Key Sahams (Arabic Parts):');
    sahams.forEach((key, saham) {
      final sign = (saham.longitude / 30).floor();
      interpretation.writeln(
        '${saham.name} in ${_getSignName(sign)} - ${saham.interpretation}',
      );
    });

    return interpretation.toString();
  }

  // Helper methods
  static Future<VedicChart> _calculateChart(
    Location location,
    DateTime dateTime,
  ) async {
    final chartService = CustomChartService();
    return await chartService.calculateChart(
      dateTime: dateTime,
      location: GeographicLocation(
        latitude: location.latitude,
        longitude: location.longitude,
      ),
      ayanamsaMode: SiderealMode.lahiri,
    );
  }

  static double _getSunLongitude(VedicChart chart) {
    return chart.planets[Planet.sun]!.longitude;
  }

  static double _getPlanetLongitude(VedicChart chart, Planet planet) {
    return chart.planets[planet]?.longitude ?? 0.0;
  }

  static double _getAscendantLongitude(VedicChart chart) {
    return chart.houses.cusps[0];
  }

  static String _getSignName(int sign) {
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
    return signs[sign % 12];
  }
}

/// Varshaphal Chart data
class VarshaphalChart {
  final int year;
  final DateTime solarReturnTime;
  final VedicChart chart;
  final int muntha;
  final List<VarshikDashaPeriod> varshikDasha;
  final Map<String, SahamPoint> sahams;
  final String yearLord;
  final String interpretation;

  VarshaphalChart({
    required this.year,
    required this.solarReturnTime,
    required this.chart,
    required this.muntha,
    required this.varshikDasha,
    required this.sahams,
    required this.yearLord,
    required this.interpretation,
  });
}

/// Varshik Dasha Period
class VarshikDashaPeriod {
  final String planet;
  final DateTime startDate;
  final DateTime endDate;
  final double durationDays;

  VarshikDashaPeriod({
    required this.planet,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
  });
}

/// Saham (Arabic Part) Point
class SahamPoint {
  final String name;
  final double longitude;
  final String interpretation;

  SahamPoint({
    required this.name,
    required this.longitude,
    required this.interpretation,
  });

  int get sign => (longitude / 30).floor();
  double get degreeInSign => longitude % 30;
}
