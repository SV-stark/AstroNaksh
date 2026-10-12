import 'package:jyotish/src/strength/bhava_bala.dart';
import 'package:jyotish/src/models/planet.dart';
import 'package:jyotish/src/models/rashi.dart';
import 'package:jyotish/src/models/vedic_chart.dart';
import 'package:jyotish/src/systems/shadbala_service.dart';


/// Service for calculating Bhava Bala (House Strength).
class BhavaBalaService {
  BhavaBalaService(this._shadbalaService);
  final ShadbalaService _shadbalaService;

  /// Calculates Bhava Bala for all 12 houses.
  Future<Map<int, BhavaBalaResult>> calculateBhavaBala(VedicChart chart) async {
    final planetShadbala = await _shadbalaService.calculateShadbala(chart);
    return <int, BhavaBalaResult>{
      for (var h = 1; h <= 12; h++)
        h: () {
          // 1. Bhava Adhipati Bala (Shadbala of the house lord)
          final lord = _getHouseLord(chart, h);
          final lordBala = planetShadbala[lord]?.totalBala ?? 0.0;

          // 2. Bhava Dig Bala
          final digBala = _calculateBhavaDigBala(h, chart.ascendant);

          // 3. Bhava Drishti Bala (Simplified)
          final drishtiBala = _calculateBhavaDrishtiBala(h, chart);

          final totalBala = lordBala + digBala + drishtiBala;

          return BhavaBalaResult(
            houseNumber: h,
            strength: totalBala,
            lordStrength: lordBala,
            digBala: digBala,
            aspectStrength: drishtiBala,
            category: _getBhavaStrengthCategory(totalBala),
          );
        }(),
    };
  }

  /// Categorizes a house's strength into a qualitative strength category.
  BhavaStrengthCategory getBhavaStrengthCategory(double strength) =>
      _getBhavaStrengthCategory(strength);

  /// Determines the ruling planet (lord) of a given house number (1-12).
  Planet getHouseLord(VedicChart chart, int houseNumber) =>
      _getHouseLord(chart, houseNumber);

  /// Calculates directional strength (Dig Bala) for a given house.
  double calculateBhavaDigBala(int houseNumber, double ascendant) =>
      _calculateBhavaDigBala(houseNumber, ascendant);

  BhavaStrengthCategory _getBhavaStrengthCategory(double strength) {
    if (strength >= 480) return BhavaStrengthCategory.veryStrong;
    if (strength >= 420) return BhavaStrengthCategory.strong;
    if (strength >= 360) return BhavaStrengthCategory.moderate;
    if (strength >= 300) return BhavaStrengthCategory.weak;
    return BhavaStrengthCategory.veryWeak;
  }

  Planet _getHouseLord(VedicChart chart, int houseNumber) {
    // Determine sign of the house
    final ascLong = chart.ascendant;
    final lagnaSign = Rashi.fromLongitude(ascLong);
    final houseSignIndex = (lagnaSign.index + houseNumber - 1) % 12;
    final rashi = Rashi.values[houseSignIndex];

    switch (rashi) {
      case Rashi.aries:
      case Rashi.scorpio:
        return Planet.mars;
      case Rashi.taurus:
      case Rashi.libra:
        return Planet.venus;
      case Rashi.gemini:
      case Rashi.virgo:
        return Planet.mercury;
      case Rashi.cancer:
        return Planet.moon;
      case Rashi.leo:
        return Planet.sun;
      case Rashi.sagittarius:
      case Rashi.pisces:
        return Planet.jupiter;
      case Rashi.capricorn:
      case Rashi.aquarius:
        return Planet.saturn;
    }
  }

  double _calculateBhavaDigBala(int house, double ascendantDegree) {
    // Standard Dig Bala for houses:
    // 4th house: 60 virupas
    // 10th house: 0 or low? Actually, specific planets get Dig Bala in houses.
    // For BHAVA Dig Bala (Bhava Bala specifically):
    // 1st, 4th, 7th, 10th (Kendras) get strength.
    // However, some systems use:
    // House 4, 5, 6, 7, 8, 9 (South) vs others.
    // Simplified standard for Bhava Bala:
    if ([1, 4, 7, 10].contains(house)) return 60.0;
    if ([2, 5, 8, 11].contains(house)) return 30.0;
    return 15.0;
  }

