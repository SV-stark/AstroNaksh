import 'package:jyotish/jyotish.dart';

// --- Basic Models ---

class Location {
  final double latitude;
  final double longitude;
  Location({required this.latitude, required this.longitude});
}

class BirthData {
  final DateTime dateTime;
  final Location location;

  BirthData({required this.dateTime, required this.location});
}

// --- KP System Models ---

class KPSubLord {
  final String starLord;
  final String subLord;
  final String subSubLord;
  final int nakshatraIndex;
  final String nakshatraName;

  KPSubLord({
    required this.starLord,
    required this.subLord,
    required this.subSubLord,
    this.nakshatraIndex = 0,
    this.nakshatraName = '',
  });
}

class KPData {
  final List<KPSubLord> subLords;
  final List<String> significators;
  final List<String> rulingPlanets;

  KPData({
    required this.subLords,
    required this.significators,
    required this.rulingPlanets,
  });
}

// --- Divisional Charts Models ---

/// Data class for divisional chart information
class DivisionalChartData {
  final String code; // e.g., 'D-9'
  final String name;
  final String description;
  final Map<String, double> positions; // planet name -> longitude
  final int? ascendantSign;

  DivisionalChartData({
    required this.code,
    required this.name,
    required this.description,
    required this.positions,
    this.ascendantSign,
  });

  /// Get planet's sign in this divisional chart
  int getPlanetSign(String planet) {
    final longitude = positions[planet];
    if (longitude == null) return 0;
    return (longitude / 30).floor();
  }

  /// Get formatted string showing planet positions
  String getFormattedPositions() {
    final buffer = StringBuffer();
    buffer.writeln('$name ($code) - $description');
    buffer.writeln('=' * 40);

    positions.forEach((planet, longitude) {
      final sign = (longitude / 30).floor();
      final degree = longitude % 30;
      final signName = _getSignName(sign);
      buffer.writeln('$planet: ${degree.toStringAsFixed(2)}° $signName');
    });

    if (ascendantSign != null) {
      buffer.writeln('Ascendant: ${_getSignName(ascendantSign!)}');
    }

    return buffer.toString();
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

// --- Dasha System Models ---

/// Vimshottari Dasha data class
class VimshottariDasha {
  final String birthLord;
  final double balanceAtBirth;
  final List<Mahadasha> mahadashas;

  VimshottariDasha({
    required this.birthLord,
    required this.balanceAtBirth,
    required this.mahadashas,
  });

  String get formattedBalanceAtBirth {
    final years = balanceAtBirth.floor();
    final months = ((balanceAtBirth - years) * 12).floor();
    final days = (((balanceAtBirth - years) * 12 - months) * 30).floor();
    return '$years years, $months months, $days days';
  }
}

/// Mahadasha data class
class Mahadasha {
  final String lord;
  final DateTime startDate;
  final DateTime endDate;
  final double periodYears;
  final List<Antardasha> antardashas;

  Mahadasha({
    required this.lord,
    required this.startDate,
    required this.endDate,
    required this.periodYears,
    required this.antardashas,
  });

  String get formattedPeriod {
    final years = periodYears.floor();
    final months = ((periodYears - years) * 12).floor();
    return '$years years $months months';
  }
}

/// Antardasha data class
class Antardasha {
  final String lord;
  final DateTime startDate;
  final DateTime endDate;
  final double periodYears;
  final List<Pratyantardasha> pratyantardashas;

  Antardasha({
    required this.lord,
    required this.startDate,
    required this.endDate,
    required this.periodYears,
    required this.pratyantardashas,
  });
}

/// Pratyantardasha data class
class Pratyantardasha {
  final String mahadashaLord;
  final String antardashaLord;
  final String lord;
  final DateTime startDate;
  final DateTime endDate;
  final double periodYears;

  Pratyantardasha({
    required this.mahadashaLord,
    required this.antardashaLord,
    required this.lord,
    required this.startDate,
    required this.endDate,
    required this.periodYears,
  });
}

/// Yogini Dasha data class
class YoginiDasha {
  final String startYogini;
  final List<YoginiMahadasha> mahadashas;

  YoginiDasha({required this.startYogini, required this.mahadashas});
}

/// Yogini Mahadasha data class
class YoginiMahadasha {
  final String name;
  final String lord;
  final DateTime startDate;
  final DateTime endDate;
  final double periodYears;

  YoginiMahadasha({
    required this.name,
    required this.lord,
    required this.startDate,
    required this.endDate,
    required this.periodYears,
  });
}

/// Chara Dasha data class
class CharaDasha {
  final int startSign;
  final List<CharaDashaPeriod> periods;

  CharaDasha({required this.startSign, required this.periods});
}

/// Chara Dasha Period data class
class CharaDashaPeriod {
  final int sign;
  final String signName;
  final String lord;
  final DateTime startDate;
  final DateTime endDate;
  final double periodYears;

  CharaDashaPeriod({
    required this.sign,
    required this.signName,
    required this.lord,
    required this.startDate,
    required this.endDate,
    required this.periodYears,
  });
}

/// Combined Dasha data
class DashaData {
  final VimshottariDasha vimshottari;
  final YoginiDasha yogini;
  final CharaDasha chara;

  DashaData({
    required this.vimshottari,
    required this.yogini,
    required this.chara,
  });
}

// --- Complete Chart Models ---

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
    for (final mahadasha in dashaData.vimshottari.mahadashas) {
      if (date.isAfter(mahadasha.startDate) &&
          date.isBefore(mahadasha.endDate)) {
        for (final antardasha in mahadasha.antardashas) {
          if (date.isAfter(antardasha.startDate) &&
              date.isBefore(antardasha.endDate)) {
            for (final pratyantardasha in antardasha.pratyantardashas) {
              if (date.isAfter(pratyantardasha.startDate) &&
                  date.isBefore(pratyantardasha.endDate)) {
                return {
                  'mahadasha': mahadasha.lord,
                  'antardasha': antardasha.lord,
                  'pratyantardasha': pratyantardasha.lord,
                  'mahaStart': mahadasha.startDate,
                  'mahaEnd': mahadasha.endDate,
                  'antarStart': antardasha.startDate,
                  'antarEnd': antardasha.endDate,
                  'pratyanStart': pratyantardasha.startDate,
                  'pratyanEnd': pratyantardasha.endDate,
                };
              }
            }
          }
        }
      }
    }
    return {};
  }

  /// Get formatted D-9 chart positions
  String getNavamsaPositions() {
    final navamsa = divisionalCharts['D-9'];
    if (navamsa == null) return 'Navamsa not available';
    return navamsa.getFormattedPositions();
  }
}
