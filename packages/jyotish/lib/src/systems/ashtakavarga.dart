import 'package:jyotish/src/models/planet.dart';
import 'package:jyotish/src/models/vedic_chart.dart';

/// Represents the Ashtakavarga (eightfold division) system.
///
/// Ashtakavarga is a system of evaluating planetary strength
/// by counting benefic points (bindus) contributed by each planet
/// in each sign of the zodiac.
class Ashtakavarga {
  const Ashtakavarga({
    required this.natalChart,
    required this.bhinnashtakavarga,
    required this.sarvashtakavarga,
    required this.samudayaAshtakavarga,
    this.lagnaBhinnashtakavarga,
  });

  /// Birth chart used for calculations
  final VedicChart natalChart;

  /// Bhinnashtakavarga for each of the 7 grahas (Sun..Saturn).
  ///
  /// Deliberately does **not** contain the Ascendant: see
  /// [lagnaBhinnashtakavarga]. Parashara gives no Rahu/Ketu rows.
  final Map<Planet, Bhinnashtakavarga> bhinnashtakavarga;

  /// The Ascendant's own Bhinnashtakavarga — the 8th row of classical Prastara.
  ///
  /// It is kept outside [bhinnashtakavarga] for two reasons:
  /// 1. That map is keyed by [Planet] and the Ascendant is not a graha, so it
  ///    has no key there.
  /// 2. [sarvashtakavarga] is the sum of [bhinnashtakavarga]; the Ascendant is
  ///    already counted through bit 7 of each graha's contribution mask, so an
  ///    extra entry in the map would double count it and move the classical
  ///    337 total.
  ///
  /// [Bhinnashtakavarga.bindus] of this row is the binary Prastara cell for the
  /// Ascendant: 1 when any graha row gives the Ascendant a bindu in that sign,
  /// 0 otherwise. Bit 7 of its contribution mask is set exactly when it is, so
  /// [Bhinnashtakavarga.doesAscendantContribute] stays meaningful.
  final Bhinnashtakavarga? lagnaBhinnashtakavarga;

  /// Sarvashtakavarga (total points per house)
  final Sarvashtakavarga sarvashtakavarga;

  /// Samudaya Ashtakavarga (total for all planets)
  final List<int> samudayaAshtakavarga;

  /// Gets the total bindus for a specific house (1-12) counted from the Ascendant.
  int getTotalBindusForHouse(int houseNumber) {
    if (houseNumber < 1 || houseNumber > 12) {
      throw ArgumentError('House number must be between 1 and 12');
    }
    final signIndex = (natalChart.ascendantSignIndex + houseNumber - 1) % 12;
    return sarvashtakavarga.bindus[signIndex];
  }

  /// Gets the total bindus for a specific sign (0=Aries, 11=Pisces)
  int getTotalBindusForSign(int signIndex) {
    if (signIndex < 0 || signIndex > 11) {
      throw ArgumentError('Sign index must be between 0 and 11');
    }
    return sarvashtakavarga.bindus[signIndex];
  }

  /// Checks if a house has more than 28 bindus (favorable)
  bool isHouseFavorable(int houseNumber) {
    return getTotalBindusForHouse(houseNumber) > 28;
  }

  /// Checks if a sign has more than 28 bindus (favorable for transits)
  bool isSignFavorableForTransits(int signIndex) {
    return getTotalBindusForSign(signIndex) > 28;
  }

  /// Gets the prastara ashtakavarga (contribution breakdown)
  Map<Planet, List<int>> get prastaraAshtakavarga {
    final result = <Planet, List<int>>{};
    for (final entry in bhinnashtakavarga.entries) {
      result[entry.key] = entry.value.contributions;
    }
    return result;
  }
}

/// Bhinnashtakavarga for a single planet.
///
/// Contains the bindus (points) contributed by each of the 7 planets
/// plus ascendant in each of the 12 signs.
class Bhinnashtakavarga {
  const Bhinnashtakavarga({
    required this.bindus,
    required this.contributions,
    this.planet,
  });

