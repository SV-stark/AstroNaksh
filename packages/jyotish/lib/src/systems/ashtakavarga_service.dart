import 'dart:typed_data';
import 'dart:math' as math;
import 'package:jyotish/src/systems/ashtakavarga.dart';
import 'package:jyotish/src/models/planet.dart';
import 'package:jyotish/src/models/vedic_chart.dart';
import 'package:jyotish/src/models/prastara_result.dart';

/// Service for calculating Ashtakavarga (eightfold division) system.
///
/// Ashtakavarga is a system that evaluates planetary strength by counting
/// benefic points (bindus) contributed by each of the seven planets plus
/// the ascendant in each sign of the zodiac.
class AshtakavargaService {
  /// The 7 grahas in mask-bit order (bit 0 .. bit 6).
  static const List<Planet> _contributorPlanets = [
    Planet.sun,
    Planet.moon,
    Planet.mars,
    Planet.mercury,
    Planet.jupiter,
    Planet.venus,
    Planet.saturn,
  ];

  /// Number of graha bits in a contributions mask (bits 0..6).
  static const int _contributorCount = 7;

  /// Bit position of the Ascendant (Lagna) inside a contributions mask.
  ///
  /// Parashara's 8th contributor is the Ascendant, not Rahu or Ketu.
  static const int _ascendantBit = 1 << 7;

  /// Calculates the Prastara Ashtakavarga 96-cell grid for a planet.
  PrastaraResult calculatePrastaraAshtakavarga(
    VedicChart chart,
    Planet planet,
  ) {
    final ashtakavarga = calculateAshtakavarga(chart);
    final bav = ashtakavarga.bhinnashtakavarga[planet];
    if (bav == null) {
      throw ArgumentError('Planet $planet not found in traditional planets');
    }

    final grid = Uint8List(8 * 12);
    for (var sign = 0; sign < 12; sign++) {
      final mask = bav.contributions[sign];
      for (var point = 0; point < 8; point++) {
        grid[point * 12 + sign] = (mask & (1 << point) != 0) ? 1 : 0;
      }
    }

    return PrastaraResult(planet: planet, grid: grid);
  }

  /// Calculates the complete Ashtakavarga for a birth chart.
  ///
  /// [natalChart] - The Vedic birth chart
  ///
  /// Returns an [Ashtakavarga] with Bhinnashtakavarga for each of the 7 grahas,
  /// the Ascendant's own 8th Prastara row, and the Sarvashtakavarga totals.
  Ashtakavarga calculateAshtakavarga(VedicChart natalChart) {
    final bhinnashtakavarga = <Planet, Bhinnashtakavarga>{
      for (final planet in _contributorPlanets)
        planet: _calculateBhinnashtakavarga(planet, natalChart),
    };

    return _assemble(
      natalChart,
      bhinnashtakavarga,
      _calculateLagnaBhinnashtakavarga(bhinnashtakavarga),
    );
  }

  /// Builds an [Ashtakavarga] from an already-computed map of graha BAVs.
  ///
  /// Only the 7 graha entries are summed into the Sarvashtakavarga, so the
  /// classical 337 total is preserved regardless of [lagnaBav].
  Ashtakavarga _assemble(
    VedicChart natalChart,
    Map<Planet, Bhinnashtakavarga> bhinnashtakavarga,
    Bhinnashtakavarga? lagnaBav,
  ) {
    return Ashtakavarga(
      natalChart: natalChart,
      bhinnashtakavarga: bhinnashtakavarga,
      sarvashtakavarga: _calculateSarvashtakavarga(bhinnashtakavarga),
      samudayaAshtakavarga: _calculateSamudayaAshtakavarga(bhinnashtakavarga),
      lagnaBhinnashtakavarga: lagnaBav,
    );
  }

  /// Calculates the Ascendant's own Bhinnashtakavarga (the 8th Prastara row).
  ///
  /// Classical Prastara is an 8x12 grid of bindu/rekha cells whose rows are the
  /// 7 grahas plus the Ascendant. A Prastara row is binary per sign, so the
  /// Ascendant row is too: `bindus[sign]` is 1 when the Ascendant is given a
  /// bindu in that sign and 0 otherwise, and `contributions[sign]` carries only
  /// bit 7 (the Ascendant) when it is.
  ///
  /// A sign qualifies when *any* of the 7 graha rows credits the Ascendant
  /// there — i.e. via [Bhinnashtakavarga.doesAscendantContribute], the same
  /// predicate that populates bit 7 of every graha row. Which grahas those are
  /// is not lost: it is already readable from bit 7 of each graha row's mask.
  ///
  /// The invariant `popcount(contributions[sign]) == bindus[sign]` therefore
  /// holds here too, and [Bhinnashtakavarga.doesAscendantContribute] returns
  /// exactly `bindus[sign] > 0` for this row.
  ///
  /// This row is **not** part of the Sarvashtakavarga sum — the Ascendant is
  /// already counted once via bit 7 of each graha's mask.
  Bhinnashtakavarga _calculateLagnaBhinnashtakavarga(
    Map<Planet, Bhinnashtakavarga> bhinnashtakavarga,
  ) {
    final bindus = List<int>.filled(12, 0);
    final contributions = List<int>.filled(12, 0);

    for (var signIndex = 0; signIndex < 12; signIndex++) {
      var ascendantContributed = false;
      for (var i = 0; i < _contributorCount; i++) {
        final bav = bhinnashtakavarga[_contributorPlanets[i]];
        if (bav == null) continue;
        if (bav.doesAscendantContribute(signIndex)) {
          ascendantContributed = true;
          break;
        }
      }
      bindus[signIndex] = ascendantContributed ? 1 : 0;
      contributions[signIndex] = ascendantContributed ? _ascendantBit : 0;
    }

    return Bhinnashtakavarga(
      bindus: bindus,
      contributions: contributions,
    );
  }

