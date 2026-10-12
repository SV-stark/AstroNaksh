import 'package:jyotish/src/models/aspect.dart';
import 'package:jyotish/src/systems/jaimini.dart';
import 'package:jyotish/src/models/planet.dart';
import 'package:jyotish/src/astronomy/planet_position.dart';
import 'package:jyotish/src/models/vedic_chart.dart';
import 'package:jyotish/src/systems/jaimini_service.dart';

/// Service for calculating Vedic planetary aspects (Graha Drishti).
///
/// **Vedic (whole-sign) mode** [default for [AspectConfig.vedic]]:
/// Aspects are cast sign-to-sign  a planet in sign X aspects every planet
/// in the target sign regardless of exact degree separation. There is no orb
/// in this model, so strength carries the classical Drishti weight of the
/// aspect type (see [_wholeSignStrength]).
///
/// Aspect houses from aspecting planets sign:
/// - All planets aspect the 7th house (opposition sign)
/// - Mars also aspects the 4th and 8th houses
/// - Jupiter also aspects the 5th and 9th houses
/// - Saturn also aspects the 3rd and 10th houses
///
/// **Western (degree-based) mode** (configured via `AspectConfig`):
/// Standard degree+orb calculation, useful for KP or Western tropical use.
class AspectService {
  /// Returns Rashi Drishti (sign aspects) for the chart.
  ///
  /// Delegates to [JaiminiService] which implements the Jaimini sign-aspect rules:
  /// - Movable signs aspect all Fixed signs (except adjacent)
  /// - Fixed signs aspect all Movable signs (except adjacent)
  /// - Dual signs aspect all other Dual signs
  List<RashiDrishtiInfo> getRashiAspects(
    VedicChart chart, {
    bool activeOnly = true,
  }) {
    final jaiminiService = const JaiminiService();
    return activeOnly
        ? jaiminiService.calculateActiveRashiDrishti(chart)
        : jaiminiService.calculateRashiDrishti(chart);
  }

  /// Calculates all aspects between planetary positions.
  ///
  /// [positions] - Map of planets to their positions
  /// [config] - Configuration for aspect calculations
  ///
  /// Returns a list of all aspects found.
  List<AspectInfo> calculateAspects(
    Map<Planet, PlanetPosition> positions, {
    AspectConfig config = AspectConfig.vedic,
  }) {
    final aspects = <AspectInfo>[];
    final planets = positions.keys.toList();

    for (var i = 0; i < planets.length; i++) {
      for (var j = i + 1; j < planets.length; j++) {
        final planet1 = planets[i];
        final planet2 = planets[j];

        // Skip nodes if not configured
        if (!config.includeNodes &&
            (planet1 == Planet.meanNode ||
                planet1 == Planet.trueNode ||
                planet2 == Planet.meanNode ||
                planet2 == Planet.trueNode)) {
          continue;
        }

        final pos1 = positions[planet1]!;
        final pos2 = positions[planet2]!;

        // Check for aspects from planet1 to planet2
        final aspectsFrom1 = _getAspectsBetween(
          planet1,
          pos1,
          planet2,
          pos2,
          config,
        );
        aspects.addAll(aspectsFrom1);

        // Check for aspects from planet2 to planet1 (reverse)
        final aspectsFrom2 = _getAspectsBetween(
          planet2,
          pos2,
          planet1,
          pos1,
          config,
        );
        aspects.addAll(aspectsFrom2);
      }
    }

    // Remove duplicate aspects and filter by minimum strength.
    //
    // Conjunction and opposition are symmetric: A->B and B->A describe one
    // and the same event, so a single record is kept and both planets are
    // reported as casting and receiving it (see getAspectsCastBy). The Vishesh
    // aspects are directional - a Mars 4th aspect onto Jupiter is not the same
    // event as a Jupiter 9th aspect back onto Mars - so those are keyed by
    // direction and never collapsed.
    final seen = <String, AspectInfo>{};
    for (final aspect in aspects) {
      if (aspect.strength < config.minimumStrength) continue;

      final p1 = aspect.aspectingPlanet.index;
      final p2 = aspect.aspectedPlanet.index;
      final String key;
      if (_isSymmetricAspect(aspect.type)) {
        key = 'mutual-${p1 < p2 ? p1 : p2}-${p1 < p2 ? p2 : p1}-${aspect.type}';
      } else {
        key = 'directed-$p1-$p2-${aspect.type}';
      }

      final existing = seen[key];
      // Deterministic representative: for a mutual aspect prefer the direction
      // whose aspecting planet has the lower Planet index, so the result never
      // depends on the iteration order of [positions].
      if (existing == null ||
          (_isSymmetricAspect(aspect.type) &&
              p1 < existing.aspectingPlanet.index)) {
        seen[key] = aspect;
      }
    }

    final result = seen.values.toList()
      ..sort((a, b) {
        final byAspecting = a.aspectingPlanet.index.compareTo(
          b.aspectingPlanet.index,
        );
        if (byAspecting != 0) return byAspecting;
        final byAspected = a.aspectedPlanet.index.compareTo(
          b.aspectedPlanet.index,
        );
        if (byAspected != 0) return byAspected;
        return a.type.index.compareTo(b.type.index);
      });
    return result;
  }

