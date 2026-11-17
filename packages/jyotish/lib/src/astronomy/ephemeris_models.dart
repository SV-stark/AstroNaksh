import 'package:jyotish/src/models/planet.dart';

/// Represents planet visibility information.
class PlanetVisibility {
  const PlanetVisibility({
    required this.planet,
    required this.date,
    required this.isVisible,
    required this.visibilityType,
    required this.elongation,
    required this.magnitude,
    required this.sunrise,
    required this.sunset,
    required this.description,
  });

  /// The planet
  final Planet planet;

  /// The date checked
  final DateTime date;

  /// Whether the planet is visible
  final bool isVisible;

  /// Type of visibility
  final VisibilityType visibilityType;

  /// Elongation from Sun (degrees)
  final double elongation;

  /// Apparent magnitude (lower is brighter)
  final double magnitude;

  /// Sunrise time
  final DateTime? sunrise;

  /// Sunset time
  final DateTime? sunset;

  /// Description of visibility
  final String description;

  /// Whether this is a heliacal event (rise or set)
  bool get isHeliacal =>
      visibilityType == VisibilityType.heliacalRise ||
      visibilityType == VisibilityType.heliacalSet;
}

/// Types of planet visibility
enum VisibilityType {
  notVisible('Not Visible'),
  heliacalRise('Heliacal Rise'),
  heliacalSet('Heliacal Set'),
  daytime('Daytime Visible'),
  evening('Evening Star'),
  morning('Morning Star');

  const VisibilityType(this.name);
  final String name;
}

/// Types of eclipses
enum EclipseType {
  any('Any'),
  solar('Solar'),
  lunar('Lunar'),
  solarTotal('Solar Total'),
  solarPartial('Solar Partial'),
  solarAnnular('Solar Annular'),
  lunarTotal('Lunar Total'),
  lunarPartial('Lunar Partial'),
  lunarPenumbral('Lunar Penumbral');

  const EclipseType(this.name);
  final String name;
}

/// Represents eclipse data
class EclipseData {
  const EclipseData({
    required this.date,
    required this.eclipseType,
    required this.magnitude,
    required this.isVisible,
    required this.description,
    this.duration,
    this.startTime,
    this.endTime,
    this.maxEclipseTime,
    this.penumbralMagnitude,
    this.partialStartTime,
    this.partialEndTime,
    this.totalStartTime,
    this.totalEndTime,
    this.penumbralStartTime,
    this.penumbralEndTime,
    this.moonrise,
    this.moonset,
  });

  /// Date (moment of maximum eclipse - UTC)
  final DateTime date;

  /// Type of eclipse
  final EclipseType eclipseType;

  /// Umbral magnitude (0 = penumbral only, 1.0 = total)
  final double magnitude;

  /// Penumbral magnitude (2.18 for this eclipse)
  final double? penumbralMagnitude;

  /// Whether globally visible (always true for lunar)
  final bool isVisible;

  /// Human-readable description
  final String description;

  // ------------------------------------------------------------------
  // Global contact times (UTC, independent of observer location)
  // ------------------------------------------------------------------

  /// Duration of the umbral/partial phase (U1-U4)
  final Duration? duration;

  /// Umbral start (U1), or penumbral start (P1) when umbra absent
  final DateTime? startTime;

  /// Umbral end (U4), or penumbral end (P4) when umbra absent
  final DateTime? endTime;

  /// Moment of maximum eclipse
  final DateTime? maxEclipseTime;

  /// First contact with umbra - Partial begins (U1)
  final DateTime? partialStartTime;

  /// Last contact with umbra - Partial ends (U4)
  final DateTime? partialEndTime;

  /// Total phase begins - Moon fully in umbra (U2)
  final DateTime? totalStartTime;

  /// Total phase ends (U3)
  final DateTime? totalEndTime;

  /// First contact with penumbra (P1)
  final DateTime? penumbralStartTime;

  /// Last contact with penumbra (P4)
  final DateTime? penumbralEndTime;

  // ------------------------------------------------------------------
  // Location-specific fields (set when observer location is provided)
  // ------------------------------------------------------------------

  /// Moonrise at the observer's location (UTC). Null if Moon doesn't rise.
  final DateTime? moonrise;

  /// Moonset at the observer's location (UTC). Null if Moon doesn't set.
  final DateTime? moonset;

  // ------------------------------------------------------------------
  // Derived convenience getters
  // ------------------------------------------------------------------

  /// Whether it's a total eclipse
  bool get isTotal => magnitude >= 1.0;

  /// Whether it's a partial eclipse
  bool get isPartial => magnitude > 0.0 && magnitude < 1.0;

  /// Whether it's penumbral-only
  bool get isPenumbralOnly => magnitude <= 0.0 && (penumbralMagnitude ?? 0) > 0;

  /// The eclipse start visible from the observer's location.
  ///
  /// For lunar eclipses: the later of [partialStartTime] and [moonrise].
  /// This matches the "Lunar Eclipse Starts (With Moonrise)" field
  /// shown on astrology sites.
  DateTime? get localStartTime {
    final globalStart = partialStartTime ?? penumbralStartTime ?? startTime;
    if (globalStart == null) return null;
    if (moonrise == null) return globalStart;
    return moonrise!.isAfter(globalStart) ? moonrise : globalStart;
  }

  /// The eclipse end visible from the observer's location.
  ///
  /// The earlier of [partialEndTime] and [moonset] (or global end if Moon
  /// stays above the horizon throughout).
  DateTime? get localEndTime {
    final globalEnd = partialEndTime ?? penumbralEndTime ?? endTime;
    if (globalEnd == null) return null;
    if (moonset == null) return globalEnd;
    return moonset!.isBefore(globalEnd) ? moonset : globalEnd;
  }

  /// Duration of the eclipse as visible from the observer's location.
  Duration? get localDuration {
    final s = localStartTime;
    final e = localEndTime;
    if (s == null || e == null) return null;
    final d = e.difference(s);
    return d.isNegative ? Duration.zero : d;
  }

  // ------------------------------------------------------------------
  // Sutak (religious fast / abstinence period)
  // ------------------------------------------------------------------

  bool get _isSolar =>
      eclipseType == EclipseType.solar ||
      eclipseType == EclipseType.solarTotal ||
      eclipseType == EclipseType.solarPartial ||
      eclipseType == EclipseType.solarAnnular;

  /// Sutak for healthy adults.
  ///
  /// Computed as 9 hours (3 Prahars) before the eclipse becomes visible at
  /// the observer's location:
  ///  - Uses [localStartTime] (moonrise if after U1) as the anchor.
  ///  - Falls back to the global umbral start (U1) when no moon-rise data.
  /// For Solar Eclipse: 12 hours (4 Prahars) before U1.
  DateTime? get sutakStartTime {
    // Use local visibility start if available (accounts for moonrise after U1)
    final anchor = localStartTime ?? partialStartTime ?? startTime;
    if (anchor == null) return null;
    return anchor.subtract(Duration(hours: _isSolar ? 12 : 9));
  }

  /// Sutak for children, elderly, and the sick.
  ///
  /// 3 hours (1 Prahar) before the eclipse becomes visible at the observer's
  /// location ([localStartTime]), falling back to global U1.
  DateTime? get sutakForSensitive {
    final anchor = localStartTime ?? partialStartTime ?? startTime;
    if (anchor == null) return null;
    return anchor.subtract(const Duration(hours: 3));
  }

  /// Sutak ends when the umbral phase ends (U4) - same as [partialEndTime].
  DateTime? get sutakEndTime => partialEndTime ?? endTime;
}