  /// Counts the set bits of a contributions mask.
  static int _popCount(int mask) {
    var remaining = mask;
    var count = 0;
    while (remaining != 0) {
      remaining &= remaining - 1;
      count++;
    }
    return count;
  }

  /// Calculates Bhinnashtakavarga for a single planet.
  ///
  /// [subjectPlanet] - The planet for which to calculate Ashtakavarga
  /// [natalChart] - The birth chart containing planetary positions
  Bhinnashtakavarga _calculateBhinnashtakavarga(
    Planet subjectPlanet,
    VedicChart natalChart,
  ) {
    final table = AshtakavargaTables.getTableForPlanet(subjectPlanet);
    final bindus = List<int>.filled(12, 0);
    final contributions = List<int>.filled(12, 0);

    // Get the sign where the subject planet is placed
    final subjectInfo = natalChart.planets[subjectPlanet];
    if (subjectInfo == null) {
      throw ArgumentError('Planet $subjectPlanet not found in chart');
    }

    // Calculate contributions from each contributing planet
    // Calculate contributions from each planet (Sun..Saturn, mask bits 0..6)
    const contributingPlanets = _contributorPlanets;

    for (var signIndex = 0; signIndex < 12; signIndex++) {
      var binduCount = 0;
      var contributionMask = 0;

      // Check contributions from each planet
      for (var i = 0; i < contributingPlanets.length; i++) {
        final contributingPlanet = contributingPlanets[i];

        // Get the sign where the contributing planet is placed
        final planetInfo = natalChart.planets[contributingPlanet];
        if (planetInfo == null) continue;
        final planetSign =
            (planetInfo.position.longitude / 30).floor() % 12;

        // Calculate relative sign: where the current signIndex is relative to where the contributing planet sits
        // If contributing planet is in sign X, we check the table to see which signs from X get bindus
        // For signIndex, we calculate: signIndex - planetSign (mod 12)
        final relativeSign = (signIndex - planetSign + 12) % 12;

        // Check if this planet contributes bindu in this sign
        // table[relativeSign][i] tells us if planet i contributes to a sign that is 'relativeSign' away from it
        if (table[relativeSign][i] == 1) {
          binduCount++;
          contributionMask |= 1 << i;
        }
      }

      // Also consider ascendant contribution
      final ascendantSign = (natalChart.houses.ascendant / 30).floor() % 12;
      // Check if ascendant contributes to this signIndex
      final relativeAscendant = (signIndex - ascendantSign + 12) % 12;

      // Ascendant contribution varies by planet
      if (_doesAscendantContribute(subjectPlanet, relativeAscendant)) {
        binduCount++;
        contributionMask |= _ascendantBit; // bit 7 = Ascendant
      }

      bindus[signIndex] = binduCount;
      contributions[signIndex] = contributionMask;
    }

    return Bhinnashtakavarga(
      planet: subjectPlanet,
      bindus: bindus,
      contributions: contributions,
    );
  }

  /// Checks if ascendant contributes bindu for a specific planet in a relative sign.
  bool _doesAscendantContribute(Planet planet, int relativeSign) {
    // Classical BPHS Ascendant contribution rules (1-based houses converted to 0-based relative signs: house - 1)
    switch (planet) {
      case Planet.sun:
        // Houses 3, 4, 6, 10, 11, 12 (6 bindus)
        return [2, 3, 5, 9, 10, 11].contains(relativeSign);
      case Planet.moon:
        // Houses 3, 6, 10, 11 (4 bindus)
        return [2, 5, 9, 10].contains(relativeSign);
      case Planet.mars:
        // Houses 1, 3, 6, 10, 11 (5 bindus)
        return [0, 2, 5, 9, 10].contains(relativeSign);
      case Planet.mercury:
        // Houses 1, 2, 4, 6, 8, 10, 11 (7 bindus)
        return [0, 1, 3, 5, 7, 9, 10].contains(relativeSign);
      case Planet.jupiter:
        // Houses 1, 2, 4, 5, 6, 7, 9, 10, 11 (9 bindus)
        return [0, 1, 3, 4, 5, 6, 8, 9, 10].contains(relativeSign);
      case Planet.venus:
        // Houses 1, 2, 3, 4, 5, 8, 9, 11 (8 bindus)
        return [0, 1, 2, 3, 4, 7, 8, 10].contains(relativeSign);
      case Planet.saturn:
        // Houses 1, 3, 4, 6, 10, 11 (6 bindus)
        return [0, 2, 3, 5, 9, 10].contains(relativeSign);
      default:
        return false;
    }
  }

