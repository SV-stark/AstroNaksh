import 'package:jyotish/jyotish.dart';
import 'ephemeris_manager.dart';

/// Ayanamsa Calculation System
/// Supports multiple ayanamsa systems used in Vedic astrology
/// Wraps the [SiderealMode] from the jyotish library.
class AyanamsaCalculator {
  /// Get all available ayanamsa systems
  static List<AyanamsaSystem> get systems {
    // Define custom order: Lahiri first, then KP Old, then KP New, then rest
    final List<SiderealMode> orderedModes = [
      SiderealMode.lahiri,
      SiderealMode.krishnamurti,
      SiderealMode.krishnamurtiVP291,
      ...SiderealMode.values.where((m) =>
          m != SiderealMode.lahiri &&
          m != SiderealMode.krishnamurti &&
          m != SiderealMode.krishnamurtiVP291),
    ];

    return orderedModes.map((mode) {
      String name = mode.name;
      String description = mode.toString();

      // Custom names for KP systems with consistent naming
      if (mode == SiderealMode.krishnamurti) {
        description = "Krishnamurti (Old)";
      } else if (mode == SiderealMode.krishnamurtiVP291) {
        description = "Krishnamurti (New)";
        // Map 'newKP' identifier to this mode for backward compatibility
        name = 'newKP';
      }

      return AyanamsaSystem(name: name, description: description, mode: mode);
    }).toList();
  }

  /// Get a specific system by name
  static AyanamsaSystem? getSystem(String name) {
    if (name == 'newKP') {
      return const AyanamsaSystem(
        name: 'newKP',
        description: 'KP New',
        mode: SiderealMode.krishnamurtiVP291,
      );
    }

    try {
      final mode = SiderealMode.values.firstWhere(
        (m) => m.name.toLowerCase() == name.toLowerCase(),
      );

      String description = mode.toString();
      if (mode == SiderealMode.krishnamurti) {
        description = "KP Old";
      }

      return AyanamsaSystem(
        name: mode.name,
        description: description,
        mode: mode,
      );
    } catch (_) {
      return null;
    }
  }

  /// Calculate ayanamsa for a given date using specified system
  /// Returns 0.0 if the library fails or system is invalid
  static Future<double> calculate(String systemName, DateTime date) async {
    final system = getSystem(systemName);
    if (system == null || system.mode == null) return 0.0;

    try {
      await EphemerisManager.ensureEphemerisData();
      return await EphemerisManager.service.getAyanamsa(dateTime: date, mode: system.mode!);
    } catch (e) {
      throw Exception('Failed to calculate ayanamsa: $e');
    }
  }

  /// Convert tropical longitude to sidereal using ayanamsa
  static double tropicalToSidereal(double tropicalLongitude, double ayanamsa) {
    return _normalizeAngle(tropicalLongitude - ayanamsa);
  }

  /// Convert sidereal longitude to tropical using ayanamsa
  static double siderealToTropical(double siderealLongitude, double ayanamsa) {
    return _normalizeAngle(siderealLongitude + ayanamsa);
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

  /// Get default ayanamsa (New KP)
  static String get defaultAyanamsa => 'newKP';

  /// Get list of system names
  static List<String> get systemNames => systems.map((e) => e.name).toList();
}

/// Ayanamsa System Definition
class AyanamsaSystem {
  final String name;
  final String description;
  final SiderealMode? mode;

  const AyanamsaSystem({
    required this.name,
    required this.description,
    required this.mode,
  });
}

/// Settings manager for ayanamsa preferences
class AyanamsaSettings {
  String _currentSystem = 'lahiri';

  String get currentSystem => _currentSystem;

  void setSystem(String system) {
    if (AyanamsaCalculator.getSystem(system) != null) {
      _currentSystem = system;
    }
  }

  Future<double> calculateForDate(DateTime date) {
    return AyanamsaCalculator.calculate(_currentSystem, date);
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