  /// Whether [type] describes the same relation from either direction.
  ///
  /// Conjunction and opposition are mutual: two planets conjoin, or aspect each
  /// other by the 7th, independently of which is named first. The Vishesh
  /// aspects of Mars, Jupiter and Saturn are directional and are not mutual.
  static bool _isSymmetricAspect(AspectType type) =>
      type == AspectType.conjunction || type == AspectType.opposition;

  /// Gets aspects for a specific planet.
  ///
  /// [planet] - The planet to get aspects for
  /// [positions] - All planetary positions
  /// [config] - Configuration for aspect calculations
  ///
  /// Returns aspects where the planet is either aspecting or aspected.
  List<AspectInfo> getAspectsForPlanet(
    Planet planet,
    Map<Planet, PlanetPosition> positions, {
    AspectConfig config = AspectConfig.vedic,
  }) {
    final allAspects = calculateAspects(positions, config: config);
    return allAspects
        .where((a) => a.aspectingPlanet == planet || a.aspectedPlanet == planet)
        .toList();
  }

  /// Gets aspects cast by a specific planet.
  ///
  /// For directional aspects (the Vishesh aspects of Mars, Jupiter and Saturn)
  /// this returns only those where [planet] is the aspecting planet.
  ///
  /// Conjunction and opposition are mutual: [calculateAspects] stores one
  /// record per mutual pair, so those are returned for [planet] whether it is
  /// the stored aspecting or the stored aspected member of the pair. This
  /// matches the mutual nature of the relation - two planets in conjunction or
  /// in 7th aspect each stand in it.
  List<AspectInfo> getAspectsCastBy(
    Planet planet,
    Map<Planet, PlanetPosition> positions, {
    AspectConfig config = AspectConfig.vedic,
  }) {
    final allAspects = calculateAspects(positions, config: config);
    return allAspects
        .where(
          (a) =>
              a.aspectingPlanet == planet ||
              (_isSymmetricAspect(a.type) && a.aspectedPlanet == planet),
        )
        .toList();
  }

  /// Gets aspects received by a specific planet.
  ///
  /// The mirror image of [getAspectsCastBy]: directional aspects are returned
  /// only where [planet] is the aspected planet, while mutual aspects
  /// (conjunction and opposition) are returned for [planet] as either member
  /// of the stored pair.
  List<AspectInfo> getAspectsReceivedBy(
    Planet planet,
    Map<Planet, PlanetPosition> positions, {
    AspectConfig config = AspectConfig.vedic,
  }) {
    final allAspects = calculateAspects(positions, config: config);
    return allAspects
        .where(
          (a) =>
              a.aspectedPlanet == planet ||
              (_isSymmetricAspect(a.type) && a.aspectingPlanet == planet),
        )
        .toList();
  }