  /// Calculates Sarvashtakavarga from all Bhinnashtakavargas.
  Sarvashtakavarga _calculateSarvashtakavarga(
    Map<Planet, Bhinnashtakavarga> bhinnashtakavarga,
  ) {
    final totalBindus = List<int>.filled(12, 0);
    for (var i = 0; i < 12; i++) {
      totalBindus[i] = bhinnashtakavarga.values.fold<int>(
        0,
        (sum, bav) => sum + bav.bindus[i],
      );
    }
    return Sarvashtakavarga(bindus: totalBindus);
  }

  /// Calculates Samudaya Ashtakavarga (total for all planets).
  ///
  /// Samudaya is *by definition* the sum of every Bhinnashtakavarga, which is
  /// exactly what [_calculateSarvashtakavarga] computes, so it delegates rather
  /// than repeating the fold. Returns a copy so the two lists stay independent.
  List<int> _calculateSamudayaAshtakavarga(
    Map<Planet, Bhinnashtakavarga> bhinnashtakavarga,
  ) {
    return List<int>.from(
      _calculateSarvashtakavarga(bhinnashtakavarga).bindus,
    );
  }

  /// Analyzes transit favorability based on Ashtakavarga.
  ///
  /// [ashtakavarga] - The calculated Ashtakavarga
  /// [transitPlanet] - The planet in transit
  /// [transitSign] - The sign being transited (0-11)
  ///
  /// Returns a transit analysis result.
  AshtakavargaTransit analyzeTransit({
    required Ashtakavarga ashtakavarga,
    required Planet transitPlanet,
    required int transitSign,
    DateTime? transitDate,
  }) {
    // Get bindus for the transiting planet in that sign
    final planetBav = ashtakavarga.bhinnashtakavarga[transitPlanet];
    final bindus = planetBav?.getBindusForSign(transitSign) ?? 0;

    // Get total bindus in that sign
    final totalBindus = ashtakavarga.getTotalBindusForSign(transitSign);

    // More than 28 bindus is generally favorable
    final isFavorable = totalBindus > 28;

    // Calculate strength score (0-100)
    var strengthScore = bindus * 10; // Up to 80 for bindus
    if (isFavorable) strengthScore += 20;
    strengthScore = strengthScore.clamp(0, 100);

    return AshtakavargaTransit(
      transitDate: transitDate ?? DateTime.now(),
      transitPlanet: transitPlanet,
      transitSign: transitSign,
      sarvashtakavargaTotal: totalBindus,
      planetBindus: bindus,
      bindus: bindus,
      isFavorable: isFavorable,
      strengthScore: strengthScore,
    );
  }

  /// Gets favorable periods for a specific planet transit.
  ///
  /// Returns a list of sign indices where the planet has 4 or more bindus
  /// in its own Bhinnashtakavarga (classical Parashara transit rule).
  List<int> getFavorableTransitSigns(Ashtakavarga ashtakavarga, Planet planet) {
    final favorableSigns = <int>[];
    final bav = ashtakavarga.bhinnashtakavarga[planet];

    for (var sign = 0; sign < 12; sign++) {
      if (bav != null) {
        if (bav.getBindusForSign(sign) >= 4) {
          favorableSigns.add(sign);
        }
      } else {
        if (ashtakavarga.isSignFavorableForTransits(sign)) {
          favorableSigns.add(sign);
        }
      }
    }

    return favorableSigns;
  }

  /// Gets detailed bindu information for all planets in a specific sign.
  Map<Planet, int> getBinduDetailsForSign(
    Ashtakavarga ashtakavarga,
    int signIndex,
  ) {
    final details = <Planet, int>{};

    for (final entry in ashtakavarga.bhinnashtakavarga.entries) {
      details[entry.key] = entry.value.getBindusForSign(signIndex);
    }

    return details;
  }

