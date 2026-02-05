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
    final varshikDasha = _calculateVarshikDasha(
      varshaphalChart,
      solarReturnTime,
    );

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

  /// Calculate Varshik (Annual) Dasha with predictions
  /// Based on weekday of solar return
  static List<VarshikDashaPeriod> _calculateVarshikDasha(
    VedicChart chart,
    DateTime solarReturnTime,
  ) {
    // Get weekday of solar return to determine starting planet
    final weekday = solarReturnTime.weekday; // 1=Monday, 7=Sunday
    final sequence = _getDashaSequence(weekday);

    final periods = <VarshikDashaPeriod>[];
    final monthDuration = 365.25 / 12; // ~30.4 days per period

    DateTime startDate = solarReturnTime;
    for (int i = 0; i < 12; i++) {
      final planet = sequence[i % 7];
      final daysInPeriod = monthDuration;
      final endDate = startDate.add(Duration(days: daysInPeriod.round()));

      // Generate prediction for this period
      final predictionData = _generatePeriodPrediction(planet, chart, i);

      periods.add(
        VarshikDashaPeriod(
          planet: planet,
          startDate: startDate,
          endDate: endDate,
          durationDays: daysInPeriod,
          prediction: predictionData['prediction'] as String,
          keyThemes: predictionData['themes'] as List<String>,
          cautions: predictionData['cautions'] as List<String>,
          favorableScore: predictionData['score'] as double,
        ),
      );

      startDate = endDate;
    }

    return periods;
  }

  /// Get dasha sequence based on weekday of solar return
  static List<String> _getDashaSequence(int weekday) {
    // Tajik Varshik Dasha sequence
    final baseSequence = [
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
    ];

    // Weekday lords: 1=Mon(Moon), 2=Tue(Mars), 3=Wed(Mercury), 4=Thu(Jupiter), 5=Fri(Venus), 6=Sat(Saturn), 7=Sun(Sun)
    final weekdayLord = [
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
      'Sun',
    ][weekday - 1];

    // Find starting index
    final startIndex = baseSequence.indexOf(weekdayLord);

    // Create rotated sequence
    final sequence = <String>[];
    for (int i = 0; i < 7; i++) {
      sequence.add(baseSequence[(startIndex + i) % 7]);
    }

    return sequence;
  }

  /// Generate prediction for a Varshik Dasha period
  static Map<String, dynamic> _generatePeriodPrediction(
    String planet,
    VedicChart chart,
    int periodIndex,
  ) {
    // Get planet's position in the annual chart
    final planetEnum = _getPlanetFromString(planet);
    final planetLong = _getPlanetLongitude(chart, planetEnum);
    final planetSign = (planetLong / 30).floor();
    final planetHouse = _getHouseNumber(chart, planetLong);

    // Generate prediction based on planet and its position
    final predictions = _getPlanetPeriodPredictions(
      planet,
      planetSign,
      planetHouse,
    );

    return {
      'prediction': predictions['main'] as String,
      'themes': predictions['themes'] as List<String>,
      'cautions': predictions['cautions'] as List<String>,
      'score': predictions['score'] as double,
    };
  }

  /// Get detailed period predictions for each planet
  static Map<String, dynamic> _getPlanetPeriodPredictions(
    String planet,
    int sign,
    int house,
  ) {
    switch (planet) {
      case 'Sun':
        return {
          'main':
              'Period of authority, recognition, and self-expression. Focus on career advancement and leadership roles. Good time for government-related matters and dealings with authority figures.',
          'themes': [
            'Career growth',
            'Authority',
            'Recognition',
            'Government dealings',
          ],
          'cautions': [
            'Avoid ego conflicts',
            'Health - watch heart and vitality',
          ],
          'score': house == 1 || house == 5 || house == 9 || house == 10
              ? 0.8
              : 0.6,
        };

      case 'Moon':
        return {
          'main':
              'Period of emotional growth, intuition, and domestic matters. Excellent for family activities, real estate, and nurturing relationships. Mind is receptive and creative.',
          'themes': [
            'Family harmony',
            'Emotional balance',
            'Creativity',
            'Real estate',
          ],
          'cautions': [
            'Emotional volatility',
            'Avoid major decisions during mood swings',
          ],
          'score': house == 4 || house == 2 || house == 7 ? 0.9 : 0.7,
        };

      case 'Mars':
        return {
          'main':
              'Period of energy, action, and initiative. Good for starting new ventures, physical activities, and competitive pursuits. Courage and determination are heightened.',
          'themes': [
            'New beginnings',
            'Physical strength',
            'Competition',
            'Courage',
          ],
          'cautions': [
            'Avoid impulsive actions',
            'Watch for conflicts and accidents',
            'Control anger',
          ],
          'score': house == 1 || house == 3 || house == 10 || house == 11
              ? 0.75
              : 0.5,
        };

      case 'Mercury':
        return {
          'main':
              'Period of communication, learning, and intellectual pursuits. Excellent for studies, writing, business negotiations, and short travels. Mental clarity and analytical skills are strong.',
          'themes': [
            'Learning',
            'Communication',
            'Business',
            'Writing',
            'Travel',
          ],
          'cautions': [
            'Avoid overthinking',
            'Double-check contracts',
            'Watch for miscommunication',
          ],
          'score': house == 3 || house == 6 || house == 10 ? 0.85 : 0.7,
        };

      case 'Jupiter':
        return {
          'main':
              'Period of expansion, wisdom, and good fortune. Highly favorable for education, spirituality, wealth accumulation, and legal matters. Wisdom and guidance come naturally.',
          'themes': [
            'Spiritual growth',
            'Financial gains',
            'Education',
            'Wisdom',
            'Children',
          ],
          'cautions': ['Avoid overindulgence', 'Don\'t take unnecessary risks'],
          'score': house == 1 || house == 5 || house == 9 || house == 11
              ? 0.95
              : 0.8,
        };

      case 'Venus':
        return {
          'main':
              'Period of pleasure, beauty, relationships, and artistic expression. Excellent for romance, creative projects, social activities, and enjoying life\'s comforts.',
          'themes': ['Romance', 'Creativity', 'Social life', 'Luxury', 'Arts'],
          'cautions': [
            'Avoid excessive spending',
            'Don\'t overindulge in pleasures',
            'Watch relationships',
          ],
          'score': house == 2 || house == 4 || house == 5 || house == 7
              ? 0.9
              : 0.75,
        };

      case 'Saturn':
        return {
          'main':
              'Period of discipline, hard work, and karmic lessons. Focus on long-term goals, responsibilities, and practical matters. Rewards come through sustained effort and patience.',
          'themes': [
            'Hard work',
            'Discipline',
            'Long-term planning',
            'Responsibility',
          ],
          'cautions': [
            'Delays are possible',
            'Health concerns',
            'Avoid shortcuts',
            'Be patient',
          ],
          'score': house == 3 || house == 6 || house == 10 || house == 11
              ? 0.7
              : 0.4,
        };

      default:
        return {
          'main': 'Period of mixed influences. Stay balanced and adaptable.',
          'themes': ['Balance', 'Adaptability'],
          'cautions': ['Stay cautious'],
          'score': 0.5,
        };
    }
  }

  /// Get house number for a longitude
  static int _getHouseNumber(VedicChart chart, double longitude) {
    final ascendant = chart.houses.cusps[0];
    final relativeDegree = (longitude - ascendant + 360) % 360;
    return (relativeDegree / 30).floor() + 1;
  }

  /// Convert string to Planet enum
  static Planet _getPlanetFromString(String planetName) {
    switch (planetName) {
      case 'Sun':
        return Planet.sun;
      case 'Moon':
        return Planet.moon;
      case 'Mars':
        return Planet.mars;
      case 'Mercury':
        return Planet.mercury;
      case 'Jupiter':
        return Planet.jupiter;
      case 'Venus':
        return Planet.venus;
      case 'Saturn':
        return Planet.saturn;
      default:
        return Planet.sun;
    }
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

/// Varshik Dasha Period with Predictions
class VarshikDashaPeriod {
  final String planet;
  final DateTime startDate;
  final DateTime endDate;
  final double durationDays;
  final String prediction;
  final List<String> keyThemes;
  final List<String> cautions;
  final double favorableScore; // 0.0 to 1.0

  VarshikDashaPeriod({
    required this.planet,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required this.prediction,
    required this.keyThemes,
    required this.cautions,
    this.favorableScore = 0.5,
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