  /// The planet this Bhinnashtakavarga belongs to.
  ///
  /// `null` for the Ascendant's own Bhinnashtakavarga (the 8th Prastara row),
  /// which is exposed via [Ashtakavarga.lagnaBhinnashtakavarga] rather than
  /// through the [Planet]-keyed [Ashtakavarga.bhinnashtakavarga] map.
  final Planet? planet;

  /// Number of bindus in each sign (0-8)
  final List<int> bindus;

  /// Detailed contributions (which planets contribute to each sign)
  /// Each element is a bitmask of contributing planets
  final List<int> contributions;

  /// Gets bindus for a specific sign (0=Aries, 11=Pisces)
  int getBindusForSign(int signIndex) {
    if (signIndex < 0 || signIndex > 11) {
      throw ArgumentError('Sign index must be between 0 and 11');
    }
    return bindus[signIndex];
  }

  /// Gets contributing planets for a specific sign
  List<Planet> getContributingPlanetsForSign(int signIndex) {
    if (signIndex < 0 || signIndex > 11) {
      throw ArgumentError('Sign index must be between 0 and 11');
    }

    final contribution = contributions[signIndex];
    final result = <Planet>[];
    final contributingPlanets = [
      Planet.sun,
      Planet.moon,
      Planet.mars,
      Planet.mercury,
      Planet.jupiter,
      Planet.venus,
      Planet.saturn,
    ];

    for (var i = 0; i < contributingPlanets.length; i++) {
      if (contribution & (1 << i) != 0) {
        result.add(contributingPlanets[i]);
      }
    }

    return result;
  }

  /// Checks if the Ascendant contributed a bindu to a specific sign.
  bool doesAscendantContribute(int signIndex) {
    if (signIndex < 0 || signIndex > 11) {
      throw ArgumentError('Sign index must be between 0 and 11');
    }
    return (contributions[signIndex] & (1 << 7)) != 0;
  }

  /// Total bindus for this planet (should be between 0-337)
  int get totalBindus => bindus.fold(0, (sum, b) => sum + b);
}

/// Sarvashtakavarga (cumulative Ashtakavarga).
///
/// Contains the total bindus contributed by all planets
/// in each of the 12 signs.
class Sarvashtakavarga {
  const Sarvashtakavarga({required this.bindus});

  /// Total bindus in each sign (0-56).
  ///
  /// A sign can receive a bindu from each of the 8 Prastara contributors
  /// (7 grahas + Ascendant), so the per-sign maximum is 56, not 12.
  final List<int> bindus;

  /// Alias for `bindus.length` for legacy tests.
  int get length => bindus.length;

  /// Alias for [bindus[index]] for legacy tests.
  int operator [](int index) => bindus[index];

  /// Total bindus across all signs (should be between 0-337)
  int get total => bindus.fold(0, (sum, b) => sum + b);

  /// Average bindus per sign
  double get average => total / 12;

  /// Gets the sign with maximum bindus
  int get strongestSign {
    var maxIndex = 0;
    for (var i = 1; i < 12; i++) {
      if (bindus[i] > bindus[maxIndex]) {
        maxIndex = i;
      }
    }
    return maxIndex;
  }

  /// Gets the sign with minimum bindus
  int get weakestSign {
    var minIndex = 0;
    for (var i = 1; i < 12; i++) {
      if (bindus[i] < bindus[minIndex]) {
        minIndex = i;
      }
    }
    return minIndex;
  }

  /// Gets favorable signs (more than 28 bindus)
  List<int> get favorableSigns {
    return List.generate(12, (i) => i).where((i) => bindus[i] > 28).toList();
  }

  /// Gets unfavorable signs (28 or fewer bindus)
  List<int> get unfavorableSigns {
    return List.generate(12, (i) => i).where((i) => bindus[i] <= 28).toList();
  }
}