  /// Applies Trikona Shodhana (Trine Reduction) to Ashtakavarga strictly
  /// adhering to BPHS Ch. 68:
  /// - If any sign in the trikona has 0 bindus, no reduction is made.
  /// - If all three signs have equal bindus, all are reduced to 0.
  /// - If unequal, the minimum is subtracted from the other two signs.
  Ashtakavarga applyTrikonaShodhana(Ashtakavarga ashtakavarga) {
    final reducedBhinnashtakavarga = <Planet, Bhinnashtakavarga>{
      for (final planet in ashtakavarga.bhinnashtakavarga.keys)
        planet: () {
          final bav = ashtakavarga.bhinnashtakavarga[planet]!;
          return _withRebuiltMask(
            bav,
            _reduceTrikona(bav.bindus),
          );
        }(),
    };

    // The Ascendant's own Prastara row is reduced with the same rules so the
    // reduced chart stays internally consistent.
    final rawLagna = ashtakavarga.lagnaBhinnashtakavarga;
    final reducedLagna = rawLagna == null
        ? null
        : _withRebuiltMask(rawLagna, _reduceTrikona(rawLagna.bindus));

    return _assemble(
      ashtakavarga.natalChart,
      reducedBhinnashtakavarga,
      reducedLagna,
    );
  }

  /// Applies the BPHS Ch. 68 Trikona rules to a 12-entry bindu array.
  ///
  /// The rules are unchanged; they are simply factored out so they can be
  /// shared by the graha BAVs and the Ascendant's own row.
  List<int> _reduceTrikona(List<int> bindus) {
    final reducedBindus = List<int>.from(bindus);

    for (final trikona in _trikonas) {
      final bindu1 = bindus[trikona[0]];
      final bindu2 = bindus[trikona[1]];
      final bindu3 = bindus[trikona[2]];

      // BPHS Rule 1: If any sign in the trine has 0, no reduction is made
      if (bindu1 == 0 || bindu2 == 0 || bindu3 == 0) {
        continue;
      }

      // BPHS Rule 2: If all three signs are equal, eliminate all (set to 0)
      if (bindu1 == bindu2 && bindu2 == bindu3) {
        reducedBindus[trikona[0]] = 0;
        reducedBindus[trikona[1]] = 0;
        reducedBindus[trikona[2]] = 0;
        continue;
      }

      // BPHS Rule 3: If unequal, deduct the smallest from the other two
      final minBindu = [bindu1, bindu2, bindu3].reduce(math.min);
      if (bindu1 > minBindu) {
        reducedBindus[trikona[0]] = bindu1 - minBindu;
      }
      if (bindu2 > minBindu) {
        reducedBindus[trikona[1]] = bindu2 - minBindu;
      }
      if (bindu3 > minBindu) {
        reducedBindus[trikona[2]] = bindu3 - minBindu;
      }
    }

    return reducedBindus;
  }

  /// Rebuilds a [Bhinnashtakavarga] from reduced bindus and a matching mask.
  ///
  /// A Shodhana reduction only produces counts, not contributor identities, so
  /// the mask is re-derived from the reduced values instead of being copied
  /// from the unreduced chart (which previously let a reduced BAV's Prastara
  /// breakdown contradict its own bindu count).
  Bhinnashtakavarga _withRebuiltMask(Bhinnashtakavarga bav, List<int> reduced) {
    return Bhinnashtakavarga(
      planet: bav.planet,
      bindus: reduced,
      contributions: [
        for (var sign = 0; sign < 12; sign++)
          _maskForReducedBindus(bav.contributions[sign], reduced[sign]),
      ],
    );
  }

  /// Derives the contribution mask for one sign from its reduced bindu count.
  ///
  /// Invariant: the result's population count always equals [reducedCount].
  /// - [reducedCount] <= 0  -> mask cleared (no contributor survives).
  /// - nothing removed     -> the original mask is kept verbatim.
  /// - otherwise           -> the Ascendant bit (bit 7) is retained whenever it
  ///   was present, and the lowest-indexed graha bits are filled in to reach
  ///   [reducedCount]. Shodhana does not identify *which* contributors were
  ///   removed, so this deterministic choice keeps the mask well-formed.
  int _maskForReducedBindus(int rawMask, int reducedCount) {
    if (reducedCount <= 0) return 0;

    final rawCount = _popCount(rawMask);
    if (reducedCount >= rawCount) return rawMask;

    final ascendantSurvives = (rawMask & _ascendantBit) != 0;
    var mask = ascendantSurvives ? _ascendantBit : 0;
    var remaining = reducedCount - (ascendantSurvives ? 1 : 0);

    for (var i = 0; i < _contributorCount && remaining > 0; i++) {
      if (rawMask & (1 << i) != 0) {
        mask |= 1 << i;
        remaining--;
      }
    }

    return mask;
  }

