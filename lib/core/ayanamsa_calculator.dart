import 'package:jyotish/jyotish.dart';

/// Ayanamsa Calculation System
/// Supports multiple ayanamsa systems used in Vedic astrology
class AyanamsaCalculator {
  /// Available ayanamsa systems
  static const Map<String, AyanamsaSystem> systems = {
    'lahiri': AyanamsaSystem(
      name: 'Lahiri',
      description: 'Chitrapaksha Ayanamsa (Official India)',
      calculate: _calculateLahiri,
    ),
    'raman': AyanamsaSystem(
      name: 'Raman',
      description: 'B.V. Raman Ayanamsa',
      calculate: _calculateRaman,
    ),
    'krishnamurti': AyanamsaSystem(
      name: 'Krishnamurti',
      description: 'K.P. Ayanamsa (Jagannatha Centers)',
      calculate: _calculateKrishnamurti,
    ),
    'yukteswar': AyanamsaSystem(
      name: 'Yukteswar',
      description: 'Swami Sri Yukteswar',
      calculate: _calculateYukteswar,
    ),
    'jn': AyanamsaSystem(
      name: 'J.N. Bhasin',
      description: 'Jagannatha Bhasin',
      calculate: _calculateJNBhasin,
    ),
    'fagan': AyanamsaSystem(
      name: 'Fagan-Bradley',
      description: 'Western Sidereal (Fagan/Bradley)',
      calculate: _calculateFaganBradley,
    ),
    'de_luce': AyanamsaSystem(
      name: 'De Luce',
      description: 'Robert De Luce',
      calculate: _calculateDeLuce,
    ),
    'sassanian': AyanamsaSystem(
      name: 'Sassanian',
      description: 'Sassanian (Babylonian)',
      calculate: _calculateSassanian,
    ),
  };

  /// Calculate ayanamsa for a given date using specified system
  static double calculate(String systemName, DateTime date) {
    final system = systems[systemName.toLowerCase()];
    if (system == null) {
      throw ArgumentError('Unknown ayanamsa system: $systemName');
    }
    return system.calculate(date);
  }

  /// Lahiri Ayanamsa (Chitrapaksha) - Official for India
  /// Based on Lahiri Commission (1956)
  static double _calculateLahiri(DateTime date) {
    // Lahiri ayanamsa calculation
    // Reference epoch: 1900 Jan 1 = 22°27'37.7"
    final jd = _julianDay(date);
    final t = (jd - 2415020.0) / 36525.0; // Julian centuries from 1900

    // Lahiri formula (simplified)
    var ayanamsa = 22.460148 + 1.397167 * t + 0.000302 * t * t;

    return _normalizeAngle(ayanamsa);
  }

  /// B.V. Raman Ayanamsa
  static double _calculateRaman(DateTime date) {
    final jd = _julianDay(date);
    final t = (jd - 2415020.0) / 36525.0;

    // Raman's formula gives slightly different results
    var ayanamsa = 22.460148 + 1.397167 * t + 0.000302 * t * t;
    ayanamsa += 0.5; // Raman's adjustment

    return _normalizeAngle(ayanamsa);
  }

  /// K.P. (Krishnamurti) Ayanamsa
  /// Used in Krishnamurti Paddhati system
  static double _calculateKrishnamurti(DateTime date) {
    final jd = _julianDay(date);
    final t = (jd - 2415020.0) / 36525.0;

    // K.P. ayanamsa (approximately 6 minutes difference from Lahiri)
    var ayanamsa = 22.460148 + 1.397167 * t + 0.000302 * t * t;
    ayanamsa += 0.1; // K.P. adjustment

    return _normalizeAngle(ayanamsa);
  }

  /// Swami Sri Yukteswar Ayanamsa
  /// Based on Sri Yukteswar's calculations
  static double _calculateYukteswar(DateTime date) {
    // unused: final jd = _julianDay(date);
    final year = date.year + (date.month - 1) / 12 + date.day / 365.25;

    // Yukteswar's formula
    // Epoch 499 AD = 0° ayanamsa (ascending Dwapara Yuga)
    var ayanamsa = (year - 499) * (360 / 24000); // 24,000 year cycle

    return _normalizeAngle(ayanamsa);
  }

  /// J.N. Bhasin Ayanamsa
  static double _calculateJNBhasin(DateTime date) {
    final jd = _julianDay(date);
    final t = (jd - 2415020.0) / 36525.0;

    // Bhasin's formula
    var ayanamsa = 22.460148 + 1.397167 * t + 0.000302 * t * t;
    ayanamsa += 0.9; // Bhasin's adjustment

    return _normalizeAngle(ayanamsa);
  }

  /// Fagan-Bradley Ayanamsa
  /// Western sidereal astrology
  static double _calculateFaganBradley(DateTime date) {
    final jd = _julianDay(date);
    final t = (jd - 2451545.0) / 36525.0; // Julian centuries from J2000

    // Fagan-Bradley formula
    var ayanamsa = 24.013334 + 1.397167 * t + 0.000302 * t * t;

    return _normalizeAngle(ayanamsa);
  }