/// Ashtakavarga transit analysis.
class AshtakavargaTransit {
  const AshtakavargaTransit({
    required this.transitDate,
    required this.transitPlanet,
    required this.transitSign,
    required this.sarvashtakavargaTotal,
    required this.planetBindus,
    required this.bindus,
    required this.isFavorable,
    required this.strengthScore,
  });

  /// Transit date
  final DateTime transitDate;

  /// Planet in transit
  final Planet transitPlanet;

  /// Sign being transited (0-11)
  final int transitSign;

  /// Total bindus in that sign from Sarvashtakavarga
  final int sarvashtakavargaTotal;

  /// Bindus in that sign from the planet's own Bhinnashtakavarga
  final int planetBindus;

  /// Overall or combined bindus (usually refers to planetBindus, kept for backward compatibility)
  final int bindus;

  /// Whether this is a favorable transit (> 28 total bindus in Sarvashtakavarga)
  final bool isFavorable;

  /// A normalized strength score (0-100) representing the relative
  /// auspiciousness of the transit based on bindu counts.
  final int strengthScore;
}

/// Ashtakavarga table constants.
///
/// These tables define which planets contribute bindus (1)
/// in which signs from the perspective of each planet.
class AshtakavargaTables {
  // Contribution tables for each planet (Brihat Parashara Hora Shastra).
  // Indexed as table[relativeHouseFromContributor][contributorIndex]:
  // row 0 = 1st house from the contributor, row 11 = 12th house from it.
  // Rows are NOT absolute zodiac signs — the caller converts a zodiac sign to a
  // relative house via (sign - contributorSign + 12) % 12 before indexing.
  // Each column represents the contributor planet in order:
  // Col 0: Sun, Col 1: Moon, Col 2: Mars, Col 3: Mercury, Col 4: Jupiter, Col 5: Venus, Col 6: Saturn.
  // 1 = contributes bindu, 0 = does not contribute.

  /// Sun's Ashtakavarga contributions (standard Parashari)
  /// Benefic houses from contributors (1-based):
  /// Sun: 1, 2, 4, 7, 8, 9, 10, 11 (8)
  /// Moon: 3, 6, 10, 11 (4)
  /// Mars: 1, 2, 4, 7, 8, 9, 10, 11 (8)
  /// Mercury: 3, 5, 6, 9, 10, 11, 12 (7)
  /// Jupiter: 5, 6, 9, 11 (4)
  /// Venus: 6, 7, 12 (3)
  /// Saturn: 1, 2, 4, 7, 8, 9, 10, 11 (8)
  /// (Lagna contributes 6 bindus at houses 3, 4, 6, 10, 11, 12 -> Total 48)
  static const List<List<int>> sunTable = [
    // Su Mo Ma Me Ju Ve Sa
    [1, 0, 1, 0, 0, 0, 1], // 1st from contributor
    [1, 0, 1, 0, 0, 0, 1], // 2nd from contributor
    [0, 1, 0, 1, 0, 0, 0], // 3rd from contributor
    [1, 0, 1, 0, 0, 0, 1], // 4th from contributor
    [0, 0, 0, 1, 1, 0, 0], // 5th from contributor
    [0, 1, 0, 1, 1, 1, 0], // 6th from contributor
    [1, 0, 1, 0, 0, 1, 1], // 7th from contributor
    [1, 0, 1, 0, 0, 0, 1], // 8th from contributor
    [1, 0, 1, 1, 1, 0, 1], // 9th from contributor
    [1, 1, 1, 1, 0, 0, 1], // 10th from contributor
    [1, 1, 1, 1, 1, 0, 1], // 11th from contributor
    [0, 0, 0, 1, 0, 1, 0], // 12th from contributor
  ];