  /// Applies Ekadhipati Shodhana (Reduction for Same Lordship).
  ///
  /// Implements classical BPHS Chapter 67 rules based on planetary occupancy:
  /// 1. Both signs unoccupied: if bindus equal, both become 0; if unequal, larger equals smaller.
  /// 2. Both signs occupied: no reduction (both keep bindus).
  /// 3. One occupied, one empty:
  ///    - If empty has more bindus than occupied: empty is reduced to occupied's bindus.
  ///    - If empty has fewer or equal bindus: empty becomes 0, occupied keeps its bindus.
  Ashtakavarga applyEkadhipatiShodhana(Ashtakavarga ashtakavarga) {
    // 1. Identify which signs are occupied by planets in the natal chart
    final occupiedSigns = <int>{};
    for (final p in Planet.traditionalPlanets) {
      final info = ashtakavarga.natalChart.getPlanet(p);
      if (info != null) {
        final sign = (info.longitude / 30).floor() % 12;
        occupiedSigns.add(sign);
      }
    }

    final reducedBhinnashtakavarga = <Planet, Bhinnashtakavarga>{
      for (final planet in ashtakavarga.bhinnashtakavarga.keys)
        planet: () {
          final bav = ashtakavarga.bhinnashtakavarga[planet]!;
          return _withRebuiltMask(
            bav,
            _reduceEkadhipati(bav.bindus, occupiedSigns),
          );
        }(),
    };

    final rawLagna = ashtakavarga.lagnaBhinnashtakavarga;
    final reducedLagna = rawLagna == null
        ? null
        : _withRebuiltMask(
            rawLagna,
            _reduceEkadhipati(rawLagna.bindus, occupiedSigns),
          );

    return _assemble(
      ashtakavarga.natalChart,
      reducedBhinnashtakavarga,
      reducedLagna,
    );
  }

  /// Applies the BPHS Ch. 67 Ekadhipati rules to a 12-entry bindu array.
  ///
  /// The rules are unchanged; they are factored out so they can be shared by
  /// the graha BAVs and the Ascendant's own row.
  List<int> _reduceEkadhipati(List<int> bindus, Set<int> occupiedSigns) {
    final reducedBindus = List<int>.from(bindus);

    // Apply classical BPHS reduction to each planet's dual signs
    for (final signPair in _dualSigns) {
      final sign1 = signPair[0];
      final sign2 = signPair[1];
      final bindu1 = reducedBindus[sign1];
      final bindu2 = reducedBindus[sign2];

      final occ1 = occupiedSigns.contains(sign1);
      final occ2 = occupiedSigns.contains(sign2);

      // Case 1: Both signs unoccupied
      if (!occ1 && !occ2) {
        if (bindu1 == bindu2) {
          reducedBindus[sign1] = 0;
          reducedBindus[sign2] = 0;
        } else {
          final minBindu = bindu1 < bindu2 ? bindu1 : bindu2;
          reducedBindus[sign1] = minBindu;
          reducedBindus[sign2] = minBindu;
        }
      }
      // Case 2: One sign occupied, one unoccupied
      else if (occ1 && !occ2) {
        if (bindu2 > bindu1) {
          reducedBindus[sign2] = bindu1;
        } else {
          reducedBindus[sign2] = 0;
        }
      } else if (!occ1 && occ2) {
        if (bindu1 > bindu2) {
          reducedBindus[sign1] = bindu2;
        } else {
          reducedBindus[sign1] = 0;
        }
      }
    }

    return reducedBindus;
  }

  /// Calculates Pinda (Planetary Strength) from Ashtakavarga.
  ///
  /// Pinda calculation combines:
  /// 1. Rashi Pinda (Sign-based points multiplied by sign multipliers)
  /// 2. Graha Pinda (Planet-based points multiplied by planet multipliers)
  ///
  /// [ashtakavarga] - The Ashtakavarga to calculate Pinda for
  ///
  /// Returns the Pinda for each planet.
  Map<Planet, PindaResult> calculatePinda(Ashtakavarga ashtakavarga) {
    // Map planets to their occupied signs
    final planetSigns = <Planet, int>{};
    for (final p in Planet.traditionalPlanets) {
      final info = ashtakavarga.natalChart.getPlanet(p);
      if (info != null) {
        planetSigns[p] = (info.longitude / 30).floor() % 12;
      }
    }

    final pindaResults = <Planet, PindaResult>{
      for (final planet in ashtakavarga.bhinnashtakavarga.keys)
        planet: () {
          final bav = ashtakavarga.bhinnashtakavarga[planet]!;

          // Calculate Rashi Pinda
          var totalRashiPinda = 0.0;
          final signPindas = <int, double>{};
          for (var signIndex = 0; signIndex < 12; signIndex++) {
            final bindus = bav.bindus[signIndex];
            final rashiMultiplier = _pindaMultipliers[signIndex];
            final rashiPinda = bindus * rashiMultiplier;
            signPindas[signIndex] = rashiPinda;
            totalRashiPinda += rashiPinda;
          }

          // Calculate Graha Pinda based on sign occupancy
          var totalGrahaPinda = 0.0;
          final grahaPindas = <int, double>{};
          for (var i = 0; i < 12; i++) {
            grahaPindas[i] = 0.0;
          }

          for (final p in Planet.traditionalPlanets) {
            final occupiedSign = planetSigns[p];
            if (occupiedSign != null) {
              final bindus = bav.bindus[occupiedSign];
              final grahaMultiplier = _grahaPindaMultipliers[p] ?? 0.0;
              final grahaPindaValue = bindus * grahaMultiplier;

              grahaPindas[occupiedSign] =
                  (grahaPindas[occupiedSign] ?? 0.0) + grahaPindaValue;
              totalGrahaPinda += grahaPindaValue;
            }
          }

          // Combined Pinda (Rashi + Graha)
          final totalPinda = totalRashiPinda + totalGrahaPinda;

          return PindaResult(
            planet: planet,
            totalPinda: totalPinda,
            signPindas: signPindas,
            pindaPerSign: totalPinda / 12,
          );
        }(),
    };

    return pindaResults;
  }

