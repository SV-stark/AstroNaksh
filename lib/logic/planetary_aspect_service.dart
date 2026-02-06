import 'package:flutter/material.dart';
import 'package:jyotish/jyotish.dart' as j;

/// Planetary Aspect Service
/// Calculates and provides planetary aspects (Drishti) using jyotish library
class PlanetaryAspectService {
  /// Calculate all planetary aspects for a natal chart
  /// Uses manual calculation based on Vedic astrology principles
  static List<PlanetaryAspect> calculateAspects(j.VedicChart chart) {
    final List<PlanetaryAspect> aspects = [];
    final planets = chart.planets.entries.toList();

    // Standard aspects (applicable to all planets)
    // - Conjunction: 0°
    // - Sextile: 60° (3rd and 11th houses)
    // - Square: 90° (4th and 10th houses)
    // - Trine: 120° (5th and 9th houses)
    // - Opposition: 180° (7th house)

    for (int i = 0; i < planets.length; i++) {
      for (int j = i + 1; j < planets.length; j++) {
        final planet1 = planets[i];
        final planet2 = planets[j];

        final long1 = planet1.value.position.longitude;
        final long2 = planet2.value.position.longitude;

        // Calculate angular difference
        double diff = (long2 - long1).abs();
        if (diff > 180) diff = 360 - diff;

        // Check for aspects with orb
        final aspect = _getAspectType(diff, planet1.key, planet2.key);
        if (aspect != null) {
          aspects.add(PlanetaryAspect(
            aspectingPlanet: planet1.key,
            aspectedPlanet: planet2.key,
            type: aspect,
            orb: (diff - _getAspectAngle(aspect)).abs(),
            isApplying: true, // Simplified
          ));
        }
      }
    }

    return aspects;
  }

  /// Get aspect type based on angular difference
  static AspectType? _getAspectType(double diff, j.Planet p1, j.Planet p2) {
    const orb = 8.0; // Standard orb

    // Conjunction - 0°
    if (diff <= orb) {
      return AspectType.conjunction;
    }

    // Sextile - 60° (3rd/11th aspect)
    if ((diff - 60).abs() <= orb) {
      return AspectType.sextile;
    }

    // Square - 90° (4th/10th aspect)
    if ((diff - 90).abs() <= orb) {
      return AspectType.square;
    }

    // Trine - 120° (5th/9th aspect)
    if ((diff - 120).abs() <= orb) {
      return AspectType.trine;
    }

    // Opposition - 180° (7th aspect)
    if ((diff - 180).abs() <= orb) {
      return AspectType.opposition;
    }

    // Special aspects
    // Mars aspects 4th, 7th, 8th
    if (p1 == j.Planet.mars || p2 == j.Planet.mars) {
      if ((diff - 120).abs() <= orb || (diff - 180).abs() <= orb || (diff - 210).abs() <= 8) {
        return AspectType.square;
      }
    }

    // Jupiter aspects 5th, 7th, 9th
    if (p1 == j.Planet.jupiter || p2 == j.Planet.jupiter) {
      if ((diff - 120).abs() <= orb || (diff - 180).abs() <= orb) {
        return AspectType.trine;
      }
    }

    // Saturn aspects 3rd, 7th, 10th
    if (p1 == j.Planet.saturn || p2 == j.Planet.saturn) {
      if ((diff - 60).abs() <= orb || (diff - 180).abs() <= orb || (diff - 270).abs() <= 8) {
        return AspectType.square;
      }
    }

    return null;
  }

  /// Get ideal angle for aspect type
  static double _getAspectAngle(AspectType type) {
    switch (type) {
      case AspectType.conjunction:
        return 0;
      case AspectType.sextile:
        return 60;
      case AspectType.square:
        return 90;
      case AspectType.trine:
        return 120;
      case AspectType.opposition:
        return 180;
    }
  }

  /// Get color for aspect type
  static Color getAspectColor(AspectType type, {double opacity = 1.0}) {
    switch (type) {
      case AspectType.conjunction:
        return const Color(0xFF9C27B0).withAlpha((255 * opacity).round()); // Purple
      case AspectType.sextile:
        return const Color(0xFF2196F3).withAlpha((255 * opacity).round()); // Blue
      case AspectType.square:
        return const Color(0xFFF44336).withAlpha((255 * opacity).round()); // Red
      case AspectType.trine:
        return const Color(0xFF4CAF50).withAlpha((255 * opacity).round()); // Green
      case AspectType.opposition:
        return const Color(0xFFFF9800).withAlpha((255 * opacity).round()); // Orange
    }
  }

  /// Get aspect name
  static String getAspectName(AspectType type) {
    switch (type) {
      case AspectType.conjunction:
        return 'Conjunction (0°)';
      case AspectType.sextile:
        return 'Sextile (60°)';
      case AspectType.square:
        return 'Square (90°)';
      case AspectType.trine:
        return 'Trine (120°)';
      case AspectType.opposition:
        return 'Opposition (180°)';
    }
  }
}

/// Planetary Aspect Model
class PlanetaryAspect {
  final j.Planet aspectingPlanet;
  final j.Planet aspectedPlanet;
  final AspectType type;
  final double orb;
  final bool isApplying;

  PlanetaryAspect({
    required this.aspectingPlanet,
    required this.aspectedPlanet,
    required this.type,
    required this.orb,
    required this.isApplying,
  });

  @override
  String toString() {
    return '${aspectingPlanet.name} ${type.symbol} ${aspectedPlanet.name} (${orb.toStringAsFixed(1)}°)';
  }
}

/// Aspect Types
enum AspectType {
  conjunction,
  sextile,
  square,
  trine,
  opposition,
}

/// Extension to get symbol for aspect type
extension AspectTypeSymbol on AspectType {
  String get symbol {
    switch (this) {
      case AspectType.conjunction:
        return '☌';
      case AspectType.sextile:
        return '⚹';
      case AspectType.square:
        return '□';
      case AspectType.trine:
        return '△';
      case AspectType.opposition:
        return '☍';
    }
  }
}
