import 'package:flutter/material.dart';
import 'package:jyotish/jyotish.dart' as j;
import '../core/ephemeris_manager.dart';

/// Planetary Aspect Service
/// Calculates and provides planetary aspects (Drishti) using jyotish library
class PlanetaryAspectService {
  static j.AspectService? _aspectService;

  /// Calculate all planetary aspects for a natal chart
  /// Uses native jyotish library for accurate Vedic aspects
  static List<PlanetaryAspect> calculateAspects(j.VedicChart chart) {
    _aspectService ??= j.AspectService();

    final libraryAspects = _aspectService!.calculateAspects(
      chart.planets.map((e) => MapEntry(e.key, e.value.position)),
      config: j.AspectConfig.vedic,
    );

    return libraryAspects.map((aspect) {
      return PlanetaryAspect(
        aspectingPlanet: aspect.aspectingPlanet,
        aspectedPlanet: aspect.aspectedPlanet,
        type: _mapLibraryAspectType(aspect.type),
        orb: aspect.exactOrb,
        isApplying: aspect.isApplying,
      );
    }).toList();
  }

  /// Calculate aspects for a specific date/time and location
  static Future<List<PlanetaryAspect>> calculateAspectsForDateTime(
    DateTime dateTime,
    j.GeographicLocation location,
  ) async {
    await EphemerisManager.ensureEphemerisData();
    final jyotish = EphemerisManager.jyotish;

    final libraryAspects = await jyotish.getAspects(
      dateTime: dateTime,
      location: location,
    );

    return libraryAspects.map((aspect) {
      return PlanetaryAspect(
        aspectingPlanet: aspect.aspectingPlanet,
        aspectedPlanet: aspect.aspectedPlanet,
        type: _mapLibraryAspectType(aspect.type),
        orb: aspect.exactOrb,
        isApplying: aspect.isApplying,
      );
    }).toList();
  }

  /// Map library's AspectType to local AspectType
  static AspectType _mapLibraryAspectType(j.AspectType type) {
    switch (type) {
      case j.AspectType.conjunction:
        return AspectType.conjunction;
      case j.AspectType.opposition:
        return AspectType.opposition;
      case j.AspectType.trine5th:
      case j.AspectType.trine9th:
      case j.AspectType.jupiterSpecial5th:
      case j.AspectType.jupiterSpecial9th:
        return AspectType.trine;
      case j.AspectType.square4th:
      case j.AspectType.square10th:
      case j.AspectType.marsSpecial4th:
      case j.AspectType.marsSpecial8th:
      case j.AspectType.saturnSpecial3rd:
      case j.AspectType.saturnSpecial10th:
        return AspectType.square;
      case j.AspectType.sextile3rd:
      case j.AspectType.sextile11th:
        return AspectType.sextile;
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