  /// Calculates Yoga Pinda (auspicious strength) from Ashtakavarga.
  ///
  /// Yoga Pinda represents the total benefic strength after all reductions.
  /// Traditional multipliers based on sign placement benefits.
  ///
  /// [ashtakavarga] - The Ashtakavarga after Trikona and Ekadhipati Shodhana
  ///
  /// Returns the Yoga Pinda for each planet
  Map<Planet, YogaPindaResult> calculateYogaPinda(Ashtakavarga ashtakavarga) {
    final yogaPindaResults = <Planet, YogaPindaResult>{
      for (final planet in ashtakavarga.bhinnashtakavarga.keys)
        planet: () {
          final bav = ashtakavarga.bhinnashtakavarga[planet]!;

          var totalYogaPinda = 0.0;
          final signYogaPindas = <int, double>{};

          // Traditional Yoga Pinda uses specific multipliers per sign
          for (var signIndex = 0; signIndex < 12; signIndex++) {
            final bindus = bav.bindus[signIndex];
            final multiplier = _traditionalYogaPindaMultipliers[signIndex];

            // Benefic placements receive enhanced multipliers
            if (multiplier > 0) {
              final rashiPinda = bindus * multiplier;
              signYogaPindas[signIndex] = rashiPinda;
              totalYogaPinda += rashiPinda;
            } else {
              signYogaPindas[signIndex] = 0.0;
            }
          }

          return YogaPindaResult(
            planet: planet,
            totalYogaPinda: totalYogaPinda,
            signYogaPindas: signYogaPindas,
            yogaPindaPerSign: totalYogaPinda / 12,
            strengthRating: _getYogaPindaRating(totalYogaPinda),
          );
        }(),
    };

    return yogaPindaResults;
  }

  /// Calculates Shodhya Pinda (reduced strength).
  ///
  /// Shodhya Pinda is calculated after applying:
  /// 1. Trikona Shodhana (Trine reduction)
  /// 2. Ekadhipati Shodhana (Reduction for same lordship)
  ///
  /// This represents the actual usable strength after reductions.
  ///
  /// [ashtakavarga] - The Ashtakavarga to calculate from
  ///
  /// Returns the complete Shodhya Pinda analysis
  ShodhyaPindaResult calculateShodhyaPinda(Ashtakavarga ashtakavarga) {
    // Step 1: Apply Trikona Shodhana
    final trikonaReduced = applyTrikonaShodhana(ashtakavarga);

    // Step 2: Apply Ekadhipati Shodhana
    final ekadhipatiReduced = applyEkadhipatiShodhana(trikonaReduced);

    // Step 3: Calculate Pinda from reduced Ashtakavarga
    final reducedPinda = calculatePinda(ekadhipatiReduced);

    // Step 4: Calculate Yoga Pinda from reduced Ashtakavarga
    final yogaPinda = calculateYogaPinda(ekadhipatiReduced);

    // Calculate totals
    var totalReducedPinda = 0.0;
    var totalYogaPinda = 0.0;

    for (final entry in reducedPinda.entries) {
      totalReducedPinda += entry.value.totalPinda;
    }

    for (final entry in yogaPinda.entries) {
      totalYogaPinda += entry.value.totalYogaPinda;
    }

    return ShodhyaPindaResult(
      trikonaReducedAshtakavarga: trikonaReduced,
      ekadhipatiReducedAshtakavarga: ekadhipatiReduced,
      reducedPinda: reducedPinda,
      yogaPinda: yogaPinda,
      totalReducedPinda: totalReducedPinda,
      totalYogaPinda: totalYogaPinda,
      reducedPindaPerPlanet:
          reducedPinda.isEmpty ? 0.0 : totalReducedPinda / reducedPinda.length,
      yogaPindaPerPlanet:
          yogaPinda.isEmpty ? 0.0 : totalYogaPinda / yogaPinda.length,
    );
  }