  /// Moon's Ashtakavarga contributions (standard Parashari)
  /// Benefic houses from contributors (1-based):
  /// Sun: 3, 6, 7, 8, 10, 11 (6)
  /// Moon: 1, 3, 6, 7, 10, 11 (6)
  /// Mars: 2, 3, 5, 6, 9, 10, 11 (7)
  /// Mercury: 1, 3, 4, 5, 7, 8, 10, 11 (8)
  /// Jupiter: 1, 4, 7, 8, 10, 11, 12 (7)
  /// Venus: 3, 4, 5, 7, 9, 10, 11 (7)
  /// Saturn: 3, 5, 6, 11 (4)
  /// (Lagna contributes 4 bindus at houses 3, 6, 10, 11 -> Total 49)
  static const List<List<int>> moonTable = [
    // Su Mo Ma Me Ju Ve Sa
    [0, 1, 0, 1, 1, 0, 0], // 1st
    [0, 0, 1, 0, 0, 0, 0], // 2nd
    [1, 1, 1, 1, 0, 1, 1], // 3rd
    [0, 0, 0, 1, 1, 1, 0], // 4th
    [0, 0, 1, 1, 0, 1, 1], // 5th
    [1, 1, 1, 0, 0, 0, 1], // 6th
    [1, 1, 0, 1, 1, 1, 0], // 7th
    [1, 0, 0, 1, 1, 0, 0], // 8th
    [0, 0, 1, 0, 0, 1, 0], // 9th
    [1, 1, 1, 1, 1, 1, 0], // 10th
    [1, 1, 1, 1, 1, 1, 1], // 11th
    [0, 0, 0, 0, 1, 0, 0], // 12th
  ];

  /// Mars' Ashtakavarga contributions (standard Parashari)
  /// Benefic houses from contributors (1-based):
  /// Sun: 3, 5, 6, 10, 11 (5)
  /// Moon: 3, 6, 11 (3)
  /// Mars: 1, 2, 4, 7, 8, 10, 11 (7)
  /// Mercury: 3, 5, 6, 11 (4)
  /// Jupiter: 6, 10, 11, 12 (4)
  /// Venus: 6, 8, 11, 12 (4)
  /// Saturn: 1, 4, 7, 8, 9, 10, 11 (7)
  /// (Lagna contributes 5 bindus at houses 1, 3, 6, 10, 11 -> Total 39)
  static const List<List<int>> marsTable = [
    // Su Mo Ma Me Ju Ve Sa
    [0, 0, 1, 0, 0, 0, 1], // 1st
    [0, 0, 1, 0, 0, 0, 0], // 2nd
    [1, 1, 0, 1, 0, 0, 0], // 3rd
    [0, 0, 1, 0, 0, 0, 1], // 4th
    [1, 0, 0, 1, 0, 0, 0], // 5th
    [1, 1, 0, 1, 1, 1, 0], // 6th
    [0, 0, 1, 0, 0, 0, 1], // 7th
    [0, 0, 1, 0, 0, 1, 1], // 8th
    [0, 0, 0, 0, 0, 0, 1], // 9th
    [1, 0, 1, 0, 1, 0, 1], // 10th
    [1, 1, 1, 1, 1, 1, 1], // 11th
    [0, 0, 0, 0, 1, 1, 0], // 12th
  ];