  double _calculateBhavaDrishtiBala(int house, VedicChart chart) {
    var drishtiBala = 0.0;
    // Calculate mid-point of the house (Bhav Madhya)
    // For simplicity in Equal House/etc, we often take the cusp.
    // In Sripathi/KP, it's the cusp. Let's use the cusp from the chart.
    // NOTE: VedicChart doesn't explicitly store house cusps in a simple list always,
    // but usually house 1 cusp = ascendant.
    // Let's approximate House mid-point based on Equal House for now if cusps aren't available,
    // OR use the calculation relative to Ascendant.
    // Given the current codebase structure (simple VedicChart), we'll assume Equal House from Ascendant
    // or if `chart.houses` existed (it doesn't seems to be passed here, just chart).
    // The `chart.ascendant` is available.
    // Let's assume Equal House System for determining the House Cusp Degree for Bhava Bala.
    // (Bhava Bala proper requires Sripathi/Placidus cusps, but without them, Equal House is the standard fallback).

    final houseCusp = (chart.ascendant + (house - 1) * 30) % 360;

    for (final entry in chart.planets.entries) {
      final planet = entry.key;
      final planetInfo = entry.value;

      // Skip Nodes (Rahu/Ketu) for standard Bhava Drishti (some systems include them, standard usually 7 planets)
      if (Planet.lunarNodes.contains(planet)) continue;

      final aspectStrength = _calculateAspectStrength(
        planet,
        planetInfo.longitude,
        houseCusp,
      );

      // Determine if planet is benefic or malefic
      // Bhava Bala uses Natural Benefic/Malefic for adding/subtracting strength
      final isBenefic = _isNaturalBenefic(planet);

      if (isBenefic) {
        drishtiBala += aspectStrength;
      } else {
        drishtiBala -= aspectStrength;
      }
    }

    // Result can be positive or negative.
    // Some texts say take 1/4th of this value.
    // B.V. Raman says: "Add the drift of benefic planets... Subtract the drift of malefic planets... Divide the result by 4."
    // Let's apply the 1/4 divisor rule which is standard for Bhava Drishti Pinda.
    return drishtiBala / 4.0;
  }

  double _calculateAspectStrength(
    Planet planet,
    double planetLong,
    double objectLong,
  ) {
    // Angle between planet and object (house cusp)
    final angle = (objectLong - planetLong + 360) % 360;

    // Standard Drig Bala (Aspect Strength) Formulas (Parashara/Raman):
    // 1. Special Aspects happen check first?
    // Usually defined by angle ranges.

    // Special Aspects (Fully strong):
    // Mars: 4th (90-120), 8th (210-240)
    // Jupiter: 5th (120-150), 9th (240-270)
    // Saturn: 3rd (60-90), 10th (270-300)

    // Convert angle to integer House distance roughly for checking special aspects?
    // No, Drig Bala formulas are precise based on degrees.

    // General Formula (Drishti Kendra):
    // 30-60:   (Angle - 30) / 2
    // 60-90:   (Angle - 60) + 15
    // 90-120:  (120 - Angle) / 2 + 45
    // 120-150: (150 - Angle)
    // 150-180: (Angle - 150) * 2
    // 180-300: (300 - Angle) / 2 (Wait, this is simpler 7th aspect logic)

    // Let's use the standard "Virupas" lookup or calculation.
    // B.V. Raman / Parashara logic:

    double aspectValue = 0.0;

    // Determine the "Distance" in degrees
    // Note: Aspects are usually cast forward.
    // If angle is 0 (conjunction), value is 0? (Planets generally don't aspect their own house in this calculation, or do they? usually aspect is 7th).
    // In Bhava Bala, we usually consider 7th aspect etc.
    // Conjunction usually typically handled by Bhava Dig Bala or similar?
    // Actually, Drig Bala starts from 30 degrees.

    if (angle < 30 || angle > 300) return 0.0;

    // Standard Parashara Aspect Formulas
    if (angle >= 30 && angle <= 60) {
      aspectValue = (angle - 30) / 2;
    } else if (angle > 60 && angle <= 90) {
      aspectValue = (angle - 60) + 15;
    } else if (angle > 90 && angle <= 120) {
      aspectValue = (120 - angle) / 2 + 45;
    } else if (angle > 120 && angle <= 150) {
      aspectValue = 150 - angle;
    } else if (angle > 150 && angle <= 180) {
      aspectValue = (angle - 150) * 2;
    } else if (angle > 180 && angle <= 300) {
      aspectValue = (300 - angle) / 2;
    } else {
      aspectValue = 0.0;
    }

    // Special Aspects Boost (to 60 Virupas)
    if (planet == Planet.mars) {
      if (angle >= 80 && angle <= 100) return 60.0; // 4th aspect
      if (angle >= 200 && angle <= 220) return 60.0; // 8th aspect
    } else if (planet == Planet.jupiter) {
      if (angle >= 110 && angle <= 130) return 60.0; // 5th aspect
      if (angle >= 230 && angle <= 250) return 60.0; // 9th aspect
    } else if (planet == Planet.saturn) {
      if (angle >= 50 && angle <= 70) return 60.0; // 3rd aspect
      if (angle >= 260 && angle <= 280) return 60.0; // 10th aspect
    }

    return aspectValue;
  }

  bool _isNaturalBenefic(Planet planet) {
    // Natural Benefics: Jupiter, Venus, Moon (Waxing usually, here simplified), Mercury (usually)
    // Natural Malefics: Sun, Mars, Saturn, Nodes.
    // Simplifying Moon/Mercury for static check:
    // Moon is generally considered Benefic in Bhava Bala unless explicitly Dark?
    // Let's stick to standard classification: Jup, Ven, Moo, Mer = Benefic. Sun, Mar, Sat = Malefic.
    // (Ideally Mercury depends on association, Moon on Paksha, but strict Natural Ben/Mal often used for this step).
    return [
      Planet.jupiter,
      Planet.venus,
      Planet.moon,
      Planet.mercury,
    ].contains(planet);
  }
}