  /// Calculates Ashtakavarga Pinda for a specific house.
  ///
  /// This calculates the strength of a specific house based on
  /// Ashtakavarga bindus in that house across all planets.
  ///
  /// [ashtakavarga] - The Ashtakavarga
  /// [houseNumber] - House number (1-12)
  ///
  /// Returns the house Pinda value
  double calculateHousePinda(Ashtakavarga ashtakavarga, int houseNumber) {
    if (houseNumber < 1 || houseNumber > 12) {
      throw ArgumentError('House number must be between 1 and 12');
    }

    final signIndex =
        (ashtakavarga.natalChart.ascendantSignIndex + houseNumber - 1) % 12;
    var housePinda = 0.0;

    // Sum bindus from all planets in this house
    for (final entry in ashtakavarga.bhinnashtakavarga.entries) {
      final bav = entry.value;
      final bindus = bav.bindus[signIndex];
      final multiplier = _pindaMultipliers[signIndex];
      housePinda += bindus * multiplier;
    }

    return housePinda;
  }

  /// Calculates Pinda strength for all 12 houses.
  ///
  /// [ashtakavarga] - The Ashtakavarga
  ///
  /// Returns a map of house numbers to their Pinda values
  Map<int, double> calculateAllHousesPinda(Ashtakavarga ashtakavarga) {
    final housesPinda = <int, double>{};

    for (var houseNum = 1; houseNum <= 12; houseNum++) {
      housesPinda[houseNum] = calculateHousePinda(ashtakavarga, houseNum);
    }

    return housesPinda;
  }

  /// Gets the rating for Yoga Pinda based on total value.
  YogaPindaRating _getYogaPindaRating(double totalYogaPinda) {
    if (totalYogaPinda >= 300) return YogaPindaRating.excellent;
    if (totalYogaPinda >= 225) return YogaPindaRating.veryGood;
    if (totalYogaPinda >= 150) return YogaPindaRating.good;
    if (totalYogaPinda >= 100) return YogaPindaRating.moderate;
    if (totalYogaPinda >= 50) return YogaPindaRating.weak;
    return YogaPindaRating.veryWeak;
  }

  // Trikona groups (trines)
  static const _trikonas = [
    [0, 4, 8], // Aries, Leo, Sagittarius (Fire)
    [1, 5, 9], // Taurus, Virgo, Capricorn (Earth)
    [2, 6, 10], // Gemini, Libra, Aquarius (Air)
    [3, 7, 11], // Cancer, Scorpio, Pisces (Water)
  ];

  // Dual signs (owned by same planet)
  static const _dualSigns = [
    [2, 5], // Gemini, Virgo (Mercury)
    [1, 6], // Taurus, Libra (Venus)
    [0, 7], // Aries, Scorpio (Mars)
    [8, 11], // Sagittarius, Pisces (Jupiter)
    [9, 10], // Capricorn, Aquarius (Saturn)
  ];

  // Pinda multipliers for each sign (Rashi Gunakara)
  static const _pindaMultipliers = [
    7.0, // Aries
    10.0, // Taurus
    8.0, // Gemini
    4.0, // Cancer
    10.0, // Leo
    5.0, // Virgo
    7.0, // Libra
    8.0, // Scorpio
    9.0, // Sagittarius
    5.0, // Capricorn
    11.0, // Aquarius
    12.0, // Pisces
  ];
}

/// Result of Pinda calculation.
class PindaResult {
  const PindaResult({
    required this.planet,
    required this.totalPinda,
    required this.signPindas,
    required this.pindaPerSign,
  });

  final Planet planet;

  /// Total Pinda = Rashi Pinda (all 12 signs) + Graha Pinda.
  final double totalPinda;

  /// Pinda contribution of each individual sign.
  final Map<int, double> signPindas;

  /// Mean Pinda per sign: [totalPinda] / 12.
  ///
  /// DERIVED CONVENIENCE, NOT A CLASSICAL FIGURE. Pinda is already a weighted
  /// score (bindus x Rashi/Graha multiplier), not a bindu count, and the Graha
  /// Pinda component is not sign-indexed — so dividing by 12 does not yield a
  /// meaningful "bindus per sign". Use [totalPinda] or [signPindas].
  final double pindaPerSign;

  /// Gets Pinda for a specific sign
  double getPindaForSign(int signIndex) => signPindas[signIndex] ?? 0.0;

  @override
  String toString() {
    return '${planet.displayName}: ${totalPinda.toStringAsFixed(1)} total, ${pindaPerSign.toStringAsFixed(1)} per sign';
  }
}

/// Result of Yoga Pinda calculation.
class YogaPindaResult {
  const YogaPindaResult({
    required this.planet,
    required this.totalYogaPinda,
    required this.signYogaPindas,
    required this.yogaPindaPerSign,
    required this.strengthRating,
  });

  final Planet planet;
  final double totalYogaPinda;
  final Map<int, double> signYogaPindas;

  /// Mean Yoga Pinda per sign: [totalYogaPinda] / 12.
  ///
  /// DERIVED CONVENIENCE, NOT A CLASSICAL FIGURE. "Yoga Pinda" itself has no
  /// standard per-sign mean in BPHS, and a fractional Pinda is not a bindu.
  /// Use [totalYogaPinda] or [signYogaPindas].
  final double yogaPindaPerSign;