  /// Mercury's Ashtakavarga contributions (standard Parashari)
  /// Benefic houses from contributors (1-based):
  /// Sun: 5, 6, 9, 11, 12 (5)
  /// Moon: 2, 4, 6, 8, 10, 11 (6)
  /// Mars: 1, 2, 4, 7, 8, 9, 10, 11 (8)
  /// Mercury: 1, 3, 5, 6, 9, 10, 11, 12 (8)
  /// Jupiter: 6, 8, 11, 12 (4)
  /// Venus: 1, 2, 3, 4, 5, 8, 9, 11 (8)
  /// Saturn: 1, 2, 4, 7, 8, 9, 10, 11 (8)
  /// (Lagna contributes 7 bindus at houses 1, 2, 4, 6, 8, 10, 11 -> Total 54)
  static const List<List<int>> mercuryTable = [
    // Su Mo Ma Me Ju Ve Sa
    [0, 0, 1, 1, 0, 1, 1], // 1st
    [0, 1, 1, 0, 0, 1, 1], // 2nd
    [0, 0, 0, 1, 0, 1, 0], // 3rd
    [0, 1, 1, 0, 0, 1, 1], // 4th
    [1, 0, 0, 1, 0, 1, 0], // 5th
    [1, 1, 0, 1, 1, 0, 0], // 6th
    [0, 0, 1, 0, 0, 0, 1], // 7th
    [0, 1, 1, 0, 1, 1, 1], // 8th
    [1, 0, 1, 1, 0, 1, 1], // 9th
    [0, 1, 1, 1, 0, 0, 1], // 10th
    [1, 1, 1, 1, 1, 1, 1], // 11th
    [1, 0, 0, 1, 1, 0, 0], // 12th
  ];

  /// Jupiter's Ashtakavarga contributions (standard Parashari)
  /// Benefic houses from contributors (1-based):
  /// Sun: 1, 2, 3, 4, 7, 8, 9, 10, 11 (9)
  /// Moon: 2, 5, 7, 9, 11 (5)
  /// Mars: 1, 2, 4, 7, 8, 10, 11 (7)
  /// Mercury: 1, 2, 4, 5, 6, 9, 10, 11 (8)
  /// Jupiter: 1, 2, 3, 4, 7, 8, 10, 11 (8)
  /// Venus: 2, 5, 6, 9, 10, 11 (6)
  /// Saturn: 3, 5, 6, 12 (4)
  /// (Lagna contributes 9 bindus at houses 1, 2, 4, 5, 6, 7, 9, 10, 11 -> Total 56)
  static const List<List<int>> jupiterTable = [
    // Su Mo Ma Me Ju Ve Sa
    [1, 0, 1, 1, 1, 0, 0], // 1st
    [1, 1, 1, 1, 1, 1, 0], // 2nd
    [1, 0, 0, 0, 1, 0, 1], // 3rd
    [1, 0, 1, 1, 1, 0, 0], // 4th
    [0, 1, 0, 1, 0, 1, 1], // 5th
    [0, 0, 0, 1, 0, 1, 1], // 6th
    [1, 1, 1, 0, 1, 0, 0], // 7th
    [1, 0, 1, 0, 1, 0, 0], // 8th
    [1, 1, 0, 1, 0, 1, 0], // 9th
    [1, 0, 1, 1, 1, 1, 0], // 10th
    [1, 1, 1, 1, 1, 1, 0], // 11th
    [0, 0, 0, 0, 0, 0, 1], // 12th
  ];

  /// Venus' Ashtakavarga contributions (standard Parashari)
  /// Benefic houses from contributors (1-based):
  /// Sun: 8, 11, 12 (3)
  /// Moon: 1, 2, 3, 4, 5, 8, 9, 11, 12 (9)
  /// Mars: 3, 5, 6, 9, 11, 12 (6)
  /// Mercury: 3, 5, 6, 9, 11 (5)
  /// Jupiter: 5, 8, 9, 10, 11 (5)
  /// Venus: 1, 2, 3, 4, 5, 8, 9, 10, 11 (9)
  /// Saturn: 3, 4, 5, 8, 9, 10, 11 (7)
  /// (Lagna contributes 8 bindus at houses 1, 2, 3, 4, 5, 8, 9, 11 -> Total 52)
  static const List<List<int>> venusTable = [
    // Su Mo Ma Me Ju Ve Sa
    [0, 1, 0, 0, 0, 1, 0], // 1st
    [0, 1, 0, 0, 0, 1, 0], // 2nd
    [0, 1, 1, 1, 0, 1, 1], // 3rd
    [0, 1, 0, 0, 0, 1, 1], // 4th
    [0, 1, 1, 1, 1, 1, 1], // 5th
    [0, 0, 1, 1, 0, 0, 0], // 6th
    [0, 0, 0, 0, 0, 0, 0], // 7th
    [1, 1, 0, 0, 1, 1, 1], // 8th
    [0, 1, 1, 1, 1, 1, 1], // 9th
    [0, 0, 0, 0, 1, 1, 1], // 10th
    [1, 1, 1, 1, 1, 1, 1], // 11th
    [1, 1, 1, 0, 0, 0, 0], // 12th
  ];