  /// Internal: Find aspects between two planets.
  List<AspectInfo> _getAspectsBetween(
    Planet planet1,
    PlanetPosition pos1,
    Planet planet2,
    PlanetPosition pos2,
    AspectConfig config,
  ) {
    final aspects = <AspectInfo>[];

    if (config.useWholeSignAspects) {
      //  WHOLE-SIGN VEDIC ASPECTS
      // Convert both planets to their sign index (0-11)
      final sign1 = (pos1.longitude / 30).floor() % 12;
      final sign2 = (pos2.longitude / 30).floor() % 12;
      // Forward distance from planet1s sign to planet2s sign
      final d = (sign2 - sign1 + 12) % 12;

      // Conjunction: same sign (d == 0)
      if (d == 0) {
        aspects.add(
          _createWholeSignAspect(
            planet1,
            pos1,
            planet2,
            pos2,
            AspectType.conjunction,
          ),
        );
      }

      // 7th house: all planets aspect the sign 6 signs ahead
      if (d == 6) {
        aspects.add(
          _createWholeSignAspect(
            planet1,
            pos1,
            planet2,
            pos2,
            AspectType.opposition,
          ),
        );
      }

      // Special aspects (only when configured)
      if (config.includeSpecialAspects) {
        // Mars: 4th (d==3) and 8th (d==7)
        if (planet1 == Planet.mars) {
          if (d == 3) {
            aspects.add(
              _createWholeSignAspect(
                planet1,
                pos1,
                planet2,
                pos2,
                AspectType.marsSpecial4th,
              ),
            );
          }
          if (d == 7) {
            aspects.add(
              _createWholeSignAspect(
                planet1,
                pos1,
                planet2,
                pos2,
                AspectType.marsSpecial8th,
              ),
            );
          }
        }
        // Jupiter: 5th (d==4) and 9th (d==8)
        if (planet1 == Planet.jupiter) {
          if (d == 4) {
            aspects.add(
              _createWholeSignAspect(
                planet1,
                pos1,
                planet2,
                pos2,
                AspectType.jupiterSpecial5th,
              ),
            );
          }
          if (d == 8) {
            aspects.add(
              _createWholeSignAspect(
                planet1,
                pos1,
                planet2,
                pos2,
                AspectType.jupiterSpecial9th,
              ),
            );
          }
        }
        // Saturn: 3rd (d==2) and 10th (d==9)
        if (planet1 == Planet.saturn) {
          if (d == 2) {
            aspects.add(
              _createWholeSignAspect(
                planet1,
                pos1,
                planet2,
                pos2,
                AspectType.saturnSpecial3rd,
              ),
            );
          }
          if (d == 9) {
            aspects.add(
              _createWholeSignAspect(
                planet1,
                pos1,
                planet2,
                pos2,
                AspectType.saturnSpecial10th,
              ),
            );
          }
        }
      }
    } else {
      //  DEGREE-BASED WESTERN ASPECTS (KP / Western tropical)
      final angularDiff = _calculateAngularDifference(
        pos1.longitude,
        pos2.longitude,
      );

      // Conjunction
      final conjunctionOrb = _getOrb(AspectType.conjunction, config);
      if (angularDiff.abs() <= conjunctionOrb) {
        aspects.add(
          _createAspect(
            planet1,
            pos1,
            planet2,
            pos2,
            AspectType.conjunction,
            angularDiff,
            config,
          ),
        );
      }

      // 7th house aspect (opposition)
      final oppositionOrb = _getOrb(AspectType.opposition, config);
      final oppDiff = (angularDiff - 180).abs();
      if (oppDiff <= oppositionOrb) {
        aspects.add(
          _createAspect(
            planet1,
            pos1,
            planet2,
            pos2,
            AspectType.opposition,
            angularDiff - 180,
            config,
          ),
        );
      }

      // Special aspects
      if (config.includeSpecialAspects) {
        aspects.addAll(
          _checkSpecialAspects(
            planet1,
            pos1,
            planet2,
            pos2,
            angularDiff,
            config,
          ),
        );
      }
    }

    return aspects;
  }