  /// Robert De Luce Ayanamsa
  static double _calculateDeLuce(DateTime date) {
    final jd = _julianDay(date);
    final t = (jd - 2415020.0) / 36525.0;

    // De Luce formula
    var ayanamsa = 22.460148 + 1.397167 * t + 0.000302 * t * t;
    ayanamsa -= 0.3; // De Luce adjustment

    return _normalizeAngle(ayanamsa);
  }

  /// Sassanian (Babylonian) Ayanamsa
  static double _calculateSassanian(DateTime date) {
    // unused: final jd = _julianDay(date);
    final year = date.year + date.month / 12 + date.day / 365.25;

    // Sassanian formula
    // Epoch 560 BC
    var ayanamsa = (year + 560) * (360 / 25772); // Great year cycle

    return _normalizeAngle(ayanamsa);
  }

  /// Convert tropical longitude to sidereal using ayanamsa
  static double tropicalToSidereal(double tropicalLongitude, double ayanamsa) {
    return _normalizeAngle(tropicalLongitude - ayanamsa);
  }

  /// Convert sidereal longitude to tropical using ayanamsa
  static double siderealToTropical(double siderealLongitude, double ayanamsa) {
    return _normalizeAngle(siderealLongitude + ayanamsa);
  }

  /// Get all ayanamsa values for a date
  static Map<String, double> getAllAyanamsas(DateTime date) {
    return {
      'Lahiri': calculate('lahiri', date),
      'Raman': calculate('raman', date),
      'Krishnamurti': calculate('krishnamurti', date),
      'Yukteswar': calculate('yukteswar', date),
      'J.N. Bhasin': calculate('jn', date),
      'Fagan-Bradley': calculate('fagan', date),
      'De Luce': calculate('de_luce', date),
      'Sassanian': calculate('sassanian', date),
    };
  }

  /// Calculate Julian Day from a DateTime
  /// Note: Converts to UTC first for consistent calculations
  static double _julianDay(DateTime date) {
    // Convert to UTC to ensure timezone-independent calculation
    final utcDate = date.toUtc();
    var year = utcDate.year;
    var month = utcDate.month;
    final day =
        utcDate.day +
        utcDate.hour / 24 +
        utcDate.minute / 1440 +
        utcDate.second / 86400;

    if (month <= 2) {
      year -= 1;
      month += 12;
    }

    final a = (year / 100).floor();
    final b = 2 - a + (a / 4).floor();

    return (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day +
        b -
        1524.5;
  }

  /// Normalize angle to 0-360 degrees
  static double _normalizeAngle(double angle) {
    var normalized = angle % 360;
    if (normalized < 0) normalized += 360;
    return normalized;
  }

  /// Format ayanamsa for display
  static String formatAyanamsa(double degrees) {
    final d = degrees.floor();
    final decimalMinutes = (degrees - d) * 60;
    final m = decimalMinutes.floor();
    final s = ((decimalMinutes - m) * 60).floor();
    return '$d° ${m.toString().padLeft(2, '0')}\' ${s.toString().padLeft(2, '0')}"';
  }

  /// Get default ayanamsa (Lahiri)
  static String get defaultAyanamsa => 'lahiri';

  /// Get list of system names
  static List<String> get systemNames => systems.keys.toList();

  /// Get system info
  static AyanamsaSystem? getSystem(String name) => systems[name.toLowerCase()];
}

/// Ayanamsa System Definition
class AyanamsaSystem {
  final String name;
  final String description;
  final double Function(DateTime) calculate;

  const AyanamsaSystem({
    required this.name,
    required this.description,
    required this.calculate,
  });
}

/// Settings manager for ayanamsa preferences
class AyanamsaSettings {
  // unused: static const String _defaultKey = 'ayanamsa_system';
  String _currentSystem = 'lahiri';

  String get currentSystem => _currentSystem;

  void setSystem(String system) {
    if (AyanamsaCalculator.systems.containsKey(system.toLowerCase())) {
      _currentSystem = system.toLowerCase();
    }
  }

  double calculateForDate(DateTime date) {
    return AyanamsaCalculator.calculate(_currentSystem, date);
  }

  /// Convert chart positions using current ayanamsa
  Map<Planet, double> convertChartPositions(
    Map<Planet, double> tropicalPositions,
    DateTime date,
  ) {
    final ayanamsa = calculateForDate(date);

    return tropicalPositions.map((planet, longitude) {
      return MapEntry(
        planet,
        AyanamsaCalculator.tropicalToSidereal(longitude, ayanamsa),
      );
    });
  }
}

/// Extension for easy ayanamsa conversion
extension AyanamsaConversion on double {
  /// Convert tropical to sidereal
  double toSidereal(double ayanamsa) {
    return AyanamsaCalculator.tropicalToSidereal(this, ayanamsa);
  }

  /// Convert sidereal to tropical
  double toTropical(double ayanamsa) {
    return AyanamsaCalculator.siderealToTropical(this, ayanamsa);
  }
}