  /// Saturn's Ashtakavarga contributions (standard Parashari)
  /// Benefic houses from contributors (1-based):
  /// Sun: 1, 2, 4, 7, 8, 10, 11 (7)
  /// Moon: 3, 6, 11 (3)
  /// Mars: 3, 5, 6, 10, 11, 12 (6)
  /// Mercury: 6, 8, 9, 10, 11, 12 (6)
  /// Jupiter: 5, 6, 11, 12 (4)
  /// Venus: 6, 11, 12 (3)
  /// Saturn: 3, 5, 6, 11 (4)
  /// (Lagna contributes 6 bindus at houses 1, 3, 4, 6, 10, 11 -> Total 39)
  static const List<List<int>> saturnTable = [
    // Su Mo Ma Me Ju Ve Sa
    [1, 0, 0, 0, 0, 0, 0], // 1st
    [1, 0, 0, 0, 0, 0, 0], // 2nd
    [0, 1, 1, 0, 0, 0, 1], // 3rd
    [1, 0, 0, 0, 0, 0, 0], // 4th
    [0, 0, 1, 0, 1, 0, 1], // 5th
    [0, 1, 1, 1, 1, 1, 1], // 6th
    [1, 0, 0, 0, 0, 0, 0], // 7th
    [1, 0, 0, 1, 0, 0, 0], // 8th
    [0, 0, 0, 1, 0, 0, 0], // 9th
    [1, 0, 1, 1, 0, 0, 0], // 10th
    [1, 1, 1, 1, 1, 1, 1], // 11th
    [0, 0, 1, 1, 1, 1, 0], // 12th
  ];

  /// Gets the contribution table for a specific planet
  static List<List<int>> getTableForPlanet(Planet planet) {
    switch (planet) {
      case Planet.sun:
        return sunTable;
      case Planet.moon:
        return moonTable;
      case Planet.mars:
        return marsTable;
      case Planet.mercury:
        return mercuryTable;
      case Planet.jupiter:
        return jupiterTable;
      case Planet.venus:
        return venusTable;
      case Planet.saturn:
        return saturnTable;
      default:
        throw ArgumentError('Ashtakavarga not defined for $planet');
    }
  }
}

/// A composite model holding the raw Ashtakavarga and its reduced forms (Shodhana).
///
/// This provides easy access to the complete Shodhya Pinda calculations
/// without needing to manually call the reduction sequence.
///
/// Note: [shodhyaPinda] is typed as `dynamic` to avoid a circular import between
/// this model and `ashtakavarga_service.dart`. Cast it to `ShodhyaPindaResult`
/// (from `ashtakavarga_service.dart`) when accessing the result fields.
class AshtakavargaWithShodhana {
  const AshtakavargaWithShodhana({
    required this.raw,
    required this.trikonaReduced,
    required this.ekadhipatiReduced,
    required this.shodhyaPinda,
  });

  /// The original, unreduced Ashtakavarga
  final Ashtakavarga raw;

  /// The Ashtakavarga after Trikona Shodhana (Trine Reduction)
  final Ashtakavarga trikonaReduced;

  /// The Ashtakavarga after Ekadhipati Shodhana (Reduction for same lordship)
  final Ashtakavarga ekadhipatiReduced;

  /// The final Shodhya Pinda and Yoga Pinda analysis.
  /// Type: `ShodhyaPindaResult` (from `ashtakavarga_service.dart`).
  final dynamic shodhyaPinda;
}