  /// Internal: Check for special planetary aspects (Mars, Jupiter, Saturn).
  List<AspectInfo> _checkSpecialAspects(
    Planet planet1,
    PlanetPosition pos1,
    Planet planet2,
    PlanetPosition pos2,
    double angularDiff,
    AspectConfig config,
  ) {
    final aspects = <AspectInfo>[];

    // Mars special aspects: 4th (90) and 8th (210)
    if (planet1 == Planet.mars) {
      final orb4th = _getOrb(AspectType.marsSpecial4th, config);
      final orb8th = _getOrb(AspectType.marsSpecial8th, config);

      if ((angularDiff - 90).abs() <= orb4th) {
        aspects.add(
          _createAspect(
            planet1,
            pos1,
            planet2,
            pos2,
            AspectType.marsSpecial4th,
            angularDiff - 90,
            config,
          ),
        );
      }
      if ((angularDiff - 210).abs() <= orb8th) {
        aspects.add(
          _createAspect(
            planet1,
            pos1,
            planet2,
            pos2,
            AspectType.marsSpecial8th,
            angularDiff - 210,
            config,
          ),
        );
      }
    }

    // Jupiter special aspects: 5th (120) and 9th (240)
    if (planet1 == Planet.jupiter) {
      final orb5th = _getOrb(AspectType.jupiterSpecial5th, config);
      final orb9th = _getOrb(AspectType.jupiterSpecial9th, config);

      if ((angularDiff - 120).abs() <= orb5th) {
        aspects.add(
          _createAspect(
            planet1,
            pos1,
            planet2,
            pos2,
            AspectType.jupiterSpecial5th,
            angularDiff - 120,
            config,
          ),
        );
      }
      if ((angularDiff - 240).abs() <= orb9th) {
        aspects.add(
          _createAspect(
            planet1,
            pos1,
            planet2,
            pos2,
            AspectType.jupiterSpecial9th,
            angularDiff - 240,
            config,
          ),
        );
      }
    }

    // Saturn special aspects: 3rd (60) and 10th (270)
    if (planet1 == Planet.saturn) {
      final orb3rd = _getOrb(AspectType.saturnSpecial3rd, config);
      final orb10th = _getOrb(AspectType.saturnSpecial10th, config);

      if ((angularDiff - 60).abs() <= orb3rd) {
        aspects.add(
          _createAspect(
            planet1,
            pos1,
            planet2,
            pos2,
            AspectType.saturnSpecial3rd,
            angularDiff - 60,
            config,
          ),
        );
      }
      if ((angularDiff - 270).abs() <= orb10th) {
        aspects.add(
          _createAspect(
            planet1,
            pos1,
            planet2,
            pos2,
            AspectType.saturnSpecial10th,
            angularDiff - 270,
            config,
          ),
        );
      }
    }

    return aspects;
  }

  /// Internal: Angular difference from [lon1] forward to [lon2], in [0, 360).
  ///
  /// Note the range is one-sided: a gate written as `angularDiff.abs() <= orb`
  /// only fires near 0, not near 360. That is safe here because
  /// `calculateAspects` evaluates every planet pair in both directions, so the
  /// reverse call supplies the near-360 half. Every other gate is centred on an
  /// angle strictly inside (0, 360) and is therefore wrap-safe as written.
  double _calculateAngularDifference(double lon1, double lon2) {
    var diff = (lon2 - lon1) % 360;
    if (diff < 0) diff += 360;
    return diff;
  }

  /// Internal: Get orb for an aspect type.
  double _getOrb(AspectType type, AspectConfig config) {
    return config.customOrbs?[type] ?? type.defaultOrb;
  }

  /// Orb reported for a whole-sign (Drishti) aspect, which has no orb.
  ///
  /// A whole-sign aspect is exact by construction - it relates two SIGNS, so
  /// there is no degree at which it becomes "exact" or "tight". [AspectInfo]
  /// exposes no nullable orb and no whole-sign flag, so the full 30-degree sign
  /// width is reported: the relation holds across an entire sign, and 30.0 sits
  /// outside both the exact (< 1.0) and tight (< 3.0) thresholds so neither flag
  /// reads as accidentally true.
  static const double wholeSignOrb = 30.0;

  /// Classical Drishti weight of each aspect type in whole-sign mode.
  ///
  /// Whole-sign aspects have no orb, so `strength` carries the classical
  /// relative weight of the aspect rather than a measure of proximity. The
  /// gradation follows the classical aspect classes: conjunction, the 7th
  /// opposition and the trine (trikona) are the full-strength aspects, the
  /// kendra squares are strong, and the upachaya sextiles are mild. The Vishesh
  /// aspects of Mars, Jupiter and Saturn inherit the weight of the pada they
  /// fall on, so Jupiter's 5th and 9th are full while Saturn's 3rd is mild.
  static const Map<AspectType, double> _wholeSignStrength = {
    AspectType.conjunction: 1.0,
    AspectType.opposition: 1.0,
    AspectType.trine5th: 1.0,
    AspectType.trine9th: 1.0,
    AspectType.jupiterSpecial5th: 1.0,
    AspectType.jupiterSpecial9th: 1.0,
    AspectType.square4th: 0.75,
    AspectType.square10th: 0.75,
    AspectType.marsSpecial4th: 0.75,
    AspectType.marsSpecial8th: 0.75,
    AspectType.saturnSpecial10th: 0.75,
    AspectType.sextile3rd: 0.5,
    AspectType.sextile11th: 0.5,
    AspectType.saturnSpecial3rd: 0.5,
  };