  final YogaPindaRating strengthRating;

  /// Gets Yoga Pinda for a specific sign
  double getYogaPindaForSign(int signIndex) => signYogaPindas[signIndex] ?? 0.0;

  @override
  String toString() {
    return '${planet.displayName}: ${totalYogaPinda.toStringAsFixed(1)} ($strengthRating)';
  }
}

/// Yoga Pinda strength ratings
enum YogaPindaRating {
  excellent('Excellent', 300, double.infinity),
  veryGood('Very Good', 225, 300),
  good('Good', 150, 225),
  moderate('Moderate', 100, 150),
  weak('Weak', 50, 100),
  veryWeak('Very Weak', 0, 50);

  const YogaPindaRating(this.name, this.minValue, this.maxValue);

  final String name;
  final double minValue;
  final double maxValue;

  @override
  String toString() => name;
}

/// Result of complete Shodhya Pinda calculation.
class ShodhyaPindaResult {
  const ShodhyaPindaResult({
    required this.trikonaReducedAshtakavarga,
    required this.ekadhipatiReducedAshtakavarga,
    required this.reducedPinda,
    required this.yogaPinda,
    required this.totalReducedPinda,
    required this.totalYogaPinda,
    required this.reducedPindaPerPlanet,
    required this.yogaPindaPerPlanet,
  });

  /// Ashtakavarga after Trikona Shodhana
  final Ashtakavarga trikonaReducedAshtakavarga;

  /// Ashtakavarga after Ekadhipati Shodhana (final)
  final Ashtakavarga ekadhipatiReducedAshtakavarga;

  /// Reduced Pinda for each planet
  final Map<Planet, PindaResult> reducedPinda;

  /// Yoga Pinda for each planet
  final Map<Planet, YogaPindaResult> yogaPinda;

  /// Total reduced Pinda across all planets
  final double totalReducedPinda;

  /// Total Yoga Pinda across all planets
  final double totalYogaPinda;

  /// Mean reduced Pinda per planet: [totalReducedPinda] / number of grahas.
  ///
  /// DERIVED CONVENIENCE, NOT A CLASSICAL FIGURE. There is no BPHS "average
  /// reduced Pinda" quantity. Divisor is the graha count (7), not the sign
  /// count, so it is not a per-sign figure and is never fractional bindus.
  final double reducedPindaPerPlanet;

  /// Mean Yoga Pinda per planet: [totalYogaPinda] / number of grahas.
  ///
  /// DERIVED CONVENIENCE, NOT A CLASSICAL FIGURE — see
  /// [reducedPindaPerPlanet]. Note this is a *per planet* mean and is distinct
  /// from [YogaPindaResult.yogaPindaPerSign].
  final double yogaPindaPerPlanet;

  /// Gets Yoga Pinda for a specific planet
  YogaPindaResult? getYogaPindaForPlanet(Planet planet) => yogaPinda[planet];

  /// Gets reduced Pinda for a specific planet
  PindaResult? getReducedPindaForPlanet(Planet planet) => reducedPinda[planet];

  /// Overall strength assessment
  ShodhyaStrength get overallStrength {
    if (yogaPindaPerPlanet >= 25) return ShodhyaStrength.veryStrong;
    if (yogaPindaPerPlanet >= 20) return ShodhyaStrength.strong;
    if (yogaPindaPerPlanet >= 15) return ShodhyaStrength.moderate;
    if (yogaPindaPerPlanet >= 10) return ShodhyaStrength.weak;
    return ShodhyaStrength.veryWeak;
  }
}

/// Shodhya Pinda overall strength
enum ShodhyaStrength {
  veryStrong('Very Strong', 'Excellent results expected'),
  strong('Strong', 'Good results expected'),
  moderate('Moderate', 'Average results'),
  weak('Weak', 'Challenges expected'),
  veryWeak('Very Weak', 'Significant difficulties');

  const ShodhyaStrength(this.name, this.description);

  final String name;
  final String description;

  @override
  String toString() => name;
}

// Traditional Yoga Pinda multipliers per sign (classical values)
const _traditionalYogaPindaMultipliers = [
  1.0, // Aries
  1.0, // Taurus
  1.0, // Gemini
  1.0, // Cancer
  1.0, // Leo
  1.0, // Virgo
  1.0, // Libra
  1.0, // Scorpio
  1.0, // Sagittarius
  1.0, // Capricorn
  1.0, // Aquarius
  1.0, // Pisces
];

// Graha (Planetary) Pinda multipliers (Graha Gunakara)
const _grahaPindaMultipliers = {
  Planet.sun: 5.0,
  Planet.moon: 5.0,
  Planet.mars: 8.0,
  Planet.mercury: 5.0,
  Planet.jupiter: 10.0,
  Planet.venus: 7.0,
  Planet.saturn: 5.0,
};