  /// Internal: Create a whole-sign aspect.
  ///
  /// A whole-sign relation has no orb and no applying/separating phase, so
  /// [AspectInfo]'s orb-based readings are not meaningful for it. See
  /// [wholeSignOrb] and [_wholeSignStrength] for the values passed and why.
  AspectInfo _createWholeSignAspect(
    Planet planet1,
    PlanetPosition pos1,
    Planet planet2,
    PlanetPosition pos2,
    AspectType type,
  ) {
    return AspectInfo(
      aspectingPlanet: planet1,
      aspectedPlanet: planet2,
      type: type,
      exactOrb: wholeSignOrb,
      isApplying: false, // not meaningful for whole-sign
      strength: _wholeSignStrength[type] ?? 1.0,
      aspectingLongitude: pos1.longitude,
      aspectedLongitude: pos2.longitude,
    );
  }

  /// Internal: Create an AspectInfo.
  AspectInfo _createAspect(
    Planet planet1,
    PlanetPosition pos1,
    Planet planet2,
    PlanetPosition pos2,
    AspectType type,
    double orb,
    AspectConfig config,
  ) {
    // Determine if applying or separating based on speeds
    final speedDiff = pos1.longitudeSpeed - pos2.longitudeSpeed;
    final isApplying = (orb > 0 && speedDiff > 0) || (orb < 0 && speedDiff < 0);

    // Calculate strength (1.0 at exact, decreasing with orb)
    final maxOrb = _getOrb(type, config);
    final strength = 1.0 - (orb.abs() / maxOrb).clamp(0.0, 1.0);

    return AspectInfo(
      aspectingPlanet: planet1,
      aspectedPlanet: planet2,
      type: type,
      exactOrb: orb.abs(),
      isApplying: isApplying,
      strength: strength,
      aspectingLongitude: pos1.longitude,
      aspectedLongitude: pos2.longitude,
    );
  }

  /// Gets planets aspecting a specific house/sign.
  ///
  /// [houseSignIndex] - The sign index (0-11) to check
  /// [positions] - All planetary positions
  /// [useWholeSign] - Use whole-sign model (default: true, Vedic standard)
  ///
  /// Returns list of planets that aspect the sign.
  List<Planet> getPlanetsAspectingSign(
    int houseSignIndex,
    Map<Planet, PlanetPosition> positions, {
    bool useWholeSign = true,
  }) {
    return positions.entries
        .where((entry) {
          final planet = entry.key;
          final pos = entry.value;

          if (useWholeSign) {
            final planetSign = (pos.longitude / 30).floor() % 12;
            final d = (houseSignIndex - planetSign + 12) % 12;

            // 7th house aspect (d == 6 represents opposite sign, 7th house away)
            if (d == 6) return true;
            if (planet == Planet.mars && (d == 3 || d == 7)) return true;
            if (planet == Planet.jupiter && (d == 4 || d == 8)) return true;
            if (planet == Planet.saturn && (d == 2 || d == 9)) return true;
            return false;
          } else {
            final targetMidpoint = (houseSignIndex * 30) + 15;
            final angularDiff = _calculateAngularDifference(
              pos.longitude,
              targetMidpoint.toDouble(),
            );

            if ((angularDiff - 180).abs() <= 15) {
              return true;
            }
            if (planet == Planet.mars &&
                ((angularDiff - 90).abs() <= 15 ||
                    (angularDiff - 210).abs() <= 15)) {
              return true;
            }
            if (planet == Planet.jupiter &&
                ((angularDiff - 120).abs() <= 15 ||
                    (angularDiff - 240).abs() <= 15)) {
              return true;
            }
            if (planet == Planet.saturn &&
                ((angularDiff - 60).abs() <= 15 ||
                    (angularDiff - 270).abs() <= 15)) {
              return true;
            }
            return false;
          }
        })
        .map((e) => e.key)
        .toList();
  }
}
